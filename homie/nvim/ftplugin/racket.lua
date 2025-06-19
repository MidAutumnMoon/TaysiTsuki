vim.opt_local.lispwords:append {
  'define/contract',
}

-- Pairing is handled by parinfer-rust
local has_ap, autopairs = pcall( require, "nvim-autopairs" )

if has_ap then
    autopairs.disable()
end

-- opt.tabstop = 2
-- opt.softtabstop = 2
-- opt.virtualedit = "all"
--
-- local setkey = vim.keymap.set
--
-- setkey( "n", "o", "", {
--   silent = true,
--   callback = function()
--     SameColumnNewline.run( "next" )
--   end
-- } )
--
-- setkey( "n", "O", "", {
--   silent = true,
--   callback = function()
--     SameColumnNewline.run( "prev" )
--   end
-- } )
