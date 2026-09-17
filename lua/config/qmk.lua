local map = vim.keymap.set

local last_notified_mode = nil
local pending = false

-- RPC stuff for QMK
if OS_INFO.windows then
  -- Start RPC server with a name containing Windows pid, so we can find it based on foreground Window
  vim.fn.serverstart([[\\.\pipe\nvim-win-]] .. vim.fn.getpid())
elseif OS_INFO.linux then
  if OS_INFO.wsl then
    -- Open a temporary RPC server with an id passed in via env var, then receive a Windows PIDN
    -- over RPC, and use that to start a new server with the Windows PID in the name.
    -- This it all so that a Windows side process can find our WSL nvim RPC socket based on
    -- getting a PID from a window, and the PID can't be passed into the environment at launch,
    -- because it doesn't exist yet.
    local launch_id = os.getenv("NVIM_LAUNCH_ID")
    if launch_id and launch_id ~= "" then
      local handshake_sock = "/tmp/nvim-handshake-" .. launch_id .. ".sock"
      vim.fn.serverstart(handshake_sock)
      _G.ReceiveWindowsPid = function(win_pid)
        vim.schedule(function()
          if win_pid and win_pid ~= "" then
            local final_socket = "/tmp/nvim-win-" .. tostring(win_pid) .. ".sock"
            vim.fn.serverstart(final_socket)
            vim.fn.serverstop(handshake_sock)
            os.remove(handshake_sock)
          end
        end)
        return "HANDSHAKE_COMPLETE"
      end
    else
      vim.fn.serverstart("/tmp/nvim-wsl-" .. vim.fn.getpid() .. ".sock")
    end
  else
    -- TODO - non-WSL Linux
  end
elseif OS_INFO.darwin then
  -- TODO -- mac
end

-- Notify via RPC when mode changes
local function commit_mode()
  pending = false
  local mode = vim.api.nvim_get_mode().mode
  if mode ~= last_notified_mode then
    last_notified_mode = mode
    vim.rpcnotify(0, "mode_change", mode)
  end
end

vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*",
  callback = function()
    local mode = vim.api.nvim_get_mode().mode
    pending = true
    if mode == 't' then -- Watch for other corner cases where SafeState isn't triggered
      commit_mode()
    end
    vim.defer_fn(function()
      if pending then commit_mode() end
    end, 15)
  end,
})

-- This works around an issue with spurious mode changes in some cases (grug-far insert mode, as one example)
vim.api.nvim_create_autocmd("SafeState", {
  callback = function()
    if pending then
      commit_mode()
    end
  end,
})

-- This is to work around an issue with ModeChanged not always firing when closing a window such as fzf-lua. Keep an eye out for other issues.
vim.api.nvim_create_autocmd("TermLeave", {
  pattern = "*",
  callback = function()
    vim.schedule(function()
      pending = true
      commit_mode()
    end)
  end,
})

-- Notify via RPC when using r, f, F, t, T and waiting for next char (treat it like insert mode)
local ns = vim.api.nvim_create_namespace("rpc_char_tracker")
local waiting_for_char = false
local f_wrapper_armed = false
vim.on_key(function(key)
  if f_wrapper_armed then
    vim.rpcnotify(0, "mode_change", "i")
    waiting_for_char = true
    f_wrapper_armed = false
  elseif waiting_for_char then
    vim.rpcnotify(0, "mode_change", "n")
    waiting_for_char = false
  end
end, ns)

M = {
  f_wrapper = function (call_me)
    f_wrapper_armed = true
    return call_me()
  end,

  r_wrapper = function ()
    f_wrapper_armed = true
    return "r"
  end,
}

return M
