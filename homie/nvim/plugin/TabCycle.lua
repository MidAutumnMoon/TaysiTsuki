local ft_skip = {
    "neo-tree",
}

local function skipping()
    return vim.tbl_contains( ft_skip, vim.bo[0].filetype )
end

local keycmds = {
    ["<Tab>"] = "wincmd w",
    ["<S-Tab>"] = "wincmd W",
}

for key, cmd in pairs( keycmds ) do
    vim.keymap.set( "n", key, function()
        repeat
            vim.cmd( cmd )
        until not skipping()
    end )
end
