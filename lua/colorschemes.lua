local M = {}

M.theme_groups = {
  {
    group = "Default",
    themes = {
      "default",
    },
  },
  {
    group = "Popular",
    themes = {
      "jb",
      "catppuccin-frappe",
      "catppuccin-macchiato",
      "catppuccin-mocha",
      "dracula",
      "kanagawa-dragon",
      "kanagawa-wave",
      "tokyonight-moon",
      "tokyonight-storm",
      "tokyonight-night",
      "tokyodark",
      "wildcharm",
      "carbonfox",
      "nightfox",
      "terafox",
      "nordfox",
      "duskfox",
      "rose-pine-main",
      "rose-pine-moon",
      "oxocarbon",
      "material-darker",
      "material-oceanic",
      "material-palenight",
      "material-deep-ocean",
      "nord",
    },
  },
  {
    group = "Rare",
    themes = {
      "arctic",
      "bamboo-multiplex",
      "bamboo-vulgaris",
      "batman",
      "bluloco-dark",
      "darcula-solid",
      "eldritch-dark",
      "eldritch-minimal",
      "everforest",
      "fusion",
      "gruvbox-material",
      "moonfly",
      "nightfly",
      "nordic",
      "onenord",
      "sonokai",
      "vague",
      "zenburned",
      "zenwritten",
    },
  },
  {
    group = "GitHub",
    themes = {
      "github_dark_colorblind",
      "github_dark_default",
      "github_dark_dimmed",
      "github_dark_high_contrast",
      "github_dark_tritanopia",
    },
  },
  {
    group = "Pastel",
    themes = {
      "pastelblack",
      "pastelcool",
      "pastelcream",
      "pasteldark",
      "pastelfog",
      "pastelmint",
      "pastelpop",
      "pastelrose",
      "pastelwarm",
    },
  },
  {
    group = "Simplie",
    themes = {
      "quiet",
      "duckbones",
      "forestbones",
      "kanagawabones",
      "nordbones",
      "rosebones",
      "seoulbones",
      "tokyobones",
      "randombones_dark",
    },
  },
  {
    group = "RedAlert",
    themes = {
      "apprentice",
      "darc",
      "desert",
      "doubletrouble",
      "elflord",
      "evening",
      "gruvbox",
      "habamax",
      "industry",
      "jellybeans-nvim",
      "koehler",
      "lunaperche",
      "melange",
      "murphy",
      "pablo",
      "retrobox",
      "ron",
      "slate",
      "sorbet",
      "torte",
      "unokai",
      "vim",
      "zaibatsu",
    },
  },
}

local max_group = 0
local max_theme = 0

local function build_theme_index(groups)
  local index = {}
  local order = 0

  for _, entry in ipairs(groups) do
    for _, theme in ipairs(entry.themes) do
      max_group = math.max(max_group, #entry.group)
      max_theme = math.max(max_theme, #theme)
      order = order + 1
      index[theme] = {
        group = entry.group,
        theme = theme,
        order = order,
      }
    end
  end

  return index
end

M.theme_index = build_theme_index(M.theme_groups)

function M.preferred_colorschemes()
  local theme_original = vim.g.colors_name
  local theme_selected
  local was_accepted = false
  local picker_width = max_group + 2 + max_theme + 6

  Snacks.picker.colorschemes({
    title = "Preffered Colorschemes",
    preview = "none",
    sort = { fields = { "order" } },
    matcher = { sort_empty = true },
    layout = {
      preset = "select",
      hidden = { "preview" },
      layout = {
        width = picker_width,
        min_width = picker_width,
      },
    },
    transform = function(item)
      local meta = M.theme_index[item.text]
      if not meta then return false end
      item.group = meta.group
      item.order = meta.order
      item.theme = meta.theme
      item.text = string.format("%s %s", meta.group, item.text)
      return item
    end,
    format = function(item)
      return {
        { string.format("%-10s", item.group .. ":" or ""), "Comment" },
        { item.theme },
      }
    end,
    on_change = function(_, item)
      if not item or not item.text then return end
      theme_selected = item.theme
      vim.schedule(function() pcall(vim.cmd.colorscheme, theme_selected) end)
    end,
    confirm = function(picker, item)
      theme_selected = item.theme
      was_accepted = true
      picker:close()
    end,
    on_close = function()
      vim.schedule(function() pcall(vim.cmd.colorscheme, was_accepted and theme_selected or theme_original) end)
    end,
  })
end

return M
