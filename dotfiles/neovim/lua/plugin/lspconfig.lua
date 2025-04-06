local lspconfig = require "lspconfig"

local servers = {
    nixd = {
        cmd = { "nixd", "--semantic-tokens=false" },
    },
    rust_analyzer = {
        settings = { ["rust-analyzer"] = {
            checkOnSave = { command = "clippy" },
        } },
    },
    rubocop = { single_file_support = true, },
    -- denols = {},
    elixirls = { cmd = { "elixir-ls" }, },
}

for server, config in pairs( servers ) do
    config.on_attach = function ( client, bufnr )
        if server == "nixd" then
            client.server_capabilities.completionProvider = false
        end
    end

    -- extend lsp capabilities
    local has_blink, blink = pcall( require, "blink-cmp" )
    local has_cmp, cmp_lsp = pcall( require, "cmp_nvim_lsp" )

    assert(
        not (has_blink and has_cmp),
        "Don't use cmp and blink at the same time!"
    )

    if has_blink then
        config.capabilities = blink.get_lsp_capabilities( config.capabilities )
        config.capabilities
            .textDocument
            .completion
            .completionItem
            .snippetSupport = false
    end

    if has_cmp then
        config.capabilities = cmp_lsp.default_capabilities()
        config.capabilities
            .textDocument
            .completion
            .completionItem
            .snippetSupport = false
    end

    lspconfig[server].setup( config )
end

vim.api.nvim_create_autocmd( 'LspAttach', {
    callback = function( args )
        local keyopts = { buffer = args.buf, silent = true }
        vim.keymap.set( "n", "D", vim.diagnostic.open_float, keyopts )
        vim.keymap.set( "n", "<F2>", vim.lsp.buf.rename, keyopts )
    end
} )

vim.diagnostic.config {
    update_in_insert = false,
    underline = true,
    virtual_text = false,
    virtual_lines = false,
    severity_sort = true,
    float = { border = "rounded" }
}
