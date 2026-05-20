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
      notifier = { enabled = true, timeout = 5000 },
      statuscolumn = { enabled = true },
      scroll = { enabled = false },
    },
  },

  { "folke/persistence.nvim", event = "BufReadPre", opts = { need = 0 } },
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

  -- most preferred colorschemes
  { "catppuccin/nvim" },
  { "folke/tokyonight.nvim" },
  { "tiagovla/tokyodark.nvim" },
  { "rebelot/kanagawa.nvim" },
  { "Mofiqul/dracula.nvim" },

  -- additional colorschemes
  { "EdenEast/nightfox.nvim" },
  { "rose-pine/neovim" },
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
