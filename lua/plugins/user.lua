return {
  {
    "LazyVim/LazyVim",
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },

  {
    "folke/snacks.nvim",
    priority = 1000,
    opts = {
      picker = { enabled = true },
      notifier = { enabled = true, timeout = 2000 },
      statuscolumn = { enabled = true },
      scroll = { enabled = false },
    },
    keys = {
      { "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
    },
  },

  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    keys = {
      { "<leader>qw", function() require("persistence").save() end, desc = "Write Session" },
    },
  },

  { "akinsho/bufferline.nvim", enabled = false },
  { "Yu-Leo/blame-column.nvim" },

  {
    "nvim-mini/mini.hipatterns",
    opts = {
      highlighters = {
        tab_after_nontab = { group = "ExtraWhitespace", pattern = "[^\t]()\t+()" },
        trailing_whspace = { group = "ExtraWhitespace", pattern = "%f[%s]%s*$" },
        spaces_befor_tab = { group = "ExtraWhitespace", pattern = " +\t%s*" },
        tab_before_space = { group = "ExtraWhitespace", pattern = "\t+ %s*" },
        line_over_length = { group = "OverLength", pattern = "^" .. (("."):rep(160)) .. "().+" },

        fixm = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
        hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
        todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
        note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
      },
    },
  },

  {
    "nickjvandyke/opencode.nvim",
    version = "*", -- Latest stable release
    dependencies = {
      {
        "folke/snacks.nvim",
        optional = true,
        opts = {
          input = {}, -- Enhances `ask()`
          picker = { -- Enhances `select()`
            actions = { opencode_send = function(...) return require("opencode").snacks_picker_send(...) end },
            win = { input = { keys = { ["<A-a>"] = { "opencode_send", mode = { "n", "i" } } } } },
          },
        },
      },
    },
    config = function()
      vim.o.autoread = true

      vim.keymap.set({ "n", "x" }, "<C-.>", function() require("opencode").ask("@this: ", { submit = true }) end, { desc = "Ask opencode…" })
      vim.keymap.set({ "n", "x" }, "<C-,>", function() require("opencode").select() end, { desc = "Select opencode…" })
      vim.keymap.set({ "n", "t" }, "<C-\\>", function() require("opencode").toggle() end, { desc = "Toggle opencode" })

      vim.keymap.set({ "v", "x" }, "go", function() return require("opencode").operator("@this ") end, { desc = "Add range to opencode", expr = true })
      vim.keymap.set("n", "go", function() return require("opencode").operator("@this ") .. "_" end, { desc = "Add line to opencode", expr = true })

      vim.keymap.set("n", "<S-C-u>", function() require("opencode").command("session.half.page.up") end, { desc = "Scroll opencode up" })
      vim.keymap.set("n", "<S-C-d>", function() require("opencode").command("session.half.page.down") end, { desc = "Scroll opencode down" })
    end,
  },

  {
    "saghen/blink.cmp",
    version = "1.*", -- use a release tag to download pre-built binaries
    opts = {
      keymap = { preset = "enter" },
      completion = { list = { selection = { preselect = false, auto_insert = false } } },
      sources = {
        default = { "buffer" },
        providers = {
          lsp = { fallbacks = {} },
          buffer = {
            opts = {
              -- completion from all open buffers
              get_bufnrs = function()
                return vim.tbl_filter(function(bufnr) return vim.bo[bufnr].buftype == "" end, vim.api.nvim_list_bufs())
              end,
            },
          },
        },
      },
    },
  },

  {
    "Exafunction/codeium.nvim",
    dependencies = {
      "saghen/blink.cmp",
    },
    config = function()
      require("codeium").setup({
        enable_cmp_source = true,
        virtual_text = {
          enabled = true,
          manual = true,
          idle_delay = 50,
          map_keys = true,
          key_bindings = {
            accept = "<Tab>",
            accept_word = "<C-w>",
            accept_line = "<C-l>",
            next = "<C-f>",
            prev = "<C-u>",
            clear = "<C-x>",
          },
        },
      })

      local cmp = require("blink.cmp")
      local codeium = require("codeium.virtual_text")

      vim.keymap.set("i", "<C-;>", function()
        cmp.hide()
        if not codeium.get_current_completion_item() then codeium.complete() end
        codeium.cycle_completions(1)
      end, { desc = "Codeium next completion" })

      vim.keymap.set("i", "<C-S-;>", function()
        cmp.hide()
        if not codeium.get_current_completion_item() then codeium.complete() end
        codeium.cycle_completions(-1)
      end, { desc = "Codeium prev completion" })

      vim.keymap.set("i", "<C-'>", function()
        codeium.clear()
        if cmp.is_visible() then
          cmp.select_next()
        else
          cmp.show()
        end
      end, { desc = "Blink next completion" })

      vim.keymap.set("i", "<C-S-'>", function()
        codeium.clear()
        if cmp.is_visible() then
          cmp.select_prev()
        else
          cmp.show()
        end
      end, { desc = "Blink prev completion" })

      vim.api.nvim_set_hl(0, "CodeiumSuggestion", { link = "Comment" })
    end,
  },

  {
    "kristijanhusak/vim-dadbod-ui",
    keys = {
      { "<A-3>", "<cmd>DBUIToggle<CR>", desc = "Toggle DBUI" },
    },
  },

  -- most preferred colorschemes
  { "catppuccin/nvim" },
  { "folke/tokyonight.nvim" },
  { "tiagovla/tokyodark.nvim" },
  { "rebelot/kanagawa.nvim" },
  { "Mofiqul/dracula.nvim" },
  { "nickkadutskyi/jb.nvim" },

  -- additional colorschemes
  { "EdenEast/nightfox.nvim" },
  { "rose-pine/neovim", name = "rose-pine", config = function() require("rose-pine").setup({}) end },
  { "marko-cerovac/material.nvim" },
  { "shaunsingh/nord.nvim" },
  { "navarasu/onedark.nvim" },
  { "projekt0n/github-nvim-theme" },
  { "bluz71/vim-moonfly-colors" },
  { "bluz71/vim-nightfly-colors" },
  { "ribru17/bamboo.nvim", config = function() require("bamboo").setup({}) end },
  { "the-coding-doggo/batman.nvim" },
  { "ellisonleao/gruvbox.nvim" },
  { "sainnhe/gruvbox-material" },
  { "sainnhe/everforest" },
  { "sainnhe/sonokai" },
  { "eldritch-theme/eldritch.nvim" },
  { "ankushbhagats/pastel.nvim" },
  { "lfenzo/fusion.nvim" },
  { "nyoom-engineering/oxocarbon.nvim" },
  { "vague-theme/vague.nvim" },
  { "zenbones-theme/zenbones.nvim" },
  { "AlexvZyl/nordic.nvim" },
  { "savq/melange-nvim" },
  { "rmehri01/onenord.nvim" },
  { "ntk148v/habamax.nvim" },
  { "uloco/bluloco.nvim" },
  { "dgox16/oldworld.nvim", lazy = false },
  { "daschw/leaf.nvim", config = function() require("leaf").setup({ theme = "dark", contrast = "medium" }) end },
  { "brargenzilian/darcula-solid.nvim", dependencies = { "rktjmp/lush.nvim" } },
  { "adisen99/apprentice.nvim", dependencies = { "rktjmp/lush.nvim" } },
  { "rockyzhang24/arctic.nvim", dependencies = { "rktjmp/lush.nvim" } },
  { "adisen99/codeschool.nvim", dependencies = { "rktjmp/lush.nvim" } },
  { "PyGamer0/darc.nvim", dependencies = { "rktjmp/lush.nvim" } },
  { "muchzill4/doubletrouble", dependencies = { "rktjmp/lush.nvim" } },
  { "npxbr/gruvbox.nvim", dependencies = { "rktjmp/lush.nvim" } },
  { "metalelf0/jellybeans-nvim", dependencies = { "rktjmp/lush.nvim" } },
  { "meliora-theme/neovim", dependencies = { "rktjmp/lush.nvim" } },
}

-- vim: ts=2 sts=2 sw=2 et
