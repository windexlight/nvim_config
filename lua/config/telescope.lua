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

-- Below here is custom buffer picker entry_maker (LLM... it probably sucks)
local DIR_HL = "TelescopeResultsComment"
local IS_WIN = vim.fn.has "win32" == 1

--- Like `utils.is_uri`, but doesn't mistake Windows drive paths for URIs.
--- telescope only exempts `C:\foo`; `C:/foo` (what you get with 'shellslash')
--- and `C:foo` come back as "URI", which would show the path verbatim.
local function is_uri(path)
  if IS_WIN and path:match "^%a:[/\\]" then
    return false
  end
  return utils.is_uri(path)
end

--- plenary relativizes a path by comparing it with the cwd as plain text,
--- sensitive to both separators and case. On Windows a buffer name often
--- doesn't spell the cwd the same way (`C:/proj` with 'shellslash' vs. the
--- `C:\proj` libuv reports, or a different drive-letter/directory case), so
--- the comparison fails and the path stays absolute. Respell the name to match
--- the cwd and plenary's own relativizing, and its `~` home substitution,
--- work as intended.
---@param name string  buffer name as reported by Neovim
---@param cwd string   cwd, already normalized by `get_cwd`
local function respell_for_plenary(name, cwd)
  if not IS_WIN or not name:match "^%a:[/\\]" then
    return name -- not a Windows drive path (empty, URI, UNC, ...)
  end
  name = name:gsub("/", "\\")
  local prefix = cwd:sub(-1) == "\\" and cwd or (cwd .. "\\")
  if name:sub(1, #prefix):lower() == prefix:lower() then
    return prefix .. name:sub(#prefix + 1)
  elseif name:lower() == cwd:lower() then
    return cwd
  end
  return name
end

--- Split a path into its filename and the directory part.
---@param path string
---@param reverse_directories boolean
---@return string filename
---@return string dir  empty string when there is no directory part
local function split_path(path, reverse_directories)
  -- Windows accepts both separators and buffer names may use either (it
  -- depends on 'shellslash'). Split on both there, and re-join with whichever
  -- one the path itself uses so the output looks like the input.
  local sep, sep_pat = "/", "/"
  if IS_WIN then
    sep_pat = "[/\\]"
    if path:find("\\", 1, true) then
      sep = "\\"
    end
  end

  -- Directory buffers (netrw etc.) end in a separator; keep it on the name.
  local trimmed = path:gsub(sep_pat .. "+$", "")
  if trimmed == "" then
    return path, "" -- filesystem root
  end
  local trailing = trimmed ~= path and sep or ""

  local parts = vim.split(trimmed, sep_pat)
  local filename = table.remove(parts) .. trailing

  -- Keep the root (`/`, `C:\`) out of the directory list, so it stays in
  -- front when un-reversed instead of ending up trailing when reversed.
  local root = ""
  if parts[1] == "" then
    root = sep
    table.remove(parts, 1)
  elseif IS_WIN and parts[1] and parts[1]:match "^%a:$" then
    root = table.remove(parts, 1) .. sep
  end

  if reverse_directories then
    local reversed = {}
    for i = #parts, 1, -1 do
      if parts[i] ~= "" then -- UNC paths leave empty elements behind
        table.insert(reversed, parts[i])
      end
    end
    return filename, table.concat(reversed, sep)
  end

  return filename, root .. table.concat(parts, sep)
end

--- Digits needed for the highest listed buffer number.
local function listed_bufnr_width()
  local max = 1
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if bufnr > max and vim.bo[bufnr].buflisted then
      max = bufnr
    end
  end
  return #tostring(max)
end

---@param opts? table
---@return fun(buffer: table): table entry_maker
function M.buffers_entry_maker(opts)
  opts = opts or {}

  local icon_width = 0
  if not opts.disable_devicons then
    local icon = utils.get_devicons("fname", opts.disable_devicons)
    icon_width = strings.strdisplaywidth(icon)
  end

  -- The cwd as telescope would use it, with the separator plenary expects.
  local function get_cwd()
    local cwd = utils.path_expand(opts.cwd or vim.uv.cwd())
    if IS_WIN then
      cwd = cwd:gsub("/", "\\")
      if not cwd:match "^%a:\\$" then
        cwd = cwd:gsub("\\+$", "") -- keep the trailing `\` only on a drive root
      end
    end
    return cwd
  end

  -- `gen_from_buffer` captures the cwd when it is created. Because this
  -- entry_maker can outlive a single picker (e.g. set in `setup()`), rebuild
  -- the wrapped maker whenever the cwd changes so paths stay relative to it.
  local default_maker, default_maker_cwd
  local function get_default_maker(cwd)
    if cwd ~= default_maker_cwd then
      default_maker = make_entry.gen_from_buffer(vim.tbl_extend("force", opts, { cwd = cwd }))
      default_maker_cwd = cwd
    end
    return default_maker
  end

  -- Same reasoning for the displayer: the bufnr column width can change
  -- between picker runs, and entry_display caches resolved widths.
  local displayer, displayer_bufnr_width
  local function get_displayer()
    local width = opts.bufnr_width or listed_bufnr_width()
    if width ~= displayer_bufnr_width then
      displayer = entry_display.create {
        separator = " ",
        items = {
          { width = width },
          { width = 4 },
          { width = icon_width },
          { remaining = true },
        },
      }
      displayer_bufnr_width = width
    end
    return displayer
  end

  local function make_display(entry)
    local head, dir = entry.filename, ""
    -- "[No Name]" buffers and URIs (term://, oil://, fugitive://, ...) are
    -- shown verbatim; there is no meaningful directory to split off.
    if entry.path and not is_uri(entry.filename) then
      head, dir = split_path(entry.filename, opts.reverse_directories)
    end

    if not opts.disable_coordinates then
      head = head .. ":" .. entry.lnum
    end

    local text, highlights = head, nil
    if dir ~= "" then
      text = head .. " " .. dir
      highlights = { { { #head, #text }, DIR_HL } }
    end

    local icon, icon_hl = utils.get_devicons(entry.filename, opts.disable_devicons)

    return get_displayer() {
      { entry.bufnr, "TelescopeResultsNumber" },
      { entry.indicator, "TelescopeResultsComment" },
      { icon, icon_hl },
      {
        text,
        function()
          return highlights or {}
        end,
      },
    }
  end

  return function(buffer)
    local cwd = get_cwd()
    if IS_WIN and buffer.info and buffer.info.name then
      -- Copy, don't mutate: telescope reuses these buffer tables (e.g. on resume).
      local info = vim.tbl_extend("force", buffer.info, { name = respell_for_plenary(buffer.info.name, cwd) })
      buffer = vim.tbl_extend("force", buffer, { info = info })
    end

    local entry = get_default_maker(cwd)(buffer)
    entry.display = make_display
    return entry
  end
end

return M
