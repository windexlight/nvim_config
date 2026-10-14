local M = {}
local uv = vim.uv or vim.loop

local WSL_RUN = '/run/WSL'

-- TODO - why is this so complicated to apparently do nothing but read a file?
local function slurp(path)
  local fd = uv.fs_open(path, 'r', 438)
  if not fd then return nil end
  local chunks = {}
  while true do
    local d = uv.fs_read(fd, 65536, -1)
    if not d or #d == 0 then break end
    chunks[#chunks + 1] = d
  end
  uv.fs_close(fd)
  return table.concat(chunks)
end

function M.ppid(pid)
  local s = slurp(('/proc/%d/stat'):format(pid))
  if not s then return nil end
  local _, rest = s:match('^%d+ %((.*)%) (.*)$')
  if not rest then return nil end
  local f = vim.split(vim.trim(rest), ' ', { plain = true })
  return tonumber(f[2])
end

function M.relay_of(pid)
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
    local ppid = M.ppid(cur)
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
  local relay = M.relay_of(pid)
  local ancestry
  if relay then
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
          ancestry = nil
        end
      end
    end)
  end
  return ancestry
end

return M
