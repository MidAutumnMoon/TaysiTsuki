local fzf = require "fzf-lua"

fzf.setup {
    "skim",
}

for key, action in pairs {
    ["<Leader>z"] = fzf.builtin,
    ["<Leader>f"] = fzf.files,
    ["<Leader>l"] = fzf.blines,
    ["<Leader>d"] = fzf.diagnostics_document,
} do
    vim.keymap.set( "n", key, action, { silent = true } )
end
