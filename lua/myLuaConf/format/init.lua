require('lze').load {
  {
    'conform.nvim',
    for_cat = 'format',
    -- cmd = { "" },
    event = 'BufWritePre',
    -- ft = "",
    keys = {
      { '<leader>FF', desc = '[F]ormat [F]ile' },
    },
    -- colorscheme = "",
    after = function(plugin)
      local conform = require('conform')

      local prettier_settings = {
        require_cwd = true,

        cwd = require('conform.util').root_file {
          '.prettierrc',
          '.prettierrc.json',
          '.prettierrc.yml',
          '.prettierrc.yaml',
          '.prettierrc.json5',
          '.prettierrc.js',
          '.prettierrc.cjs',
          '.prettierrc.mjs',
          '.prettierrc.toml',
          'prettier.config.js',
          'prettier.config.cjs',
          'prettier.config.mjs',
        },
      }

      conform.setup {
        formatters_by_ft = {
          -- NOTE: download some formatters in lspsAndRuntimeDeps
          -- and configure them here
          lua = { 'stylua' },
          sql = { 'sqlfluff' },
          -- go = { "gofmt", "golint" },
          -- templ = { "templ" },
          -- Conform will run multiple formatters sequentially
          -- python = { "isort", "black" },
          -- Use a sub-list to run only the first available formatter
          javascript = { 'prettierd' },
          javascriptreact = { 'prettierd' },
          typescriptreact = { 'prettierd' },
          typescript = { 'prettierd' },
          graphql = { 'prettierd' },
          json = { 'prettierd' },
          css = { 'prettierd' },
          nix = { 'alejandra' },
          cs = { 'injected', 'csharpier' },
          -- ['*'] = { 'injected' },
        },
        format_on_save = {
          -- These options will be passed to conform.format()
          timeout_ms = 500,
          lsp_format = 'fallback',
        },
        formatters = {
          prettierd = prettier_settings,
        },
      }

      vim.keymap.set({ 'n', 'v' }, '<leader>FF', function()
        conform.format {
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
        }
      end, { desc = '[F]ormat [F]ile' })
    end,
  },
}
