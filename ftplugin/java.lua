-- ~/.config/nvim/ftplugin/java.lua

local jdtls = require 'jdtls'
local jdtls_runtime_java = '/opt/homebrew/opt/openjdk@21/bin/java'

-- Root directory detection: walks up from the current file
-- looking for common Java project markers.
local root_markers = { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle', 'build.gradle.kts' }
local root_dir = require('jdtls.setup').find_root(root_markers)
if not root_dir then return end

-- Unique workspace per project, so different projects don't
-- clobber each other's jdtls state/cache.
local project_name = vim.fn.fnamemodify(root_dir, ':p:h:t')
local workspace_dir = vim.fn.stdpath 'cache' .. '/jdtls-workspace/' .. project_name

-- Mason install paths
local mason_registry = vim.fn.stdpath 'data' .. '/mason/packages'
local jdtls_path = mason_registry .. '/jdtls'

-- Find the launcher jar and OS-specific config dir
local launcher_jar = vim.fn.glob(jdtls_path .. '/plugins/org.eclipse.equinox.launcher_*.jar')

local os_config
if vim.fn.has 'mac' == 1 then
  os_config = 'config_mac'
elseif vim.fn.has 'unix' == 1 then
  os_config = 'config_linux'
elseif vim.fn.has 'win32' == 1 then
  os_config = 'config_win'
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
if ok_cmp then capabilities = cmp_lsp.default_capabilities(capabilities) end

-- Bundles for debug/test support, if installed
local bundles = {}

local debug_path = mason_registry .. '/java-debug-adapter'
if vim.fn.isdirectory(debug_path) == 1 then
  vim.list_extend(bundles, vim.split(vim.fn.glob(debug_path .. '/extension/server/com.microsoft.java.debug.plugin-*.jar'), '\n'))
end

local test_path = mason_registry .. '/java-test'
if vim.fn.isdirectory(test_path) == 1 then vim.list_extend(bundles, vim.split(vim.fn.glob(test_path .. '/extension/server/*.jar'), '\n')) end
bundles = vim.tbl_filter(function(s) return s ~= '' end, bundles)

local config = {
  cmd = {
    jdtls_runtime_java,
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xmx1g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',
    '-jar',
    launcher_jar,
    '-configuration',
    jdtls_path .. '/' .. os_config,
    '-data',
    workspace_dir,
  },
  root_dir = root_dir,
  capabilities = capabilities,
  settings = {
    java = {
      signatureHelp = { enabled = true },
      completion = {
        favoriteStaticMembers = {
          'org.junit.Assert.*',
          'org.junit.jupiter.api.Assertions.*',
          'java.util.Objects.requireNonNull',
        },
      },
    },
  },
  init_options = {
    bundles = bundles,
  },
  on_attach = function(client, bufnr)
    local opts = { buffer = bufnr, silent = true }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, opts)

    -- nvim-jdtls specific extras
    jdtls.setup_dap { hotcodereplace = 'auto' }
    require('jdtls.dap').setup_dap_main_class_configs()

    vim.keymap.set('n', '<leader>jo', jdtls.organize_imports, opts)
    vim.keymap.set('n', '<leader>jt', jdtls.test_class, opts)
    vim.keymap.set('n', '<leader>jn', jdtls.test_nearest_method, opts)
  end,
}

jdtls.start_or_attach(config)
