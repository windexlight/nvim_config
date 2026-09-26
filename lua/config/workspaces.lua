local workspaces = require("workspaces")
local fzf = require("fzf-lua")

M = {}

-- TODO - why is this so slow?
M.open_workspace_fzf = function ()
  local function get_formatted_entries()
    local list = workspaces.get()
    local entries = {}
    for _, item in ipairs(list) do
      table.insert(entries, string.format("%-20s %s", item.name, item.path))
    end
    return entries
  end

  fzf.fzf_exec(get_formatted_entries(), {
    prompt = "Workspaces> ",
    -- Display helpful keymap hints in the fzf footer
    fzf_opts = {
      ["--header"] = "ctrl-a: Add CWD | ctrl-d: Delete selected",
    },
    actions = {
      -- Default (Enter): Open selected workspace
      ["default"] = function(selected)
        if not selected or #selected == 0 then return end
        local name = selected[1]:match("^(%S+)")
        if name then
          workspaces.open(name)
        end
      end,

      -- Ctrl-a: Add current working directory as a new workspace
      ["ctrl-a"] = function()
        vim.ui.input({ prompt = "Workspace name for current directory: " }, function(name)
          if name and name ~= "" then
            workspaces.add(vim.fn.getcwd(), name)
            -- vim.notify("Workspace added: " .. name, vim.log.levels.INFO)
          end
        end)
      end,

      -- Ctrl-d: Remove selected workspace
      ["ctrl-d"] = function(selected)
        if not selected or #selected == 0 then return end
        local name = selected[1]:match("^(%S+)")
        if name then
          workspaces.remove(name)
          -- vim.notify("Workspace removed: " .. name, vim.log.levels.WARN)
        end
      end,
    },
  })
end

return M

