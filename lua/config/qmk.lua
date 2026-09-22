local map = vim.keymap.set

local last_notified_mode = nil
local pending = false

-- Start RPC server for talking to QMK bridge app
if OS_INFO.windows then
  vim.fn.serverstart([[\\.\pipe\nvim-win-]] .. vim.fn.getpid())
elseif OS_INFO.linux then
  if OS_INFO.wsl then
    vim.fn.serverstart("/tmp/nvim-wsl-" .. vim.fn.getpid() .. ".sock")
  else
    -- TODO - non-WSL Linux
  end
elseif OS_INFO.darwin then
  -- TODO -- mac
end

-- Notify via RPC when we gain or lose focus
-- Also, notify that we have focus when getting an F24 press, used to query on new nvim instance connect
vim.keymap.set("", "<C-M-S-F12>", function ()
  vim.rpcnotify(0, "focus_change", "gain")
end)
vim.api.nvim_create_autocmd("FocusGained", {
  callback = function()
    vim.rpcnotify(0, "focus_change", "gain")
  end,
})
vim.api.nvim_create_autocmd("FocusLost", {
  callback = function()
    vim.rpcnotify(0, "focus_change", "lose")
  end,
})

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
