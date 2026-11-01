local workspaces = require("workspaces")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

local function make_finder()
  local results = {}
  for _, item in ipairs(workspaces.get()) do
    table.insert(results, { name = item.name, path = item.path })
  end

  return finders.new_table({
    results = results,
    entry_maker = function(item)
      return {
        value = item,
        display = string.format("%-20s %s", item.name, item.path),
        ordinal = item.name .. " " .. item.path,
      }
    end,
  })
end

M.workspace_picker = function(opts)
  opts = opts or {}

  pickers
    .new(opts, {
      prompt_title = "Workspaces  (<C-a>: Add CWD | <C-d>: Delete selected)",
      finder = make_finder(),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if entry then
            workspaces.open(entry.value.name)
          end
        end)

        map({ "i", "n" }, "<C-a>", function()
          actions.close(prompt_bufnr)
          vim.ui.input({ prompt = "Workspace name for current directory: " }, function(name)
            if name and name ~= "" then
              workspaces.add(vim.fn.getcwd(), name)
              vim.notify("Workspace added: " .. name, vim.log.levels.INFO)
            end
          end)
        end)

        map({ "i", "n" }, "<C-d>", function()
          local entry = action_state.get_selected_entry()
          if not entry then
            return
          end
          local picker = action_state.get_current_picker(prompt_bufnr)
          workspaces.remove(entry.value.name)
          vim.notify("Workspace removed: " .. entry.value.name, vim.log.levels.WARN)
          picker:refresh(make_finder(), { reset_prompt = false })
        end)

        return true
      end,
    })
    :find()
end

return M
