local map = vim.keymap.set

-- Use <Esc> to exit terminal mode
map('t', '<Esc>', '<C-\\><C-n>')

-- Quit
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

-- Save file
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- New file
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

-- Better indenting in visual mode
map("x", "<", "<gv")
map("x", ">", ">gv")

-- Add undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- Clear search and stop snippet on escape
map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })

-- Better up/down (by visual line rather than logical in case of wrapping)
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Treat movements greater than a line as a jump
-- This adds the previous position to the jumplist
local moves = { "j", "k" }
for _, move in ipairs(moves) do
  map("n", move, function()
    return vim.v.count > 1 and "m'" .. vim.v.count .. move or move
  end, { expr = true, silent = true })
end

-- Clear multicursors
map({'n'}, '<leader>Q', function ()
  local mc_ns = vim.api.nvim_create_namespace('nvim.multicursor')
  vim.api.nvim_buf_clear_namespace(0, mc_ns, 0, -1)
end)

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- Move Lines
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- Buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
-- map("n", "<leader>bd", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })
map("n", "<leader>bd", function()
  _G.MiniBufremove.delete()
end, { desc = "Delete Buffer" })
-- map("n", "<leader>bo", function()
--   Snacks.bufdelete.other()
-- end, { desc = "Delete Other Buffers" })
map("n", "<leader>bD", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })

-- Make n always go forward and N always go backward regaddless of the search command
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Tabs
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

-- Windows
map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })

-- Location list
map("n", "<leader>xl", function()
  local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Location List" })

-- Quickfix list
map("n", "<leader>xq", function()
  local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Quickfix List" })

map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- Diagnostics
local diagnostic_goto = function(next, severity)
  return function()
    vim.diagnostic.jump({
      count = (next and 1 or -1) * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end
map("n", "<leader>ld", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })


-- Fold navigation (not sure I like this)

-- -- Close all folds except current one (great for focus)
-- map("n", "zv", "zMzvzz", { desc = "Close all folds except the current one" })

-- -- Smart fold navigation (closes current, opens next/previous)
-- map("n", "zj", "zcjzOzz", { desc = "Close current fold when open. Always open next fold." })
-- map("n", "zk", "zckzOzz", { desc = "Close current fold when open. Always open previous fold." })


-- LSP
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Actions" })
map("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Code Rename" })
map("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
-- map("n", "<leader>gth", vim.lsp.buf.typehierarchy, { desc = "Show Type Heirarchy" })

-- FzfLua
map("n", "gd", function() FzfLua.lsp_definitions() end, { desc = "Goto Definition" }) -- Native "go to definition of word under the cursor in current function"
map("n", "gr", function() FzfLua.lsp_references() end, { desc = "Goto References" }) -- Native "virtual replace N chars with {char}"
map("n", "gds", function() FzfLua.lsp_document_symbols() end, { desc = "Goto Document Symbols" }) -- No native
map("n", "gws", function() FzfLua.lsp_workspace_symbols() end, { desc = "Goto Workspace Symbols" }) -- No native
map("n", "<leader>/", function() FzfLua.live_grep() end, { desc = "Live Grep" }) -- No native
map("n", "<leader>fo", function() FzfLua.oldfiles() end, { desc = "Goto Oldfiles" }) -- No native
map("n", "<leader>fb", function() FzfLua.buffers() end, { desc = "Goto Buffers" }) -- No native
map("n", "<leader>ff", function() FzfLua.files() end, { desc = "Goto Files" }) -- No native
map("n", "<leader>ft", function() FzfLua.tabs() end, { desc = "Goto Tabs" }) -- No native
map("n", "<leader>fl", function() FzfLua.lines() end, { desc = "Goto Lines" }) -- No native
map("n", "<leader>fj", function() FzfLua.jumps() end, { desc = "FzfLua Jumps" }) -- No native
map("n", "<leader>fr", function() FzfLua.resume() end, { desc = "FzfLua Resume" }) -- No native
map("n", "gm", function() FzfLua.marks() end, { desc = "Goto Marks" }) -- No native

-- TODO: add other fzf-lua keymaps

-- Others:
--Command	List
-- lsp_declarations	Declarations
-- lsp_typedefs	Type Definitions
-- lsp_implementations	Implementations
-- lsp_live_workspace_symbols	Workspace Symbols (live query)
-- lsp_incoming_calls	Incoming Calls
-- lsp_outgoing_calls	Outgoing Calls
-- lsp_type_sub	Sub Types
-- lsp_type_super	Super Types
-- lsp_code_actions	Code Actions
-- lsp_finder	All LSP locations, combined view
-- diagnostics_document	Document Diagnostics
-- diagnostics_workspace	Workspace Diagnostics
-- lsp_document_diagnostics	alias to diagnostics_document
-- lsp_workspace_diagnostics	alias to diagnostics_workspace


-- CD to LSP root
local function cd_to_lsp_root(loc)
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  local dir = vim.fn.expand("%:p:h")
  if #clients > 0 then
    local root = clients[1].config.root_dir
    if root then
      dir = root
    end
  end
  local cmd = (loc and "lcd") or "cd"
  vim.cmd(cmd .. " " .. dir)
  print(cmd .. ": " .. dir)
end
vim.api.nvim_create_user_command('CdLspRoot', function() cd_to_lsp_root() end, {})
vim.api.nvim_create_user_command('LcdLspRoot', function() cd_to_lsp_root(true) end, {})
map('n', '<leader>cd', ':CdLspRoot<CR>', { desc = 'CD to LSP root' })
map('n', '<leader>lcd', ':LcdLspRoot<CR>', { desc = 'LCD to LSP root' })

-- Open Alacritty to current cwd
map('n', '<leader>cm', ':call jobstart(\'cmd /c start "" "alacritty"\', {\'detach\': 1})<CR>', { desc = 'Open Alacritty' })

-- Open Explorer to current cwd
map('n', '<leader>ii', ':call jobstart(\'cmd /c start .\')<CR>', { desc = 'Open Explorer' })

-- nvim-treesitter-textobjects keymaps
-- map({ "x", "o" }, "am", function() require "nvim-treesitter-textobjects.select".select_textobject("@function.outer", "textobjects") end)
-- map({ "x", "o" }, "im", function() require "nvim-treesitter-textobjects.select".select_textobject("@function.inner", "textobjects") end)
-- map({ "x", "o" }, "ac", function() require "nvim-treesitter-textobjects.select".select_textobject("@class.outer", "textobjects") end)
-- map({ "x", "o" }, "ic", function() require "nvim-treesitter-textobjects.select".select_textobject("@class.inner", "textobjects") end)
-- map({ "x", "o" }, "as", function() require "nvim-treesitter-textobjects.select".select_textobject("@local.scope", "locals") end)
map("n", "<leader>a", function() require("nvim-treesitter-textobjects.swap").swap_next "@parameter.inner" end)
map("n", "<leader>A", function() require("nvim-treesitter-textobjects.swap").swap_previous "@parameter.outer" end)
--
map({ "n", "x", "o" }, "]m", function() require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects") end)
-- map({ "n", "x", "o" }, "]]", function() require("nvim-treesitter-textobjects.move").goto_next_start("@class.outer", "textobjects") end)
-- map({ "n", "x", "o" }, "]o", function() require("nvim-treesitter-textobjects.move").goto_next_start({"@loop.inner", "@loop.outer"}, "textobjects") end)
-- map({ "n", "x", "o" }, "]s", function() require("nvim-treesitter-textobjects.move").goto_next_start("@local.scope", "locals") end)
-- map({ "n", "x", "o" }, "]z", function() require("nvim-treesitter-textobjects.move").goto_next_start("@fold", "folds") end)
--
map({ "n", "x", "o" }, "]M", function() require("nvim-treesitter-textobjects.move").goto_next_end("@function.outer", "textobjects") end)
-- map({ "n", "x", "o" }, "][", function() require("nvim-treesitter-textobjects.move").goto_next_end("@class.outer", "textobjects") end)
--
map({ "n", "x", "o" }, "[m", function() require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects") end)
-- map({ "n", "x", "o" }, "[[", function() require("nvim-treesitter-textobjects.move").goto_previous_start("@class.outer", "textobjects") end)
--
map({ "n", "x", "o" }, "[M", function() require("nvim-treesitter-textobjects.move").goto_previous_end("@function.outer", "textobjects") end)
-- map({ "n", "x", "o" }, "[]", function() require("nvim-treesitter-textobjects.move").goto_previous_end("@class.outer", "textobjects") end)

-- Go to either the start or the end, whichever is closer.
-- Use if you want more granular movements
-- map({ "n", "x", "o" }, "]d", function()
--   require("nvim-treesitter-textobjects.move").goto_next("@conditional.outer", "textobjects")
-- end)
-- map({ "n", "x", "o" }, "[d", function()
--   require("nvim-treesitter-textobjects.move").goto_previous("@conditional.outer", "textobjects")
-- end)
--

-- Mini.Map
map('n', '<Leader>mc', MiniMap.close)
map('n', '<Leader>mf', MiniMap.toggle_focus)
map('n', '<Leader>mo', MiniMap.open)
map('n', '<Leader>mr', MiniMap.refresh)
map('n', '<Leader>ms', MiniMap.toggle_side)
map('n', '<Leader>mt', MiniMap.toggle)

-- Mini.Files
map("n", "<leader>fm", function() MiniFiles.open() end, { desc = "Lazygit (Root Dir)" })

-- Fuzzy cd
map({"i","n","v"}, "<M-f>d", function()
  require("fzf-lua").fzf_exec("fd . --type d", { --or fd
  prompt = "~/",
  cwd = "~",
  actions = {
    ["default"] = function(selected)
      if selected and #selected > 0 then
        local root = vim.fn.expand("~").."/"
        vim.cmd("cd " .. root .. selected[1])
      end
    end,
  },
})
end, {silent=true, desc="Fuzzy cd to dir under ~"})

-- On MiniFiles creation
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesBufferCreate",
  callback = function(args)

    -- Keymap to open grug-far with current mini.files column
    map("n", "gs", function()
      local state = require("mini.files").get_explorer_state()
      if not state or not state.branch or not state.depth_focus then return end
      local path = state.branch[state.depth_focus]
      if not path then return end
      local prefills = { paths = path }
      local grug_far = require "grug-far"
      -- instance check
      if not grug_far.has_instance "explorer" then
        grug_far.open {
          instanceName = "explorer",
          prefills = prefills,
          staticTitle = "Find and Replace from Explorer",
        }
      else
        grug_far.get_instance('explorer'):open()
        -- updating the prefills without creating the search and other fields
        grug_far.get_instance('explorer'):update_input_values(prefills, false)
      end
    end, { buffer = args.data.buf_id, desc = "Search in directory" })

    -- Keymap to set cwd to current mini.files column
    map("n", ".", function()
      local state = require("mini.files").get_explorer_state()
      if not state or not state.branch or not state.depth_focus then return end
      local path = state.branch[state.depth_focus]
      if not path then return end
      vim.fn.chdir(path)
      print("CWD changed to: " .. path)
    end, { buffer = args.data.buf_id, desc = "Set CWD to current column directory" })
  end,
})

-- Open Grug-Far, smart visual selection behavior
map({ 'n', 'x' }, '<leader>si', function()
  require('grug-far').open({ visualSelectionUsage = 'auto-detect' })
end, { desc = 'grug-far: Search within range' })

-- TODO -- doesn't work
-- Create a buffer local keybinding to open a result location and immediately close grug-far.nvim
-- vim.api.nvim_create_autocmd('FileType', {
--   group = vim.api.nvim_create_augroup('grug-far-keybindings', { clear = true }),
--   pattern = { 'grug-far' },
--   callback = function()
--     vim.keymap.set('n', '<C-enter>', function()
--       require('grug-far').get_instance(0):open_location()
--       require('grug-far').get_instance(0):close()
--     end, { buffer = true })
--   end,
-- })

-- DAP
map('n', '<F5>', function() require('dap').continue() end)
map('n', '<F10>', function() require('dap').step_over() end)
map('n', '<F11>', function() require('dap').step_into() end)
map('n', '<F12>', function() require('dap').step_out() end)
map('n', '<leader>bp', function() require('dap').toggle_breakpoint() end)
-- map('n', '<leader>B', function() require('dap').set_breakpoint() end)
map('n', '<leader>lp', function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end)
-- map('n', '<leader>dr', function() require('dap').repl.open() end)
-- map('n', '<leader>dl', function() require('dap').run_last() end)

-- Toggleterm
map('n', 'gt', '<cmd>ToggleTerm<cr>')

-- Overseer
map('n', '<leader>or', '<cmd>OverseerRun<cr>')
map('n', '<leader>ot', '<cmd>OverseerToggle<cr>')

-- Open Neogit
map("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "Open Neogit UI" })

-- Open submodule in neogit
-- TODO - Consider making that a buffer local map in neogit
map("n", "gS", function()
  local status = require("neogit.buffers.status")
  local Finder = require("neogit.lib.finder")

  local instance = status.instance()
  if not instance then
    return
  end

  local submodules = instance:submodules()
  if #submodules == 0 then
    vim.notify("No submodules found", vim.log.levels.INFO)
    return
  end

  Finder.create({ prompt_prefix = "submodule" })
    :add_entries(submodules)
    :find(function(choice)
      if choice then
        instance:close()
        require("neogit").open { cwd = vim.fs.joinpath(instance.root, choice) }
      end
    end)
end, { desc = "Neogit: browse all submodules" })

local M = {}

-- Gitsigns keymaps
function M.gitsigns_on_attach(bufnr)
  local gitsigns = require('gitsigns')

  local function lmap(mode, l, r, opts)
    opts = opts or {}
    opts.buffer = bufnr
    vim.keymap.set(mode, l, r, opts)
  end

  -- Navigation
  lmap('n', ']c', function()
    if vim.wo.diff then
      vim.cmd.normal({']c', bang = true})
    else
      gitsigns.nav_hunk('next')
    end
  end)

  lmap('n', '[c', function()
    if vim.wo.diff then
      vim.cmd.normal({'[c', bang = true})
    else
      gitsigns.nav_hunk('prev')
    end
  end)

  -- Actions
  lmap('n', '<leader>hs', gitsigns.stage_hunk)
  lmap('n', '<leader>hr', gitsigns.reset_hunk)

  lmap('v', '<leader>hs', function()
    gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
  end)

  lmap('v', '<leader>hr', function()
    gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
  end)

  lmap('n', '<leader>hS', gitsigns.stage_buffer)
  lmap('n', '<leader>hR', gitsigns.reset_buffer)
  lmap('n', '<leader>hp', gitsigns.preview_hunk)
  lmap('n', '<leader>hi', gitsigns.preview_hunk_inline)

  lmap('n', '<leader>hb', function()
    gitsigns.blame_line({ full = true })
  end)

  -- Look into whether this has use in context of diffview. Standard diff mode is annoying.
  -- lmap('n', '<leader>hd', gitsigns.diffthis)

  lmap('n', '<leader>hD', function()
    gitsigns.diffthis('~')
  end)

  lmap('n', '<leader>hQ', function() gitsigns.setqflist('all') end)
  lmap('n', '<leader>hq', gitsigns.setqflist)

  -- Toggles
  lmap('n', '<leader>tb', gitsigns.toggle_current_line_blame)
  lmap('n', '<leader>tw', gitsigns.toggle_word_diff)

  -- Text object
  lmap({'o', 'x'}, 'ih', gitsigns.select_hunk)
end

-- Setup for mini.ai better text object motions
-- Note: does not work with multicursors for now, as vim.api.nvim_win_set_cursor only seems to affect
-- the regular cursor. Not sure if that will change at any point in the future.
-- TODO - Builtin expr_motion in mini.ai clears its internal cache, which I can't do here. Side effects?
local inside = false
local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")
local function get_tobj_id()
  local ok, char = pcall(vim.fn.getcharstr)
  if not ok or char == '' or char == '\3' or char == '\27' then return nil end
  return char
end
local function mini_ai_move_cursor(side, params)
  local sibling = false
  inside = false
  if params.next == 'next_sibling' then
    sibling = true
    params.next = 'next'
  end
  if params.prev == 'prev_sibling' then
    sibling = true
    params.prev = 'prev'
  end
  local tobj_id = get_tobj_id()
  if tobj_id == nil then return end
  local move = ts_repeat_move.make_repeatable_move(function(opts)
    local new_opts = { search_method = opts.forward and params.next or params.prev }
    for _ = 1, vim.v.count1 do
      -- Sibling navigation requires identifying span of what we're on first
      if sibling then
        local cover_opts = vim.deepcopy(new_opts)
        cover_opts.search_method = 'cover'
        new_opts.reference_region = _G.MiniAi.find_textobject('a', tobj_id, cover_opts)
      end
      -- If visual mode, go back to normal and jump to beginning of selection
      if vim.fn.mode():match("^[vV\27]") ~= nil then
        local esc = vim.api.nvim_replace_termcodes('<esc>', true, false, true)
        vim.api.nvim_feedkeys(esc, 'x', false)
        vim.cmd("normal! `<")
      end
      -- Always move cursor first, than select what we moved to if needed
      _G.MiniAi.move_cursor(side, opts.ai_type or params.ai_type or 'a', tobj_id, new_opts)
    end
    if params.select then
      new_opts.search_method = 'cover'
      new_opts.reference_region = nil
      _G.MiniAi.select_textobject(opts.ai_type or params.ai_type or 'a', tobj_id, new_opts)
      if vim.fn.mode():match("^[vV\27]") ~= nil then
        vim.cmd("normal! o") -- End with cursor at beginning of selection because it feels more natural
      end
    end
  end)
  move({ forward = params.forward })
end

-- Keymaps for mini.ai better text object motions
map({'n', 'o', 'x'}, 'gl', function () mini_ai_move_cursor('left', { forward = true, next = 'next', prev = 'prev_or_cover' }) end)
map({'n', 'o', 'x'}, 'gh', function () mini_ai_move_cursor('left', { forward = false, next = 'next', prev = 'prev_or_cover' }) end)
map({'n', 'o', 'x'}, 'gL', function () mini_ai_move_cursor('left', { forward = true, next = 'next_sibling', prev = 'cover_or_prev' }) end)
map({'n', 'o', 'x'}, 'gH', function () mini_ai_move_cursor('left', { forward = false, next = 'next_sibling', prev = 'cover_or_prev' }) end)
map({'n', 'o', 'x'}, 'gj', function () mini_ai_move_cursor('right', { forward = true, next = 'next_or_cover', prev = 'prev', ai_type = 'i' }) end)
map({'n', 'o', 'x'}, 'gk', function () mini_ai_move_cursor('right', { forward = true, next = 'next_or_cover', prev = 'prev' }) end)
map({'n', 'o', 'x'}, 'gJ', function () mini_ai_move_cursor('right', { forward = false, next = 'next_or_cover', prev = 'prev', ai_type = 'i' }) end)
map({'n', 'o', 'x'}, 'gK', function () mini_ai_move_cursor('right', { forward = false, next = 'next_or_cover', prev = 'prev' }) end)

map({'n', 'o', 'x'}, 'sl', function () mini_ai_move_cursor('left', { select = true, forward = true, next = 'next', prev = 'prev_or_cover' }) end)
map({'n', 'o', 'x'}, 'sh', function () mini_ai_move_cursor('left', { select = true, forward = false, next = 'next', prev = 'prev_or_cover' }) end)
map({'n', 'o', 'x'}, 'sL', function () mini_ai_move_cursor('left', { select = true, forward = true, next = 'next_sibling', prev = 'cover_or_prev' }) end)
map({'n', 'o', 'x'}, 'sH', function () mini_ai_move_cursor('left', { select = true, forward = false, next = 'next_sibling', prev = 'cover_or_prev' }) end)

-- Repeat movement with ; and ,
-- ensure ; goes forward and , goes backward regardless of the last direction
map({ "n", "x", "o" }, ";", function () ts_repeat_move.repeat_last_move({ forward = true, ai_type = inside and 'i' }) end)
map({ "n", "x", "o" }, ",", function () ts_repeat_move.repeat_last_move({ forward = false, ai_type = inside and 'i' }) end)

-- Go inside/outside last mini.ai object, or if last repeatable move was not mini.ai, just repeat normally
map({ "n", "x", "o" }, "g]", function () inside = true; ts_repeat_move.repeat_last_move({ forward = true, ai_type = 'i' }) end)
map({ "n", "x", "o" }, "g[", function () inside = false; ts_repeat_move.repeat_last_move({ forward = false, ai_type = 'a' }) end)

-- Make builtin f, F, t, T also repeatable with ; and ,
map({ "n", "x", "o" }, "f", function() return require("config.qmk").f_wrapper(ts_repeat_move.builtin_f_expr) end, { expr = true })
map({ "n", "x", "o" }, "F", function() return require("config.qmk").f_wrapper(ts_repeat_move.builtin_F_expr) end, { expr = true })
map({ "n", "x", "o" }, "t", function() return require("config.qmk").f_wrapper(ts_repeat_move.builtin_t_expr) end, { expr = true })
map({ "n", "x", "o" }, "T", function() return require("config.qmk").f_wrapper(ts_repeat_move.builtin_T_expr) end, { expr = true })
map({ "n", "x", "o" }, "r", require("config.qmk").r_wrapper, { expr = true })

return M

