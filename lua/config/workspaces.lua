local workspaces = require("workspaces")
local fzf = require("fzf-lua")

M = {}

-- TODO - Why does this randomly take 3-4 seconds to populate? Tried a few things, including passing list in a file, but didn't help.
M.open_workspace_fzf = function ()
  local list = workspaces.get()
  local entries = {}
  for _, item in ipairs(list) do
    table.insert(entries, string.format("%-20s %s", item.name, item.path))
  end

  fzf.fzf_exec(entries, {
    prompt = "Workspaces> ",
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
            print("Workspace added: " .. name, vim.log.levels.INFO)
          end
        end)
      end,

      -- Ctrl-d: Remove selected workspace
      ["ctrl-d"] = function(selected)
        if not selected or #selected == 0 then return end
        local name = selected[1]:match("^(%S+)")
        if name then
          workspaces.remove(name)
          print("Workspace removed: " .. name, vim.log.levels.WARN)
        end
      end,
    },
  })
end

return M

