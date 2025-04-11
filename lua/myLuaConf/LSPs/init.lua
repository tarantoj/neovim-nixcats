local catUtils = require('nixCatsUtils')
if catUtils.isNixCats and nixCats('lspDebugMode') then
  vim.lsp.set_log_level('debug')
end
-- this is how to use the lsp handler.
require('lze').load {
  {
    'nvim-lspconfig',
    for_cat = 'general.core',
    -- the on require handler will be needed here if you want to use the
    -- fallback method of getting filetypes if you don't provide any
    on_require = { 'lspconfig' },
    -- define a function to run over all type(plugin.lsp) == table
    -- when their filetype trigger loads them
    lsp = function(plugin)
      -- in this case, just extend some default arguments with the ones provided in the lsp table
      require('lspconfig')[plugin.name].setup(vim.tbl_extend('force', {
        capabilities = require('myLuaConf.LSPs.caps-on_attach').get_capabilities(plugin.name),
        on_attach = require('myLuaConf.LSPs.caps-on_attach').on_attach,
      }, plugin.lsp or {}))
    end,
  },
  {
    'mason.nvim',
    -- only run it when not on nix
    enabled = not catUtils.isNixCats,
    on_plugin = { 'nvim-lspconfig' },
    load = function(name)
      vim.cmd.packadd(name)
      vim.cmd.packadd('mason-lspconfig.nvim')
      require('mason').setup()
      -- auto install will make it install servers when lspconfig is called on them.
      require('mason-lspconfig').setup { automatic_installation = true }
    end,
  },
  {
    -- lazydev makes your lsp way better in your config without needing extra lsp configuration.
    'lazydev.nvim',
    for_cat = 'neonixdev',
    cmd = { 'LazyDev' },
    ft = 'lua',
    after = function(_)
      require('lazydev').setup {
        library = {
          { words = { 'nixCats' }, path = (nixCats.nixCatsPath or '') .. '/lua' },
        },
      }
    end,
  },
  {
    -- name of the lsp
    'lua_ls',
    enabled = nixCats('lua') or nixCats('neonixdev') or false,
    -- provide a table containing filetypes,
    -- and then whatever your functions defined in the function type specs expect.
    -- in our case, it just expects the normal lspconfig setup options,
    -- but with a default on_attach and capabilities
    lsp = {
      -- if you provide the filetypes it doesn't ask lspconfig for the filetypes
      filetypes = { 'lua' },
      settings = {
        Lua = {
          runtime = { version = 'LuaJIT' },
          formatters = {
            ignoreComments = true,
          },
          signatureHelp = { enabled = true },
          diagnostics = {
            globals = { 'nixCats', 'vim' },
            disable = { 'missing-fields' },
          },
          telemetry = { enabled = false },
        },
      },
    },
    -- also these are regular specs and you can use before and after and all the other normal fields
  },
  {
    'gopls',
    for_cat = 'go',
    -- if you don't provide the filetypes it asks lspconfig for them
    lsp = {},
  },
  {
    'rnix',
    -- mason doesn't have nixd
    enabled = not catUtils.isNixCats,
    lsp = {
      filetypes = { 'nix' },
    },
  },
  {
    'nil_ls',
    -- mason doesn't have nixd
    enabled = not catUtils.isNixCats,
    lsp = {
      filetypes = { 'nix' },
    },
  },
  { 'ts_ls', lsp = {} },
  -- { 'tailwindcss', lsp = {} },
  { 'basedpyright', lsp = {} },
  { 'terraformls', lsp = {} },
  { 'tflint', lsp = {} },
  { 'eslint', lsp = {} },
  { 'html', lsp = {} },
  { 'cssls', lsp = {} },
  {
    'jsonls',
    lsp = {
      settings = {
        json = {
          format = { enable = true },
          schemas = require('schemastore').json.schemas(),
          validate = { enable = true },
        },
      },
    },
  },
  { 'dockerls', lsp = {} },
  { 'docker_compose_language_service', lsp = {} },
  { 'taplo', lsp = {} },
  { 'bashls', lsp = {} },
  {
    'yamlls',
    lsp = {
      settings = {
        redhat = { telemetry = { enabled = false } },
        yaml = {
          keyOrdering = false,
          format = { enable = true },
          validate = true,
          schemaStore = {
            -- You must disable built-in schemaStore support if you want to use
            -- this plugin and its advanced options like `ignore`.
            enable = false,
            -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
            url = '',
          },
          schemas = require('schemastore').yaml.schemas(),
        },
      },
    },
  },
  {
    'nixd',
    enabled = catUtils.isNixCats and (nixCats('nix') or nixCats('neonixdev')) or false,
    lsp = {
      filetypes = { 'nix' },
      settings = {
        nixd = {
          -- nixd requires some configuration.
          -- luckily, the nixCats plugin is here to pass whatever we need!
          -- we passed this in via the `extra` table in our packageDefinitions
          -- for additional configuration options, refer to:
          -- https://github.com/nix-community/nixd/blob/main/nixd/docs/configuration.md
          nixpkgs = {
            -- in the extras set of your package definition:
            -- nixdExtras.nixpkgs = ''import ${pkgs.path} {}''
            expr = nixCats.extra('nixdExtras.nixpkgs') or [[import <nixpkgs> {}]],
          },
          options = {
            -- If you integrated with your system flake,
            -- you should use inputs.self as the path to your system flake
            -- that way it will ALWAYS work, regardless
            -- of where your config actually was.
            nixos = {
              -- nixdExtras.nixos_options = ''(builtins.getFlake "path:${builtins.toString inputs.self.outPath}").nixosConfigurations.configname.options''
              expr = nixCats.extra('nixdExtras.nixos_options'),
            },
            -- If you have your config as a separate flake, inputs.self would be referring to the wrong flake.
            -- You can override the correct one into your package definition on import in your main configuration,
            -- or just put an absolute path to where it usually is and accept the impurity.
            ['home-manager'] = {
              -- nixdExtras.home_manager_options = ''(builtins.getFlake "path:${builtins.toString inputs.self.outPath}").homeConfigurations.configname.options''
              expr = nixCats.extra('nixdExtras.home_manager_options'),
            },
          },
          formatting = {
            command = { 'alejandra' },
          },
          diagnostic = {
            suppress = {
              'sema-escaping-with',
            },
          },
        },
      },
    },
  },
  {
    'roslyn-nvim',
    for_cat = 'dotnet',
    -- load = (require("nixCatsUtils").isNixCats and vim.cmd.packadd),
    after = function(plugin)
      require('roslyn').setup {
        exe = 'Microsoft.CodeAnalysis.LanguageServer',
        config = {
          capabilities = require('myLuaConf.LSPs.caps-on_attach').get_capabilities('roslyn'),
          settings = {
            ['csharp|completion'] = {
              ['dotnet_provide_regex_completions'] = true,
              ['dotnet_show_completion_items_from_unimported_namespaces'] = true,
              ['dotnet_show_name_completion_suggestions'] = true,
            },
            ['csharp|highlighting'] = {
              ['dotnet_highlight_related_json_components'] = true,
              ['dotnet_highlight_related_regex_components'] = true,
            },
            -- ['navigation'] = {
            --   ['dotnet_navigate_to_decompiled_sources'] = true,
            -- },
            ['csharp|inlay_hints'] = {
              csharp_enable_inlay_hints_for_implicit_object_creation = true,
              csharp_enable_inlay_hints_for_implicit_variable_types = true,
              csharp_enable_inlay_hints_for_lambda_parameter_types = true,
              csharp_enable_inlay_hints_for_types = true,
              dotnet_enable_inlay_hints_for_indexer_parameters = true,
              dotnet_enable_inlay_hints_for_literal_parameters = true,
              dotnet_enable_inlay_hints_for_object_creation_parameters = true,
              dotnet_enable_inlay_hints_for_other_parameters = true,
              dotnet_enable_inlay_hints_for_parameters = true,
              dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
              dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
              dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
            },
            ['csharp|code_lens'] = { dotnet_enable_tests_code_lens = false },
            ['csharp|background_analysis'] = {
              dotnet_analyzer_diagnostics_scope = 'openFiles',
              dotnet_compiler_diagnostics_scope = 'fullSolution',
            },
          },
        },
      }
    end,
    ft = 'cs',
  },
}
