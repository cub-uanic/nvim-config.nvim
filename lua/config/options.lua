-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.have_nerd_font = true
vim.g.lazyvim_picker = "telescope"

vim.opt.exrc = true
vim.opt.secure = true
-- vim.opt.mouse = ""
-- vim.opt.clipboard = "" -- Отключить автокопирование в системный буфер
vim.opt.spell = false
vim.opt.spelllang = ""
vim.opt.spellfile = vim.fn.expand "~/.vim/spell/local.utf-8.add"
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true -- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.updatetime = 250 -- Decrease update time
vim.opt.timeoutlen = 300 -- Decrease mapped sequence wait time
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = "•·", trail = "·", nbsp = "␣" }
vim.opt.modeline = true
vim.opt.modelines = 5
vim.opt.shiftround = true
vim.opt.backspace = { "indent", "eol", "start" }
vim.opt.encoding = "utf-8"
vim.opt.fileencodings = { "utf-8", "default", "latin1" }
vim.opt.breakindent = true
vim.opt.undofile = true -- Enable undo/redo changes even after closing and reopening a file
vim.opt.inccommand = "split" -- Preview substitutions live, as you type
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.scrolloff = 10 -- Minimal number of screen lines to keep above and below the cursor
vim.opt.confirm = true
vim.opt.history = 5000
vim.opt.showmatch = true
vim.opt.autowrite = true
vim.opt.hidden = true
vim.opt.showcmd = true
vim.opt.laststatus = 2

-- vim: ts=2 sts=2 sw=2 et
