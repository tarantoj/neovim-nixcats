return {
  {
    'avante.nvim',
    for_cat = 'general.ai',
    cmd = {
      'AvanteAsk',
      'AvanteChat',
      'AvanteEdit',
      'AvanteFocus',
      'AvanteSwitchProvider',
      'AvanteShowRepoMap',
      'AvanteToggle',
    },
    after = function()
      require('avante_lib').load()
      require('avante').setup { provider = 'copilot' }
    end,
  },
  {
    'copilot.lua',
    cmd = 'Copilot',
    after = function()
      require('copilot').setup {}
    end,
    for_cat = 'general.ai',
    dep_of = 'avante.nvim',
  },
  { 'img-clip.nvim', for_cat = 'general.ai', dep_of = 'avante.nvim' },
  {
    'render-markdown-nvim',
    for_cat = 'general.ai',
    dep_of = 'avante.nvim',
  },
  { 'dressing-nvim', for_cat = 'general.ai', dep_of = 'avante.nvim' },
  { 'nui.nvim', for_cat = 'general.ai', dep_of = 'avante.nvim' },
}
