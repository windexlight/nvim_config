local M = {}
local action_state = require("telescope.actions.state")
local utils = require("telescope.utils")
local actions = require("telescope.actions")
local entry_display = require "telescope.pickers.entry_display"
local make_entry = require "telescope.make_entry"
local strings = require "plenary.strings"

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
