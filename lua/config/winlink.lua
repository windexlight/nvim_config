local M = {}
local uv = vim.uv or vim.loop

local WSL_RUN = '/run/WSL'

local function slurp(path)
  local f = io.open(path, 'rb')
  if not f then return nil end
  local s = f:read('*a')
  f:close()
  return s
end

local function get_ppid(pid)
  local s = slurp(('/proc/%d/stat'):format(pid))
  if not s then return nil end
  local _, rest = s:match('^%d+ %((.*)%) (.*)$')
  if not rest then return nil end
  local f = vim.split(vim.trim(rest), ' ', { plain = true })
  return tonumber(f[2])
end

local function relay_of(pid)
  local cur = pid
  for _ = 1, 128 do
    local sock = ('%s/%d_interop'):format(WSL_RUN, cur)
    local st = uv.fs_stat(sock)
    if st and st.type == 'socket' then
      local comm = vim.trim(slurp(('/proc/%d/comm'):format(cur)) or '')
      local s = comm:match('^Relay%((%d+)%)$')
      if s then
        return { pid = cur, interop = sock }
      end
    end
    local ppid = get_ppid(cur)
    if not ppid or ppid <= 1 then return nil end
    cur = ppid
  end
  return nil
end

local PS_SCRIPT = [[
$ErrorActionPreference='Stop'
$all=Get-CimInstance -ClassName Win32_Process -Property ProcessId,ParentProcessId,Name,CreationDate
$by=@{}; foreach($p in $all){ $by[[int]$p.ProcessId]=$p }
$chain=New-Object System.Collections.ArrayList
$id=[int]$PID
while($by.ContainsKey($id) -and $chain.Count -lt 32){
  $p=$by[$id]
  [void]$chain.Add([ordered]@{pid=[int]$p.ProcessId;ppid=[int]$p.ParentProcessId;name=[string]$p.Name;created=$p.CreationDate.ToUniversalTime().ToString('o')})
  $q=$by[[int]$p.ParentProcessId]
  if($null -eq $q -or $q.CreationDate -gt $p.CreationDate){ break }
  $id=[int]$q.ProcessId
}
ConvertTo-Json -Compress -InputObject @($chain)
]]

function M.ancestry()
  local pid = uv.os_getpid()
  local relay = relay_of(pid)
  local ancestry = { no_relay = true }
  if relay then
    ancestry = { have_relay = true }
    local ps = vim.fn.exepath('powershell.exe')
    if ps == '' then ps = '/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe' end
    vim.system({ ps, '-NoLogo', '-NoProfile', '-NonInteractive', '-Command', PS_SCRIPT }, {
      text = true,
      timeout = 15000,
      env = { WSL_INTEROP = relay.interop },
    }, function(res)
      if res.code == 0 then
        local ok
        ok, ancestry = pcall(vim.json.decode, res.stdout or '')
        if not (ok and type(ancestry) == 'table') then
          ancestry = { not_ok = true }
        end
      end
    end)
  end
  return ancestry
end

return M
