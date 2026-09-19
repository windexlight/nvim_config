local opt = vim.opt

-- Sync clipboard between OS and Neovim. Schedule the setting after `UIEnter` because it can
-- increase startup-time. Remove this option if you want your OS clipboard to remain independent.
-- See `:h 'clipboard'`
vim.api.nvim_create_autocmd('UIEnter', {
  callback = function()
    vim.o.clipboard = 'unnamedplus'
  end,
})

opt.number = true -- Print line number
opt.relativenumber = true -- Relative line numbers
opt.cursorline = true -- Enable highlighting of the current line
opt.wrap = false -- Disable line wrap
opt.scrolloff = 4 -- Lines of context
opt.sidescrolloff = 8 -- Columns of context

opt.tabstop = 2 -- Number of spaces tabs count for
opt.shiftwidth = 2 -- Size of an indent
opt.softtabstop = 2 -- Soft tab stop
opt.expandtab = true -- Use spaces instead of tabs
opt.smartindent = true -- Insert indents automatically
opt.autoindent = true -- Copy indent from current line
opt.shiftround = true -- Round indent

opt.ignorecase = true -- Ignore case
opt.smartcase = true -- Don't ignore case with capitals
opt.hlsearch = true -- Highlight search results
opt.incsearch = true -- Show mathches as you type

opt.termguicolors = true -- Enable 24-bit colors
opt.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
opt.showmatch = true -- Highlight matching brackets
opt.matchtime = 2 -- How long to show matching bracket
-- opt.cmdheight = 1 -- Command line height
opt.showmode = true -- Show mode
opt.pumblend = 10 -- Popup blend
opt.pumheight = 10 -- Maximum number of entries in a popup
opt.completeopt = "menu,menuone,noselect,popup"
opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
opt.confirm = true -- Confirm to save changes before exiting modified buffer
opt.concealcursor = ""
opt.synmaxcol = 300 -- Syntax highlighting limit
opt.ruler = false -- Disable the default ruler
opt.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
opt.winminwidth = 5 -- Minimum window width
opt.winborder = "rounded"

opt.backup = false -- Don't create backup files
opt.writebackup = false -- Don't create backup before writing
opt.swapfile = false -- Don't create swap files
opt.undofile = true -- Persistent undo
opt.undolevels = 10000
opt.updatetime = 200 -- Save swap file and trigger CursorHold
opt.timeoutlen = 1000 -- Custom multi-key command timeout
opt.ttimeoutlen = 10 -- Key code timeout (too high, and esc feels laggy, too low, and terminal codes can get broken up resulting in bad input being processed)
opt.autoread = true -- Auto reload files changed outside vim
opt.autowrite = false -- Auto save

-- Behavior settings
opt.hidden = true -- Allow hidden buffers
opt.errorbells = false -- No error bells
opt.backspace = "indent,eol,start" -- Better backspace behavior
opt.autochdir = false -- Don't auto change directory
opt.iskeyword:append("-") -- Treat dash as part of word
opt.path:append("**") -- include subdirectories in search
opt.selection = "inclusive" -- Selection behavior
opt.mouse = "a" -- Enable mouse support
opt.modifiable = true -- Allow buffer modifications
opt.encoding = "UTF-8" -- Set encoding

opt.smoothscroll = true
opt.foldmethod = "indent"
-- opt.foldmethod = "expr"
-- opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99 -- Start with all folds open
opt.formatoptions = "jcroqlnt" -- tcqj
opt.grepprg = "rg --vimgrep"
opt.grepformat = "%f:%l:%c:%m"

opt.splitbelow = true -- Put new windows below current
opt.splitright = true -- Put new windows right of current
opt.splitkeep = "screen"

opt.wildmenu = true
opt.wildmode = "longest:full,full" -- Command-line completion mode

-- A better diff configuration
opt.diffopt:append("internal,filler,closeoff,indent-heuristic,algorithm:histogram,linematch:60") -- Keep an eye out for gitsigns issues

-- Performance improvements
opt.redrawtime = 10000 -- Allow more time for syntax highlighting to complete
opt.maxmempattern = 20000 -- Allow more memory for regex

opt.jumpoptions = "view"
opt.laststatus = 3 -- global statusline
opt.linebreak = true -- Wrap lines at convenient points
opt.list = true -- Show some invisible characters (tabs...)
opt.shortmess:append({ W = true, I = true, c = true, C = true })

opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
opt.foldtext = ""
-- opt.formatexpr = "v:lua.LazyVim.format.formatexpr()"
opt.inccommand = "nosplit" -- preview incremental substitute
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
opt.spelllang = { "en" }
-- opt.statuscolumn = [[%!v:lua.LazyVim.statuscolumn()]]
-- opt.timeoutlen = vim.g.vscode and 1000 or 300 -- Lower than default (1000) to quickly trigger which-key

-- Put cwd on statusline
function _G.get_cwd()
  local cwd = vim.fn.getcwd()
  return vim.fn.fnamemodify(cwd, ":~")
end
vim.opt.statusline = "%F %m %= [%{%v:lua.get_cwd()%}] %l:%c"

