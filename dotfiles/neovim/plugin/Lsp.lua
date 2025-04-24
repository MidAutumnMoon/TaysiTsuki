vim.lsp.config( "elixirls", {
    cmd = { "elixir-ls" },
} )

vim.lsp.config( "rust_analyzer", {
    settings = { ["rust-analyzer"] = {
        checkOnSave = true,
        check = { command = "clippy" },
        hover = {
            show = { traitAssocItems = 2 },
        },
        imports = {
            granularity = { group = "item" },
        },
    }, }
} )

vim.lsp.config( "nixd", {
    on_init = function( client, result )
        client.server_capabilities.completionProvider = false
    end
} )

vim.lsp.enable {
    "denols",
    "rubocop",
    "rust_analyzer",
    "nixd",
}

vim.api.nvim_create_autocmd( 'LspAttach', {
    callback = function( args )
        local keyopts = { buffer = args.buf, silent = true }
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
