-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- @diagnostic disable-next-line: undefined-global
local vim = vim
-- @diagnostic disable-next-line: undefined-global
local LazyVim = LazyVim

local function map(modes, keys, action, desc, extopt)
  if type(keys) ~= "table" then keys = { keys } end
  local opts = vim.tbl_extend("force", { silent = true, desc = desc }, extopt or {})

  for _, key in ipairs(keys) do
    vim.keymap.set(modes, key, action, opts)
  end
end

local function bufmap(modes, keys, action, desc) map(modes, keys, action, desc, { buffer = 0 }) end
local function remap(modes, keys, action, desc) map(modes, keys, action, desc, { remap = true }) end

local function ensure_parent_dir_for_current_buffer()
  local buf = vim.api.nvim_get_current_buf()
  local fname = vim.api.nvim_buf_get_name(buf)

  if fname == nil or fname == "" then return true end -- No name / special buffers
  if fname:match("^%a+://") then return true end -- Don't try to create dirs for non-file buffers (netrw, fugitive, etc.)

  local dir = vim.fn.fnamemodify(fname, ":h")
  if dir == nil or dir == "" or dir == "." then return true end

  if vim.fn.isdirectory(dir) == 1 then return true end

  local msg = ("Directory doesn't exist:\n%s\n\nCreate it (including parents)?"):format(dir)
  local choice = vim.fn.confirm(msg, "&Yes\n&No", 2)
  if choice ~= 1 then return false end

  local ok, err = pcall(vim.fn.mkdir, dir, "p")
  if not ok then
    vim.notify(("Failed to create directory:\n%s\n%s"):format(dir, tostring(err)), vim.log.levels.ERROR)
    return false
  end

  return true
end

local function is_telescope_active()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local buf_type = vim.api.nvim_get_option_value("buftype", { buf = buf })
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_type == "prompt" or buf_name:match("Telescope") then return true end
    end
  end
  return false
end

local function press(keys)
  local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(termcodes, "m", false)
end

local function exec(cmd, return_to_insert)
  if is_telescope_active() then vim.api.nvim_win_close(0, true) end

  local mode = vim.fn.mode(1)
  local was_insert = mode:match("^i")

  if was_insert then vim.cmd("stopinsert") end

  local c = (cmd:match("^%S+") or ""):lower()
  if c:match("^w(rite|all|a)?$") then
    if not ensure_parent_dir_for_current_buffer() then return end
  end

  local ok, err = pcall(function() vim.cmd(cmd) end)
  if not ok then
    if tostring(err):match("E444") then
      vim.notify("Can't close last buffer") --
    end
  end

  if was_insert and return_to_insert then
    local key = ({ i = "i", ic = "i", ix = "i", R = "R", Rc = "R" })[mode] or "i"
    local k = vim.api.nvim_replace_termcodes(key, true, false, true)
    vim.api.nvim_feedkeys(k, "n", false)
  end
end

local function next_window()
  local cur = vim.fn.winnr()
  local last = vim.fn.winnr("$")
  local neww = cur + 1
  if neww > last then neww = 1 end
  vim.cmd(("silent %dwincmd w"):format(neww))
end

local function prev_window()
  local cur = vim.fn.winnr()
  local last = vim.fn.winnr("$")
  local neww = cur - 1
  if neww < 1 then neww = last end
  vim.cmd(("silent %dwincmd w"):format(neww))
end

local function microsnippets_edit(visual_precmd)
  if visual_precmd then vim.api.nvim_feedkeys(visual_precmd, "x", false) end
  local ft = vim.bo.filetype ~= "" and vim.bo.filetype or "all"
  local base = vim.fn.stdpath("config") .. "/microsnippets"
  vim.fn.mkdir(base, "p")
  vim.cmd({ cmd = "edit", args = { base .. "/snippet." .. ft } })
end

local function tagback_or_alternate()
  local ok = pcall(vim.cmd.pop)
  if not ok then
    local alt_bufnr = vim.fn.bufnr("#")
    if alt_bufnr > 0 and vim.api.nvim_buf_is_loaded(alt_bufnr) then
      vim.cmd("buffer #")
    else
      vim.notify("No tag stack and no alternate buffer", vim.log.levels.WARN)
    end
  end
end

local function jump_gd_gf_help_tag()
  local cfile = vim.fn.expand("<cfile>")
  if cfile ~= "" then
    local ok, err = xpcall(function() vim.cmd("normal! gf") end, function(e) return tostring(e) end)
    if ok then return end
    if not (err and (err:match("E447") or err:match("E446"))) then error(err) end
  end

  local cword = vim.fn.expand("<cword>")
  if cword ~= "" then
    local pattern = "^" .. vim.fn.escape(cword, [[\.^$~[]]) .. "$"
    if next(vim.fn.taglist(pattern)) ~= nil then
      vim.cmd.tag(cword)
      return
    end
  end

  local cWORD = vim.fn.expand("<cWORD>")
  local tag = cWORD:match("|([^|]+)|")
  if tag then
    vim.cmd.help(tag)
    return
  end

  vim.notify("No file or tag under cursor", vim.log.levels.INFO)
end

local function jump_lsp_or_fallback()
  local clients = vim.lsp.get_clients({ bufnr = 0 })

  local function supported_clients(method)
    local ret = {}
    for _, client in ipairs(clients) do
      if client:supports_method(method) then table.insert(ret, client) end
    end
    return ret
  end

  local function current_pos()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    return row - 1, col
  end

  local function make_pos_params()
    local curline, curcol = current_pos()
    return {
      textDocument = vim.lsp.util.make_text_document_params(0),
      position = { line = curline, character = curcol },
    }
  end

  local function normalize_location(loc)
    if loc.uri == nil and loc.targetUri ~= nil then return {
      uri = loc.targetUri,
      range = loc.targetSelectionRange or loc.targetRange,
    } end
    return loc
  end

  local function position_in_range(pos, range)
    local line, col = pos[1], pos[2]
    local start_line, start_col = range.start.line, range.start.character
    local end_line, end_col = range["end"].line, range["end"].character

    if line < start_line or line > end_line then return false end
    if line == start_line and col < start_col then return false end
    if line == end_line and col >= end_col then return false end
    return true
  end

  local function same_location_as_cursor(loc)
    if not loc then return false end

    local curline, curcol = current_pos()
    local cururi = vim.uri_from_bufnr(0)

    if loc.targetUri then
      if loc.targetUri ~= cururi then return false end
      local range = loc.targetSelectionRange or loc.targetRange
      return range and position_in_range({ curline, curcol }, range) or false
    end

    if loc.uri then
      if loc.uri ~= cururi then return false end
      return loc.range and position_in_range({ curline, curcol }, loc.range) or false
    end

    return false
  end

  local function first_location_from(method, params)
    local matched = supported_clients(method)
    if vim.tbl_isempty(matched) then return nil end

    local results = vim.lsp.buf_request_sync(0, method, params, 1000)
    if not results then return nil end

    for _, client in ipairs(matched) do
      local res = results[client.id]
      local result = res and res.result

      if result and not vim.tbl_isempty(result) then
        local loc = vim.islist(result) and result[1] or result
        return normalize_location(loc)
      end
    end

    return nil
  end

  local def_loc = first_location_from("textDocument/definition", make_pos_params())

  if def_loc then
    if same_location_as_cursor(def_loc) then
      if not vim.tbl_isempty(supported_clients("textDocument/references")) then
        press("gr")
        return
      end
    else
      press("gd")
      return
    end
  end

  jump_gd_gf_help_tag()
end

local function cmd_only() exec("only") end
local function cmd_copen() exec("copen") end
local function cmd_close() exec("close") end
local function cmd_write() exec("w") end
local function cmd_writeall() exec("wall") end
local function cmd_writeall_quit() exec("wqa") end
local function cmd_quit_all() exec("qa") end
local function cmd_quit_all_force() exec("qa!") end
local function cmd_toggle_bom() vim.bo.bomb = not vim.bo.bomb end
local function cmd_toggle_listchars() vim.opt.list = not vim.opt.list end
local function cmd_tb_symbol_list() LazyVim.pick("lsp_document_symbols")() end
local function cmd_tb_tag_list() LazyVim.pick("tags")() end
local function cmd_tb_recent() LazyVim.pick("oldfiles")() end
local function cmd_tb_buf_ff() LazyVim.pick("grep_curbuf")() end
local function cmd_tb_buffers() LazyVim.pick("buffers")() end
local function cmd_git_blame_line() require("blame-column").toggle() end
local function cmd_edit_alt() exec("edit #") end
local function cmd_cp() exec("cp") end
local function cmd_bp() exec("bp") end
local function cmd_cn() exec("cn") end
local function cmd_bn() exec("bn") end
local function cmd_j_yank() exec([["jy]]) end
local function cmd_f_yank() exec([["fy]]) end
local function cmd_j_paste() exec([["jP]]) end
local function cmd_f_paste() exec([["fP]]) end
local function cmd_v_microsnippets_yank() microsnippets_edit("y") end
local function cmd_v_microsnippets_del() microsnippets_edit("d") end
local function cmd_c_microsnippets() microsnippets_edit() end
local function cmd_f9_format() LazyVim.format({ force = true }) end
local function cmd_s_f9_lens_toggle() vim.lsp.codelens.enable(not vim.lsp.codelens.is_enabled()) end
local function cmd_c_f9_format_and_select()
  LazyVim.format({ force = true })
  cmd_write()
  LazyVim.pick()()
end
local function cmd_search_picker() LazyVim.pick("builtin", { fuzzy = true })() end
local function cmd_search_buffers_fzf() LazyVim.pick("lines", { fuzzy = true })() end
local function cmd_lg_cword() LazyVim.pick("live_grep", { default_text = vim.fn.expand("<cword>") })() end
local function cmd_security_file() vim.cmd("edit " .. vim.fn.fnameescape(vim.fn.stdpath("state") .. "/trust")) end
local function cmd_yank_to_system() vim.fn.setreg("+", vim.fn.getreg('"')) end
local function cmd_reset_search() exec("nohlsearch") end
local function cmd_c_tab() LazyVim.pick("buffers", { sort_mru = true, ignore_current_buffer = true })() end

--
-- Hotkeys definitions
--
map("n", "<Esc>", cmd_reset_search, "Clear highlights")
map("n", "<Bslash><Bslash>", cmd_reset_search, "Clear highlights")
map("n", "<CR>", jump_lsp_or_fallback, "Go to def/gf/tag")
map("n", "<BS>", tagback_or_alternate, "Go to back or alternate file")

-- Yank to system clipboard - TODO: delete?.. seems not really needed in LazyVim
map("n", "<Leader>y", cmd_yank_to_system, "Send last yank/delete to system clipboard")
map({ "n", "v" }, "<Leader>Y", '"+y', "Yank to system clipboard")

-- Move between windows
map("n", "<C-n>", "<C-w>h", "Window left")
map("n", "<C-e>", "<C-w>k", "Window up")
map("n", "<C-o>", "<C-w>j", "Window down")
map("n", "<C-i>", "<C-w>l", "Window right")

-- Resize windows (useful for terminal splits)
map("n", "<C-S-n>", "<C-w><", "Decrease window width")
map("n", "<C-S-e>", "<C-w>+", "Increase window height")
map("n", "<C-S-o>", "<C-w>-", "Decrease window height")
map("n", "<C-S-i>", "<C-w>>", "Increase window width")

map("n", "<A-Left>", "<C-w><", "Decrease window width")
map("n", "<A-Down>", "<C-w>+", "Increase window height")
map("n", "<A-Up>", "<C-w>-", "Decrease window height")
map("n", "<A-Right>", "<C-w>>", "Increase window width")

-- map("n", "<C-u>", "<C-w>+", "Increase window height")
-- map("n", "<C-p>", "<C-w>-", "Decrease window height")

-- Terminal mode (works with toggleterm.nvim and any :terminal)
map("t", "<C-n>", [[<C-\><C-n><C-w>h]], "Terminal window left")
map("t", "<C-e>", [[<C-\><C-n><C-w>k]], "Terminal window up")
map("t", "<C-o>", [[<C-\><C-n><C-w>j]], "Terminal window down")
map("t", "<C-i>", [[<C-\><C-n><C-w>l]], "Terminal window right")

-- Terminal key passthrough (Tab, F-keys)
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    bufmap("t", "<Tab>", [[<Tab>]]) -- Tab → shell completion
    for i = 1, 36 do
      bufmap("t", "<F" .. i .. ">", "<F" .. i .. ">") -- Function keys → shell (F1–F36)
    end
  end,
})

-- Remap for Workman
remap({ "n", "i", "v" }, "<A-e>", "<A-k>", "Move Up")
remap({ "n", "i", "v" }, "<A-o>", "<A-j>", "Move Down")

-- F1
map({ "n", "i" }, "<F1>", cmd_only, "Leave only this")
map({ "n", "i" }, { "<S-F1>", "<F13>" }, cmd_copen, "Quickfix open")
map({ "n", "i" }, { "<C-F1>", "<F25>" }, cmd_close, "Quickfix close")

-- F2
map({ "n", "i" }, "<F2>", cmd_write, "Save")
map({ "n", "i" }, { "<S-F2>", "<F14>" }, cmd_writeall, "Save All")
-- microsnippets
map("v", "<F2>", cmd_v_microsnippets_yank, "Microsnippets (yank)")
map("v", { "<C-F2>", "<F26>" }, cmd_v_microsnippets_del, "Microsnippets (yank)")
map({ "n", "i" }, { "<C-F2>", "<F26>" }, cmd_c_microsnippets, "Microsnippets")

-- F3
map({ "n", "i" }, { "<S-F3>", "<F15>" }, cmd_toggle_bom, "Toggle BOM")
map({ "n", "i" }, { "<C-F3>", "<F27>" }, cmd_toggle_listchars, "Toggle Listchars")

-- F4
map({ "n", "i" }, "<F4>", cmd_tb_symbol_list, "Symbols list")
map({ "n", "i" }, { "<S-F4>", "<F16>" }, cmd_tb_tag_list, "Tags list") -- :TlistToggle   TODO: delete? requires ctags

-- F5
map({ "n", "i" }, "<F5>", cmd_tb_recent, "Recent files")
map({ "n", "i" }, { "<S-F5>", "<F17>" }, cmd_git_blame_line, "Toggle Git blame")
map({ "n", "i" }, { "<C-F5>", "<F29>" }, cmd_tb_buf_ff, "Fuzzy in current buffer")

-- F6
map({ "n", "i" }, "<F6>", cmd_tb_buffers, "Telescope: buffers")
map({ "n", "i" }, { "<S-F6>", "<F18>" }, cmd_tb_tag_list, "Tags list") -- :Tags   TODO: delete? requires ctags
map({ "n", "i" }, { "<C-F6>", "<F30>" }, cmd_edit_alt, "Edit alternate file")

-- F7
map({ "n", "i" }, "<F7>", next_window, "Next window")
map({ "n", "i" }, { "<S-F7>", "<F19>" }, cmd_bp, "Prev buffer")
map({ "n", "i" }, { "<C-F7>", "<F31>" }, cmd_cp, "Prev quickfix")

-- F8
map({ "n", "i" }, "<F8>", prev_window, "Prev window")
map({ "n", "i" }, { "<S-F8>", "<F20>" }, cmd_bn, "Next buffer")
map({ "n", "i" }, { "<C-F8>", "<F32>" }, cmd_cn, "Next quickfix")

-- F9
map({ "n", "i" }, "<F9>", cmd_f9_format, "Format code")
map({ "n", "i" }, { "<S-F9>", "<F21>" }, cmd_s_f9_lens_toggle, "Toggle Codelens")
map({ "n", "i" }, { "<C-F9>", "<F33>" }, cmd_c_f9_format_and_select, "Format code and select")

-- F10
map({ "n", "i" }, "<F10>", cmd_quit_all, "Quit")
map({ "n", "i" }, { "<S-F10>", "<F22>" }, cmd_writeall_quit, "Save all & Quit")
map({ "n", "i" }, { "<C-F10>", "<F34>" }, cmd_quit_all_force, "Force Quit")

-- F11
-- TODO: <S-F11> :SessionOpen elc

-- F12
map({ "n", "i" }, "<F12>", cmd_quit_all, "Quit")
-- TODO: <S-F12> :SessionOpen default
-- TODO: <C-F12> :call UpdateTags() -- delete? requires ctags

-- fast access to Yank/Paste (workman)
map({ "n", "v", "i" }, "<C-Y>", cmd_j_yank, 'Yank to "j"')
map({ "n", "v", "i" }, "<C-N>", cmd_f_yank, 'Yank to "f"')
map({ "n", "i" }, "<C-K>", cmd_j_paste, 'Paste from "j"')
map({ "n", "i" }, "<C-L>", cmd_f_paste, 'Paste from "f"')

-- misc searches
map("n", "<Leader>sp", cmd_search_picker, "FZF picker")
map("n", "<Leader>sB", cmd_search_buffers_fzf, "Buffer Lines (fzf)")
map("n", "<Leader>sv", cmd_lg_cword, "LiveGrep (cword)")

-- Edit trust database
map("n", "<Leader>fs", cmd_security_file, "Edit trust database")

-- TODO: Mirror/Reverse

-- Marks shortcuts (Tab-f/u/p/$ and jumps)
map("n", "<Leader><Tab>f", "mF", "Set mark F")
map("n", "<Leader><Tab>u", "mU", "Set mark U")
map("n", "<Leader><Tab>p", "mP", "Set mark P")
map("n", "<Leader><Tab>;", "mA", "Set mark A")
map("n", "<Leader><Tab>n", "'F", "Jump to mark F")
map("n", "<Leader><Tab>e", "'U", "Jump to mark U")
map("n", "<Leader><Tab>o", "'P", "Jump to mark P")
map("n", "<Leader><Tab>i", "'A", "Jump to mark A")

-- Indent shortcuts (< >)
-- ORIGINAL (.vimrc): nmap < << ; nmap > >> ; vmap < <gv ; vmap > >gv ; vmap <Tab>/<S-Tab>
map("n", "<Tab>", ">>", "Indent block right")
map("n", "<S-Tab>", "<<", "Indent block left")
map("v", ">", ">gv", "Indent block right")
map("v", "<", "<gv", "Indent block left")
map("v", "<Tab>", ">gv", "Indent block right")
map("v", "<S-Tab>", "<gv", "Indent block left")

-- TODO: implement IDEA-like mappings

--[[

 Group / Feature                              | Used   | Hotkey (macOS IDEA) | Overwrite (IDEA keymap)    | LazyVim Command                            | Hotkey (LazyVim)              | Implementation
 -------------------------------------------- | ------ | ------------------- | -------------------------- | ------------------------------------------ | ----------------------------- | --------------
 Navigation / Switcher                        | 36456  | Ctrl+Tab            | —                          | Buffers: list / switch                     | <leader>bb / <S-h> / <S-l>    | Ctrl+Tab
 Navigation / Go to declaration               | 35983  | Cmd+B               | —                          | LSP: go to definition                      | gd                            | Enter
 Code Editing / Syntax aware selection        | 15383  | Option+Up           | —                          | Treesitter incremental selection           | v → + / -                     |
 Navigation / Recent files popup              | 9266   | Cmd+E               | —                          | Telescope: recent files                    | <leader>fr                    |
 Code Completion / Replace By (lookup)        | 6911   | Tab                 | —                          | nvim-cmp: confirm completion               | <Tab>                         |
 Code Completion / Variable name completion   | 6403   | Ctrl+Alt+Space      | —                          | nvim-cmp: LSP completion                   | <C-Space>                     |
 Code Completion / Basic code completion      | 6287   | Ctrl+Space          | —                          | nvim-cmp: trigger completion               | <C-Space>                     |
 Navigation / Search Everywhere               | 5672   | Double Shift        | Cmd+Space / Ctrl+Space     | Telescope: files / live grep               | <leader><leader> / <leader>sg |
 UI Usability / Speed search in trees         | 3987   | (type to search)    | —                          | Telescope fuzzy search                     | (type after Telescope)        |
 Code Assistants / Context actions            | 3819   | Option+Enter        | —                          | LSP: code actions                          | <leader>ca                    |
 Refactoring / Rename                         | 2192   | Shift+F6            | —                          | LSP: rename symbol                         | <leader>rn                    |
 Navigation / Go to implementation            | 2181   | Option+Cmd+B        | —                          | LSP: go to implementation                  | gI                            |
 Navigation / Find                            | 1937   | Cmd+F               | —                          | / (buffer search)                          | /                             |
 Code Assistants / Comment line               | 1924   | Cmd+/               | —                          | Toggle comment                             | gcc                           |
 Code Editing / Reformat code                 | 1850   | Option+Cmd+L        | —                          | Format buffer                              | <leader>cf                    |
 Navigation / File structure popup            | 1484   | Cmd+F12             | —                          | Symbols outline                            | <leader>ss                    |
 Database / Execute SQL Statement             | 792    | Cmd+Enter           | —                          | ❌ vim-dadbod-ui                           | -                             |
 Database / Database Table Editor             | 731    | —                   | —                          | ❌ vim-dadbod-ui                           | -                             |
 Refactoring / Introduce Variable             | 652    | Option+Cmd+V        | —                          | ❌ refactoring.nvim                        | -                             |
 Code Assistants / Highlight method throws    | 618    | —                   | —                          | ❌ (IDE inspection)                        | -                             |
 Code Editing / Multiple carets               | 607    | Option+Click        | —                          | vim-visual-multi                           | <C-n>                         |
 UI Usability / Open Project tool window      | 536    | Cmd+1               | Cmd+1                      | neo-tree                                   | <leader>e                     |
 UI Usability / Hide tool window              | 517    | Shift+Esc           | —                          | Close buffer                               | <leader>bd                    |
 Code Completion / CamelCase prefixes         | 419    | —                   | —                          | nvim-cmp                                   | auto                          |
 Code Assistants / Quick Documentation popup  | 207    | F1                  | —                          | LSP hover                                  | K                             |
 Navigation / Show inheritance hierarchy      | 178    | Ctrl+H              | Ctrl+H / Cmd+Alt+H         | ❌ lspsaga / aerial                        | -                             |
 Refactoring / Introduce Variable (quick)     | 174    | —                   | —                          | ❌ refactoring.nvim                        | -                             |
 Navigation / Find in files                   | 171    | Cmd+Shift+F         | —                          | Telescope live grep                        | <leader>sg                    |
 Code Assistants / Quick Doc on navigation    | 165    | —                   | —                          | LSP hover                                  | K                             |
 -------------------------------------------- | ------ | ------------------- | -------------------------- | ------------------------------------------ | ----------------------------- | --------------
 Group / Feature                              | Used   | Hotkey (macOS IDEA) | Overwrite (IDEA keymap)    | LazyVim Command                            | Hotkey (LazyVim)              |
 -------------------------------------------- | ------ | ------------------- | -------------------------- | ------------------------------------------ | ----------------------------- | --------------
 UI / Project tool window                     | 0      | —                   | Cmd+1 / Cmd+!              | neo-tree                                   | <leader>e                     |
 UI / Bookmarks tool window                   | 0      | —                   | Cmd+2 / Cmd+@              | ❌ (нет аналога)                           | -                             |
 UI / Database tool window                    | 0      | —                   | Cmd+3 / Cmd+#              | ❌ vim-dadbod-ui                           | -                             |
 UI / Run tool window                         | 0      | —                   | Cmd+4 / Cmd+{              | dap / run                                  | <leader>dr                    |
 UI / Debug tool window                       | 0      | —                   | Cmd+5 / Cmd+}              | dap-ui                                     | <leader>du                    |
 UI / Problems tool window                    | 0      | —                   | Cmd+6 / Cmd+[              | Diagnostics                                | <leader>xd                    |
 UI / Structure tool window                   | 0      | —                   | Cmd+7 / Cmd+]              | Symbols outline                            | <leader>ss                    |
 UI / Services tool window                    | 0      | —                   | Cmd+8 / Cmd+*              | ❌                                         | -                             |
 UI / Commit tool window                      | 0      | —                   | Cmd+0 / Cmd+)              | LazyGit                                    | <leader>gg                    |
 Navigation / Search Everywhere               | 0      | Double Shift        | Cmd+Space / Ctrl+Space     | Telescope                                  | <leader><leader>              |
 Editor / Delete line                         | 0      | Cmd+Backspace       | Cmd+Backspace              | delete line                                | dd                            |
 Editor / Increase font size                  | 0      | —                   | Shift+Alt+=                | ❌                                         | -                             |
 Editor / Decrease font size                  | 0      | —                   | Shift+Alt+-                | ❌                                         | -                             |
 Editor / Reset font size                     | 0      | —                   | Shift+Alt+)                | ❌                                         | -                             |
 Editor / Move paragraph forward              | 0      | —                   | Shift+Alt+]                | ❌                                         | -                             |
 Editor / Move paragraph backward             | 0      | —                   | Shift+Alt+[                | ❌                                         | -                             |
 VCS / Annotate (blame)                       | 0      | —                   | Ctrl+Shift+A               | gitsigns blame                             | <leader>gb                    |
 Completion / Inline completion               | 0      | —                   | Shift+Alt+\ / Shift+Ctrl+\ | ❌ (copilot-like)                          | -                             |
 UI / Toggle distraction free mode            | 0      | —                   | Shift+Alt+\ / Shift+Cmd+\  | zen-mode                                   | <leader>uz                    |
 -------------------------------------------- | ------ | ------------------- | -------------------------- | ------------------------------------------ | ----------------------------- | --------------
 Group / Feature                              | Used   | Hotkey (macOS IDEA) | Overwrite (IDEA keymap)    | LazyVim Command                            | Hotkey (LazyVim)              |

--]]

map("n", "<C-Tab>", cmd_c_tab, "Navigation / Switcher")

-- load last session
vim.schedule(function()
  local ok, persistence = pcall(require, "persistence")
  if ok and vim.fn.argc() == 0 then persistence.load() end
end)

-- vim: ts=2 sts=2 sw=2 et
