local dap = require('dap')

-- To install debugpy on Windows:
-- cd ~
-- mkdir .virtualenvs
-- cd .virtualenvs
-- python -m venv debugpy
-- debugpy\scripts\Activate.ps1
-- pip install --upgrade pip
-- pip install debugpy
-- TODO - If adapting for linux, follow something more like here: https://codeberg.org/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#python

-- Set K to open nvim-dap-view hover when debug session running
local api = vim.api
local keymap_restore = {}
dap.listeners.after['event_initialized']['me'] = function()
  for _, buf in pairs(api.nvim_list_bufs()) do
    local keymaps = api.nvim_buf_get_keymap(buf, 'n')
    for _, keymap in pairs(keymaps) do
      if keymap.lhs == "K" then
        table.insert(keymap_restore, keymap)
        api.nvim_buf_del_keymap(buf, 'n', 'K')
      end
    end
  end
  api.nvim_set_keymap(
    'n', 'K', '<Cmd>lua require("dap-view").hover()<CR>', { silent = true })
end
dap.listeners.after['event_terminated']['me'] = function()
  for _, keymap in pairs(keymap_restore) do
    if keymap.rhs then
      api.nvim_buf_set_keymap(
        keymap.buffer,
        keymap.mode,
        keymap.lhs,
        keymap.rhs,
        { silent = keymap.silent == 1 }
      )
    elseif keymap.callback then
      vim.keymap.set(
      keymap.mode,
      keymap.lhs,
      keymap.callback,
      { buffer = keymap.buffer, silent = keymap.silent == 1 }
      )
    end
  end
  keymap_restore = {}
end

-- Python adapter
dap.adapters.debugpy = function(cb, config)
  if config.request == 'attach' then
    ---@diagnostic disable-next-line: undefined-field
    local port = (config.connect or config).port
    ---@diagnostic disable-next-line: undefined-field
    local host = (config.connect or config).host or '127.0.0.1'
    cb({
      type = 'server',
      port = assert(port, '`connect.port` is required for a python `attach` configuration'),
      host = host,
      options = {
        source_filetype = 'python',
      },
    })
  else
    local home = os.getenv("USERPROFILE")
    cb({
      type = 'executable',
      command = home .. [[\.virtualenvs\debugpy\Scripts\python.exe]], -- TODO - will be bin instead of Scripts on linux
      args = { '-m', 'debugpy.adapter' },
      options = {
        source_filetype = 'python',
      },
      enrich_config = function(cfg, on_config)
        local final_config = vim.deepcopy(cfg)
        if not final_config.pythonPath then
          -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
          -- The code below looks for a `venv` or `.venv` folder in the current directory and uses the python within.
          -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
          local cwd = vim.fn.getcwd()
          if vim.fn.executable(cwd .. [[\venv\Scripts\python.exe]]) == 1 then -- TODO - will be bin instead of Scripts on linux
            final_config.pythonPath = cwd .. [[\venv\Scripts\python.exe]]
          elseif vim.fn.executable(cwd .. [[\.venv\Scripts\python.exe]]) == 1 then -- TODO - will be bin instead of Scripts on linux
            final_config.pythonPath = cwd .. [[\.venv\Scripts\python.exe]]
          else
            local appdata = os.getenv("LOCALAPPDATA")
            final_config.pythonPath = appdata .. [[\Programs\Python\Python314\python.exe]]
          end
        end
        on_config(final_config)
      end,
    })
  end
end

-- dap.configurations.python = {
--   {
--     -- The first three options are required by nvim-dap
--     type = 'python'; -- the type here established the link to the adapter definition: `dap.adapters.python`
--     request = 'launch';
--     name = "Launch file";
--
--     -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options
--
--     program = "${file}"; -- This configuration will launch the current file if used.
--     pythonPath = function()
--       -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
--       -- The code below looks for a `venv` or `.venv` folder in the current directory and uses the python within.
--       -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
--       local cwd = vim.fn.getcwd()
--       if vim.fn.executable(cwd .. [[\venv\Scripts\python.exe]]) == 1 then -- TODO - will be bin instead of Scripts on linux
--         return cwd .. [[\venv\Scripts\python.exe]]
--       elseif vim.fn.executable(cwd .. [[\.venv\Scripts\python.exe]]) == 1 then -- TODO - will be bin instead of Scripts on linux
--         return cwd .. [[\.venv\Scripts\python.exe]]
--       else
--         local appdata = os.getenv("LOCALAPPDATA")
--         return appdata .. [[\Programs\Python\Python314\python.exe]]
--       end
--     end;
--   },
-- }

