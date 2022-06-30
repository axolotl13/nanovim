-- Extra
local ok_impatient, impatient = pcall(require, "impatient")
if ok_impatient then impatient.enable_profile() end

-- User Settings
local opt = vim.opt
opt.clipboard = "unnamedplus"
opt.cursorline = true
opt.expandtab = true
opt.fillchars = "eob: "
opt.hidden = true
opt.number = true
opt.mouse = "a"
opt.signcolumn = "yes"
opt.shiftwidth = 2
opt.smartcase = true
opt.smartindent = true
opt.shortmess:append("sI")
opt.wrap = false
opt.termguicolors = true

-- User Keymaps
-- vim.g.mapleader = " "
local extends = { noremap = true, silent = true }
vim.keymap.set("n", "<esc>", "<cmd>noh<cr>", extends, "Not highlight")
-- vim.keymap.set("n", "<tab>", "<cmd>bnext<cr>", extends, "Next buffer")
-- vim.keymap.set("n", "<s-tab>", "<cmd>bprevious<cr>", extends, "Previous buffer")
vim.keymap.set("n", "<c-s>", "<cmd>w!<cr>", extends, "Saved change")
vim.keymap.set("n", "<c-x>", "<cmd>qa!<cr>", extends, "Quit")

-- Plugins
local bootstrap = nil

local install_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"

  if fn.empty(fn.glob(install_path)) > 0 then
    bootstrap = fn.system({
      "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path
    })
  end

  print("Restart nvim")
end

local ok, packer = pcall(require, "packer")
if not ok then
  install_packer()
else
  return packer.startup(function(use)
    -- Plugins Manager
    use "wbthomason/packer.nvim"
    -- Performance
    use "lewis6991/impatient.nvim"
    -- Theme
    use {
      "Mofiqul/adwaita.nvim",
      config = function()
        vim.g.adwaita_darker = true
        vim.cmd([[colorscheme adwaita]])
      end
    }
    -- Treessiter
    use {
      "nvim-treesitter/nvim-treesitter",
      run = ":TSUpdate",
      event = { "BufRead", "BufNewFile" },
      config = function()
        local ok_treesitter, treesitter = pcall(require, "nvim-treesitter.configs")
        if not ok_treesitter then return end

        treesitter.setup({
          -- Popular lenguage
          -- Uncomment to install
          ensure_installed = {
            -- "bash",
            -- "css",
            -- "go",
            -- "html",
            -- "java",
            -- "javascript",
            -- "json",
            "lua", "python"
            -- "rust",
            -- "tsx",
            -- "typescript"
          },
          highlight = { enable = true },
          indent = { enable = true }
        })
      end
    }
    use {
      "neovim/nvim-lspconfig",
      after = "nvim-lsp-installer",
      config = function()
        local ok_lsp, lspconfig = pcall(require, "lspconfig")
        local ok_lspinstall, lspinstall = pcall(require, "nvim-lsp-installer")
        if not ok_lsp and ok_lspinstall then return end

        vim.diagnostic.config({
          virtual_text = true,
          signs = true,
          update_in_insert = true,
          underline = true,
          severity_sort = true
        })

        local signs = {
          Error = "",
          Warn = "",
          Hint = "",
          Info = ""
        }

        for type, icon in pairs(signs) do
          local hl = "DiagnosticSign" .. type
          vim.fn.sign_define(hl, {text = icon, texthl = hl, numhl = hl})
        end

        local on_attach = function(_, bufnr)
          vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

          local bufopts = {extends, buffer = bufnr}
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
          vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, bufopts)
          vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
          vim.keymap.set("n", "<space>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, bufopts)
          vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, bufopts)
          vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, bufopts)
          vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, bufopts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
          vim.keymap.set("n", "<space>f", vim.lsp.buf.formatting, bufopts)
        end

        local capabilities = vim.lsp.protocol.make_client_capabilities()
        local ok_cmp_lsp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
        if ok_cmp_lsp then
          capabilities = cmp_lsp.update_capabilities(capabilities)
        end

        capabilities.textDocument.completion.completionItem = {
          snippetSupport = true
        }

        lspinstall.setup({
          -- Popular Servers
          -- Uncomment to install
          ensure_installed = {
            -- "angularls",
            -- "bashls",
            -- "clangd",
            -- "cssls",
            -- "eslint",
            -- "gopls",
            -- "html",
            -- "jsonls",
            -- "jdtls",
            -- "jedi_language_server",
            "pyright",
            -- "sqlls",
            "sumneko_lua"
            -- "tailwindcss",
            -- "tsserver",
            -- "vuels",
            -- "yamlls"
          },
          automatic_installation = true,
          ui = {
            check_outdated_servers_on_open = true,
            icons = {
              server_installed = "I",
              server_pending = "P",
              server_uninstalled = "U"
            }
          }
        })

        local servers = lspinstall.get_installed_servers()

        local opts = {}
        local extend = vim.tbl_deep_extend

        for _, server in pairs(servers) do
          opts = {
            on_attach = on_attach,
            capabilities = capabilities,
            flags = { debounce_text_changes = 150 }
          }
          if server.name == "sumneko_lua" then
            opts = extend("force", {
              settings = {
                Lua = {
                  runtime = { version = "LuaJIT" },
                  diagnostics = { globals = { "vim" } },
                  workspace = { library = vim.api.nvim_get_runtime_file("", true) },
                  telemetry = { enable = false }
                }
              }
            }, opts)
          end

          lspconfig[server.name].setup(opts)
        end
      end
    }
    use {
      "williamboman/nvim-lsp-installer",
      -- event = {"BufRead", "BufNewFile"}
    }
    -- Autocomplete
    use {
      "hrsh7th/nvim-cmp",
      event = "InsertEnter",
      config = function()
        vim.opt.completeopt = "menuone,noselect"
        vim.opt.pumheight = 15
        local ok_cmp, cmp = pcall(require, "cmp")
        if not ok_cmp then return end

        cmp.setup({
          sources = {
            {name = "nvim_lsp"},
            {name = "buffer"},
            {name = "nvim_lua"},
            {name = "path"}
          },
          mapping = {
            ["<C-p>"] = cmp.mapping.select_prev_item(),
            ["<C-n>"] = cmp.mapping.select_next_item(),
            ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), {"i", "c"}),
            ["<C-e>"] = cmp.mapping {i = cmp.mapping.abort(), c = cmp.mapping.close()},
            ["<CR>"] = cmp.mapping.confirm {behavior = cmp.ConfirmBehavior.Replace, select = true},
            ["<Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              else
                fallback()
              end
            end, {"i", "s"}),
            ["<S-Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              else
                fallback()
              end
            end, {"i", "s"})
          }
        })
      end
    }
    use {"hrsh7th/cmp-nvim-lua", after = "nvim-cmp"}
    use {"hrsh7th/cmp-nvim-lsp", module = "cmp_nvim_lsp"}
    use {"hrsh7th/cmp-buffer", after = "nvim-cmp"}
    use {"hrsh7th/cmp-path", after = "nvim-cmp"}
    -- Comments
    use {
      "numToStr/Comment.nvim",
      keys = {{"n", "gcc"}, {"n", "gbc"}, {"v", "gc"}, {"v", "gb"}},
      config = function()
        local ok_comment, comment = pcall(require, "Comment")
        if not ok_comment then return end

        comment.setup({
          padding = true,
          ignore = "^$",
          mapping = {basic = true, extra = false},
          toggler = {line = "gcc", block = "gbc"}
        })
      end
    }
    -- Autopairs
    use {
      "windwp/nvim-autopairs",
      keys = {{"i", "("}, {"i", "["}, {"i", "{"}, {"i", "'"}, {"i", '"'}},
      config = function()
        local ok_autopairs, autopairs = pcall(require, "nvim-autopairs")
        if not ok_autopairs then return end

        autopairs.setup()
      end
    }
    -- Buffer
    use({
      "ghillb/cybu.nvim",
      branch = "main",
      event = { "BufRead", "BufNewFile" },
      config = function()
        local ok_cybu, cybu = pcall(require, "cybu")
        if not ok_cybu then return end

        cybu.setup()
        vim.keymap.set("n", "<tab>", "<Plug>(CybuPrev)", extends, "Next Buffer")
        vim.keymap.set("n", "<s-tab>", "<Plug>(CybuNext)", extends, "Previous Buffer")
      end,
    })

    if bootstrap then packer.sync() end
  end)
end
