-- winlink.lua — read-only identity/focus probe for the *current* Neovim instance (WSL2).
--
-- Purpose: let a Windows-side host learn which Windows `wsl.exe` client (and therefore which
-- top-level window) routes keyboard input to this nvim, and whether this nvim is focused.
--
-- Why this works (all derived from the WSL source, see ANALYSIS.md):
--   * Every process started by one `wsl.exe` launch descends from ONE relay process R
--     (init forks it; PR_SET_CHILD_SUBREAPER; comm "Relay(<S>)"; owns the pty master;
--     serves the unix socket /run/WSL/<R>_interop).  Daemonised descendants re-parent to R.
--   * A Windows process created through that socket is created by the very `wsl.exe` that
--     owns R (SubProcess::Start sets no parent override).  wslhost.exe takes over only after
--     that wsl.exe has exited.
--   * So: "Windows ancestry of a probe started through R's socket" == "Windows ancestry of the
--     wsl.exe that is feeding this nvim", which contains the terminal / GUI's top-level PID.
--
-- Side effects: none on state.  M.info() only reads procfs.  M.resolve() starts one short-lived
-- Windows process (a hidden PowerShell that only reads the process table) through WSL interop.
-- M.setup() installs FocusGained/FocusLost (+ optional on_key) listeners that only timestamp.

local M = {}
local uv = vim.uv or vim.loop
local api = vim.api

local WSL_RUN = '/run/WSL'

---------------------------------------------------------------------------------------------
-- procfs helpers
---------------------------------------------------------------------------------------------

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

--- Parse /proc/<pid>/stat.  `comm` may contain spaces/parens, so split at the LAST ')'.
function M.proc_stat(pid)
  local s = slurp(('/proc/%d/stat'):format(pid))
  if not s then return nil end
  local comm, rest = s:match('^%d+ %((.*)%) (.*)$')
  if not rest then return nil end
  local f = vim.split(vim.trim(rest), ' ', { plain = true })
  return {
    comm = comm,
    state = f[1],
    ppid = tonumber(f[2]),
    pgrp = tonumber(f[3]),
    session = tonumber(f[4]),
    tty_nr = tonumber(f[5]),
    tpgid = tonumber(f[6]),
    starttime = tonumber(f[20]), -- field 22: clock ticks since boot; (pid,starttime) is unique
  }
end

local function pts_index(tty_nr)
  if not tty_nr or tty_nr == 0 then return nil end
  local major = bit.band(bit.rshift(tty_nr, 8), 0xfff)
  local minor = bit.bor(bit.band(tty_nr, 0xff), bit.band(bit.rshift(tty_nr, 12), 0xfff00))
  if major >= 136 and major <= 143 then return (major - 136) * 256 + minor end
  return nil -- not a Unix98 pty slave (e.g. a VT)
end

---------------------------------------------------------------------------------------------
-- relay discovery
---------------------------------------------------------------------------------------------

--- Walk the PPID chain from `pid` to the first ancestor A that is a WSL relay:
---   * /run/WSL/<A>_interop exists and is a socket, AND
---   * /proc/<A>/comm is "Relay(<S>)" (init names the relay this way; S is the pty session leader)
--- Returns { pid, interop, session_leader, hops } or nil.
function M.relay_of(pid)
  local cur, hops = pid, {}
  for _ = 1, 128 do
    local sock = ('%s/%d_interop'):format(WSL_RUN, cur)
    local st = uv.fs_stat(sock)
    if st and st.type == 'socket' then
      local comm = vim.trim(slurp(('/proc/%d/comm'):format(cur)) or '')
      local s = comm:match('^Relay%((%d+)%)$')
      if s then
        return { pid = cur, interop = sock, session_leader = tonumber(s), hops = hops }
      end
    end
    local ps = M.proc_stat(cur)
    if not ps or ps.ppid <= 1 then return nil end
    hops[#hops + 1] = cur
    cur = ps.ppid
  end
  return nil
end

---------------------------------------------------------------------------------------------
-- focus tracking
---------------------------------------------------------------------------------------------

-- state: 'unknown' until the first event arrives (nvim cannot ask the terminal), then 'focused'/'blurred'.
-- Times are wall-clock ms (comparable across nvim instances); 0 = never seen.
local focus = { state = 'unknown', gained_ms = 0, lost_ms = 0, last_key_ms = 0 }

local function now_ms()
  local sec, usec = uv.gettimeofday()
  return sec * 1000 + math.floor(usec / 1000)
end

function M.setup(opts)
  opts = opts or {}
  local g = api.nvim_create_augroup('winlink', { clear = true })
  api.nvim_create_autocmd('FocusGained', { group = g, callback = function()
    focus.state, focus.gained_ms = 'focused', now_ms()
  end })
  api.nvim_create_autocmd('FocusLost', { group = g, callback = function()
    focus.state, focus.lost_ms = 'blurred', now_ms()
  end })
  if opts.track_keys then
    vim.on_key(function() focus.last_key_ms = now_ms() end, api.nvim_create_namespace('winlink'))
  end
end


---------------------------------------------------------------------------------------------
-- tmux: the PPID chain leads to whichever relay STARTED the tmux server, not to the client that
-- is attached now.  The keyboard route is: pane pty <- tmux server <- attached client(s) <- relay.
-- $TMUX gives the socket, $TMUX_PANE the pane; both are fixed for the life of the pane.
---------------------------------------------------------------------------------------------

function M.tmux()
  local tm, pane = vim.env.TMUX, vim.env.TMUX_PANE
  if not tm or tm == '' or not pane or pane == '' then return nil end
  local sock = tm:match('^([^,]+)')
  local function q(args)
    local cmd = { 'tmux', '-S', sock }
    vim.list_extend(cmd, args)
    local ok, r = pcall(function() return vim.system(cmd, { text = true }):wait(2000) end)
    if not ok or not r or r.code ~= 0 then return nil end
    return r.stdout
  end
  local p = q({ 'display-message', '-p', '-t', pane, '#{window_id}\t#{pane_active}\t#{window_active}\t#{pane_tty}\t#{session_name}' })
  if not p then return { socket = sock, pane = pane, error = 'tmux query failed' } end
  local win, pane_active, window_active, pane_tty, session = unpack(vim.split(vim.trim(p), '\t', { plain = true }))
  local out = {
    socket = sock, pane = pane, window = win, session = session, pane_tty = pane_tty,
    pane_active = pane_active == '1', window_active = window_active == '1', clients = {},
  }
  local c = q({ 'list-clients', '-F', '#{client_pid}\t#{client_tty}\t#{session_name}\t#{window_id}\t#{client_flags}' })
  for line in vim.gsplit(c or '', '\n', { plain = true, trimempty = true }) do
    local pid, tty, sess, cwin, flags = unpack(vim.split(line, '\t', { plain = true }))
    pid = tonumber(pid)
    out.clients[#out.clients + 1] = {
      pid = pid, tty = tty, session = sess, window = cwin, flags = flags,
      focused = (flags or ''):find('focused', 1, true) ~= nil,
      shows_my_window = (sess == session and cwin == win),   -- this client's current window is mine
      relay = pid and M.relay_of(pid) or nil,                -- <- the route that actually carries the keys
    }
  end
  return out
end

---------------------------------------------------------------------------------------------
-- UI summary
---------------------------------------------------------------------------------------------

local function ui_summary()
  local out = {}
  for _, ui in ipairs(api.nvim_list_uis()) do
    local item = {
      chan = ui.chan, stdin_tty = ui.stdin_tty, stdout_tty = ui.stdout_tty,
      term_name = ui.term_name, width = ui.width, height = ui.height,
    }
    if ui.chan and ui.chan ~= 0 then
      local ok, ci = pcall(api.nvim_get_chan_info, ui.chan)
      if ok and ci then
        item.client = ci.client and { name = ci.client.name, type = ci.client.type } or nil
        item.stream = ci.stream
        -- 'socket' = attached over a unix/TCP socket (nvim --remote-ui, Neovide --server, ...):
        -- the keyboard route is NOT this process's wsl.exe ancestry (see ANALYSIS.md).
        item.remote = ci.stream == 'socket'
      end
    end
    out[#out + 1] = item
  end
  return out
end

function M.has_remote_ui()
  for _, u in ipairs(ui_summary()) do if u.remote then return true end end
  return false
end

---------------------------------------------------------------------------------------------
-- Routes: which relay(s) actually carry keyboard input into this nvim
---------------------------------------------------------------------------------------------

--- kind='own'         : the relay in our PPID chain (plain terminal, `wsl.exe -e nvim --embed`, ...)
--- kind='tmux-client' : relay of each tmux client currently showing our window
--- (none)             : headless / detached tmux / socket-attached UI (remote_ui) -> not derivable here
local function routes_of(relay, tmux, remote_ui)
  local routes = {}
  if tmux then
    for _, c in ipairs(tmux.clients or {}) do
      if c.shows_my_window and c.relay then
        routes[#routes + 1] = { kind = 'tmux-client', relay_pid = c.relay.pid, interop = c.relay.interop,
                                client_pid = c.pid, client_focused = c.focused }
      end
    end
  elseif relay and not remote_ui then
    routes[1] = { kind = 'own', relay_pid = relay.pid, interop = relay.interop }
  end
  return routes
end

---------------------------------------------------------------------------------------------
-- Windows-side resolution (one short-lived probe per route, through THAT route's interop socket)
---------------------------------------------------------------------------------------------

-- Windows PowerShell 5.1-compatible; prints the probe's own Windows ancestry as JSON.
-- (A parent is only trusted if it is not younger than its child -> guards PID reuse.)
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

-- cache: relay_pid -> { relay_pid, relay_starttime, chain, at_ms }
local resolved = {}

local function default_helper()
  local ps = vim.fn.exepath('powershell.exe')
  if ps == '' then ps = '/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe' end
  return { ps, '-NoLogo', '-NoProfile', '-NonInteractive', '-Command', PS_SCRIPT }
end

--- Resolve every current route that has no valid cached result.  Async; `cb(err_or_nil)` when done.
--- opts.helper : command list that prints the JSON chain (default: hidden powershell.exe)
--- opts.force  : ignore the cache
function M.resolve(opts, cb)
  opts = opts or {}
  local pid = uv.os_getpid()
  local routes = routes_of(M.relay_of(pid), M.tmux(), M.has_remote_ui())
  local todo = {}
  for _, r in ipairs(routes) do
    local c = resolved[r.relay_pid]
    local ps = M.proc_stat(r.relay_pid)
    if opts.force or not c or not ps or ps.starttime ~= c.relay_starttime then todo[#todo + 1] = { route = r, ps = ps } end
  end
  if #todo == 0 then if cb then cb(#routes == 0 and 'no routes' or nil) end return #routes end
  local pending, errs = #todo, {}
  for _, t in ipairs(todo) do
    vim.system(opts.helper or default_helper(), {
      text = true,
      timeout = opts.timeout_ms or 15000,
      -- Pin the route explicitly: never trust an inherited (possibly stale / wrong-window) $WSL_INTEROP.
      env = { WSL_INTEROP = t.route.interop },
    }, function(res)
      local ok, chain = pcall(vim.json.decode, res.stdout or '')
      if res.code == 0 and ok and type(chain) == 'table' then
        resolved[t.route.relay_pid] = { relay_pid = t.route.relay_pid, relay_starttime = t.ps and t.ps.starttime,
                                        chain = chain, at_ms = now_ms() }
      else
        errs[#errs + 1] = ('relay %d: code=%s %s'):format(t.route.relay_pid, tostring(res.code), res.stderr or '')
      end
      pending = pending - 1
      if pending == 0 and cb then vim.schedule(function() cb(#errs > 0 and table.concat(errs, '; ') or nil) end) end
    end)
  end
  return #todo
end

---------------------------------------------------------------------------------------------
-- Public: everything the host needs, in one RPC round trip
---------------------------------------------------------------------------------------------

function M.info()
  local pid = uv.os_getpid()
  local ps = M.proc_stat(pid) or {}
  local relay = M.relay_of(pid)
  local env_interop = vim.env.WSL_INTEROP
  local uis = ui_summary()
  local tty_ui, remote_ui = false, false
  for _, u in ipairs(uis) do
    if u.stdin_tty or u.stdout_tty then tty_ui = true end
    if u.remote then remote_ui = true end
  end

  -- Since Neovim 0.10 the process that owns the terminal is a separate "nvim-tui" client and
  -- THIS process (the RPC server) is its child: it has its own session and NO controlling tty.
  -- The terminal-side facts (tty, session) therefore belong to the parent.
  local tui
  for _, u in ipairs(uis) do
    if u.client and u.client.name == 'nvim-tui' and u.stream == 'stdio' and ps.ppid then
      local cps = M.proc_stat(ps.ppid)
      if cps then
        tui = { pid = ps.ppid, sid = cps.session, tty_nr = cps.tty_nr, pts = pts_index(cps.tty_nr),
                tty = vim.uv.fs_readlink(('/proc/%d/fd/0'):format(ps.ppid)) }
      end
    end
  end

  local tmux = M.tmux()
  local routes = routes_of(relay, tmux, remote_ui)
  -- Attach cached Windows ancestry to each route; a cache entry is only valid for the SAME relay process.
  local windows = {}
  for _, r in ipairs(routes) do
    local c = resolved[r.relay_pid]
    local rps = M.proc_stat(r.relay_pid)
    if c and rps and rps.starttime == c.relay_starttime then windows[#windows + 1] = c end
  end

  return {
    pid = pid,
    servername = vim.v.servername,
    starttime = ps.starttime,
    ppid = ps.ppid, sid = ps.session, pgrp = ps.pgrp,
    tty_nr = ps.tty_nr, pts = pts_index(ps.tty_nr),
    tmux = tmux,                                     -- nil unless running inside tmux
    routes = routes,                                 -- relays that carry keyboard input to this nvim
    tui = tui,                                       -- nil => no embedded TUI client (GUI / headless / remote UI)
    relay = relay,                                   -- nil => not under a wsl.exe-launched tree
    env_interop = env_interop,
    env_interop_matches_relay = (relay ~= nil and env_interop == relay.interop) or false,
    wt_session = vim.env.WT_SESSION,                 -- present only if WSLENV forwards it
    uis = uis, has_ui = #uis > 0, tty_ui = tty_ui, remote_ui = remote_ui,
    focus = vim.deepcopy(focus),
    now_ms = now_ms(),
    windows = windows,
  }
end

return M
