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

dap.adapters.python = function(cb, config)
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
    })
  end
end

dap.configurations.python = {
  {
    -- The first three options are required by nvim-dap
    type = 'python'; -- the type here established the link to the adapter definition: `dap.adapters.python`
    request = 'launch';
    name = "Launch file";

    -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

    program = "${file}"; -- This configuration will launch the current file if used.
    pythonPath = function()
      -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
      -- The code below looks for a `venv` or `.venv` folder in the current directory and uses the python within.
      -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
      local cwd = vim.fn.getcwd()
      if vim.fn.executable(cwd .. [[\venv\Scripts\python.exe]]) == 1 then -- TODO - will be bin instead of Scripts on linux
        return cwd .. [[\venv\Scripts\python.exe]]
      elseif vim.fn.executable(cwd .. [[\.venv\Scripts\python.exe]]) == 1 then -- TODO - will be bin instead of Scripts on linux
        return cwd .. [[\.venv\Scripts\python.exe]]
      else
        local appdata = os.getenv("LOCALAPPDATA")
        return appdata .. [[\Programs\Python\Python314\python.exe]]
      end
    end;
  },
}
