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
        -- client.server_capabilities.completionProvider = false
    end,
    settings = { nixd = {
        nixpkgs = { expr = "null" },
        options = {
            nixos = { expr = "null" },
            home_manager = { expr = "null" },
        },
    } }
} )

-- avoid ambiguous syntax
;

(function()
    local lsp_path = vim.fn.exepath( "elixir-ls" )
    if lsp_path ~= "" then
        vim.lsp.config( "elixirls", { cmd = { lsp_path } } )
        vim.lsp.enable { "elixirls" }
    end
end)()

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
        vim.keymap.set( "n", "gd", vim.lsp.buf.definition, keyopts )
        -- disable semantic highlight; it's laggy
        local client = vim.lsp.get_client_by_id( args.data.client_id )
        -- client.server_capabilities.semanticTokensProvider = nil
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
