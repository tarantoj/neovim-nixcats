local servers = {}
if nixCats('neonixdev') then
  servers.lua_ls = {
    Lua = {
      formatters = {
        ignoreComments = true,
      },
      signatureHelp = { enabled = true },
      diagnostics = {
        globals = { 'nixCats' },
        disable = { 'missing-fields' },
      },
    },
    telemetry = { enabled = false },
    filetypes = { 'lua' },
  }
  if require('nixCatsUtils').isNixCats then
    servers.nixd = {
      nixd = {
        nixpkgs = {
          -- nixd requires some configuration in flake based configs.
          -- luckily, the nixCats plugin is here to pass whatever we need!
          expr = [[import (builtins.getFlake "]] .. nixCats.extra('nixdExtras.nixpkgs') .. [[") { }   ]],
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
    }
    servers.statix = {}
    servers.nil_ls = {}
    -- If you integrated with your system flake,
    -- you should pass inputs.self as nixdExtras.flake-path
    -- that way it will ALWAYS work, regardless
    -- of where your config actually was.
    -- otherwise flake-path could be an absolute path to your system flake, or nil or false
    if nixCats.extra('nixdExtras.flake-path') then
      local flakePath = nixCats.extra('nixdExtras.flake-path')
      servers.nixd.nixd.options = {}
      if nixCats.extra('nixdExtras.systemCFGname') then
        -- (builtins.getFlake "<path_to_system_flake>").nixosConfigurations."<name>".options
        servers.nixd.nixd.options.nixos = {
          expr = [[(builtins.getFlake "]] .. flakePath .. [[").nixosConfigurations."]] .. nixCats.extra(
            'nixdExtras.systemCFGname'
          ) .. [[".options]],
        }
      end
      if nixCats.extra('nixdExtras.homeCFGname') then
        -- (builtins.getFlake "<path_to_system_flake>").homeConfigurations."<name>".options
        servers.nixd.nixd.options['home-manager'] = {
          expr = [[(builtins.getFlake "]] .. flakePath .. [[").homeConfigurations."]] .. nixCats.extra(
            'nixdExtras.homeCFGname'
          ) .. [[".options]],
        }
      end
    end
  else
    servers.rnix = {}
  end
end

if nixCats('go') then
  servers.gopls = {}
end

if nixCats('tf') then
  servers.terraformls = {}
  servers.tflint = {}
end

if nixCats('python') then
  servers.basedpyright = {}
end

if nixCats('js') then
  servers.eslint = {
    workingDirectories = { mode = 'auto' },
    format = true,
    codeActionOnSave = {
      enable = true,
      mode = 'all',
    },
  }

  servers.tailwindcss = {}

  -- servers.ts_ls = {
  --   typescript = {
  --     inlayHints = {
  --       includeInlayParameterNameHints = 'all',
  --       includeInlayFunctionParameterTypeHints = true,
  --       includeInlayVariableTypeHints = true,
  --       includeInlayPropertyDeclarationTypeHints = true,
  --       includeInlayFunctionLikeReturnTypeHints = true,
  --       includeInlayEnumMemberValueHints = true,
  --     },
  --   },
  --   javascript = {
  --     inlayHints = {
  --       includeInlayParameterNameHints = 'all',
  --       includeInlayFunctionParameterTypeHints = true,
  --       includeInlayVariableTypeHints = true,
  --       includeInlayPropertyDeclarationTypeHints = true,
  --       includeInlayFunctionLikeReturnTypeHints = true,
  --       includeInlayEnumMemberValueHints = true,
  --     },
  --   },
  -- }
end

-- This is this flake's version of what kickstarter has set up for mason handlers.
-- This is a convenience function that calls lspconfig on the lsps we downloaded via nix
-- This will not download your lsp. Nix does that.

--  Add any additional override configuration in the following tables. They will be passed to
--  the `settings` field of the server config. You must look up that documentation yourself.
--  All of them are listed in https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
--
--  If you want to override the default filetypes that your language server will attach to you can
--  define the property 'filetypes' to the map in question.
--  You may do the same thing with cmd

-- servers.clangd = {},
-- servers.gopls = {},
-- servers.pyright = {},
-- servers.rust_analyzer = {},
-- servers.tsserver = {},
servers.html = {}
servers.cssls = {}
servers.jsonls = {
  json = {
    format = { enable = true },
    schemas = require('schemastore').json.schemas(),
    validate = { enable = true },
  },
}

servers.dockerls = {}
servers.docker_compose_language_service = {}
servers.taplo = {}

servers.yamlls = {
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
}

servers.bashls = {}

if not require('nixCatsUtils').isNixCats and nixCats('lspDebugMode') then
  vim.lsp.set_log_level('debug')
end
-- If you were to comment out this autocommand
-- and instead pass the on attach function directly to
-- nvim-lspconfig, it would do the same thing.
-- come to think of it, it might be better because then lspconfig doesnt have to be called before lsp attach?
-- but you would still end up triggering on a FileType event anyway, so, it makes little difference.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('nixCats-lsp-attach', { clear = true }),
  callback = function(event)
    require('myLuaConf.LSPs.caps-on_attach').on_attach(vim.lsp.get_client_by_id(event.data.client_id), event.buf)

    local nmap = function(keys, func, desc)
      if desc then
        desc = 'LSP: ' .. desc
      end

      vim.keymap.set('n', keys, func, { buffer = event.buf, desc = desc })
    end

    local client = vim.lsp.get_client_by_id(event.data.client_id)

    if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
      vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
      nmap('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, '[T]oggle Inlay [H]ints')
    end

    if client and client.name == 'eslint' then
      vim.api.nvim_create_autocmd('BufWritePre', {
        buffer = event.buf,
        command = 'EslintFixAll',
      })
    end

    if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup('nixCats-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('nixCats-lsp-highlight', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'nixCats-lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_codeLens) then
      vim.lsp.codelens.refresh()
      vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
        buffer = event.buf,
        callback = vim.lsp.codelens.refresh,
      })
    end
  end,
})

require('lze').load {
  {
    'nvim-lspconfig',
    for_cat = 'general.always',
    event = 'FileType',
    load = (require('nixCatsUtils').isNixCats and vim.cmd.packadd) or function(name)
      vim.cmd.packadd(name)
      vim.cmd.packadd('mason.nvim')
      vim.cmd.packadd('mason-lspconfig.nvim')
    end,
    after = function(plugin)
      if require('nixCatsUtils').isNixCats then
        for server_name, cfg in pairs(servers) do
          require('lspconfig')[server_name].setup {
            capabilities = require('myLuaConf.LSPs.caps-on_attach').get_capabilities(server_name),
            -- this line is interchangeable with the above LspAttach autocommand
            -- on_attach = require('myLuaConf.LSPs.caps-on_attach').on_attach,
            settings = cfg,
            filetypes = (cfg or {}).filetypes,
            cmd = (cfg or {}).cmd,
            root_pattern = (cfg or {}).root_pattern,
          }
        end
      else
        require('mason').setup()
        local mason_lspconfig = require('mason-lspconfig')
        mason_lspconfig.setup {
          ensure_installed = vim.tbl_keys(servers),
        }
        mason_lspconfig.setup_handlers {
          function(server_name)
            require('lspconfig')[server_name].setup {
              capabilities = require('myLuaConf.LSPs.caps-on_attach').get_capabilities(server_name),
              -- this line is interchangeable with the above LspAttach autocommand
              -- on_attach = require('myLuaConf.LSPs.caps-on_attach').on_attach,
              settings = servers[server_name],
              filetypes = (servers[server_name] or {}).filetypes,
            }
          end,
        }
      end
    end,
  },
  {
    'roslyn',
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
  {
    'typescript-tools.nvim',
    for_cat = 'js',
    event = 'DeferredUIEnter',
    after = function(plugin)
      require('typescript-tools').setup {}
    end,
  },
}
