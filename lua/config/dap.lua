local dap = require('dap')

-- To install debugpy on Windows:
-- cd ~
-- mkdir .virtualenvs
-- cd .virtualenvs
-- python -m venv debugpy
-- debugpy\scripts\Activate.ps1
-- pip install --upgrade pip
-- pip install debugpy

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
    cb({
      type = 'executable',
      command = OS_INFO.windows and os.getenv("USERPROFILE") .. [[\.virtualenvs\debugpy\Scripts\python.exe]] or '~/.virtualenvs/debugpy/bin/python',
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
          local venv_path1 = cwd .. (OS_INFO.windows and [[\venv\Scripts\python.exe]] or '/venv/bin/python')
          local venv_path2 = cwd .. (OS_INFO.windows and [[\.venv\Scripts\python.exe]] or '/.venv/bin/python')
          if vim.fn.executable(venv_path1) == 1 then
            final_config.pythonPath = venv_path1
          elseif vim.fn.executable(venv_path2) == 1 then
            final_config.pythonPath = venv_path2
          else
            -- TODO -- Use which (or win equivalent) to find default python instead of assuming here
            if OS_INFO.windows then
              final_config.pythonPath = os.getenv("LOCALAPPDATA") .. [[\Programs\Python\Python314\python.exe]]
            else
              final_config.pythonPath = '/usr/bin/python'
            end
          end
        end
        on_config(final_config)
      end,
    })
  end
end

