local M = {}
local action_state = require("telescope.actions.state")
local utils = require("telescope.utils")
local actions = require("telescope.actions")

M.diffview_head = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if selection == nil then
    utils.__warn_no_selection("DiffViewOpen --imply-local")
    return
  end
  actions.close(prompt_bufnr)
  vim.cmd(string.format("DiffviewOpen %s..HEAD --imply-local", selection.value))
end

M.diffview_commit = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if selection == nil then
    utils.__warn_no_selection("DiffViewOpen commit")
    return
  end
  actions.close(prompt_bufnr)
  vim.cmd(string.format("DiffviewOpen %s^!", selection.value))
end

return M

