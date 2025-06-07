local autopairs = require "nvim-autopairs"

local Rule = require "nvim-autopairs.rule"
local conds = require "nvim-autopairs.conds"

autopairs.setup {
    check_ts = true,
    map_c_w = true,
    enable_check_bracket_line = true,
    enable_bracket_in_quote = false,
}


--
-- Insertion with surrounding check
--
-- Ref: autopairs wiki
--

function builder( open, ins, close )
    local r = Rule( ins, ins )
        :with_pair( function(o)
            return open..close == o.line:sub( o.col - #open, o.col + #close - 1 )
        end )
        :with_move( conds.none() )
        :with_cr( conds.none() )
        :with_del( function(o)
            local col = vim.api.nvim_win_get_cursor(0)[2]
            return open..ins..ins..close == o.line:sub(col - #open - #ins + 1, col + #ins + #close) -- insert only works for #ins == 1 anyway
        end )
    local r2 = Rule( open..ins, ins..close )
        :with_pair( conds.none() )
        :with_move( function(o) return o.char == close end )
        :with_del( conds.none() )
        :use_key( close )
    autopairs.add_rules { r, r2 }
end

builder( "(", " ", ")" )
builder( "<", " ", ">" )
builder( "[", " ", "]" )
builder( "{", " ", "}" )

--
-- Move past commas and semicolons
--
-- Ref: autopairs wiki
--

for _, punct in pairs { ":", ",", ";" } do
    local r = Rule( "", punct )
        :with_move( function(o) return o.char == punct end )
        :with_pair( function() return false end )
        :with_del( function() return false end )
        :with_cr( function() return false end )
        :use_key( punct )
    autopairs.add_rules { r }
end

--
-- <> for generics but not as greater-than/less-than operators
--
-- Ref: autopairs wiki
--

local angle_bracket_ft = {
    "-html",
    "-javascriptreact",
    "-typescriptreact",
}

autopairs.add_rule(
    Rule( '<', '>', angle_bracket_ft )
        :with_pair(
            -- regex will make it so that it will auto-pair on
            -- `a<` but not `a <`
            -- The `:?:?` part makes it also
            -- work on Rust generics like `some_func::<T>()`
            conds.before_regex( "%a+:?:?$", 3 )
        )
        :with_move(function(o) return o.char == ">" end )
)

-- Disable single quote autopair in Rust altogether
vim.iter( autopairs.get_rules "'" )
    :each( function( it )
        it.not_filetypes =
            vim.list_extend( it.not_filetypes or {}, { "rust" } )
        -- print( vim.inspect( it ) )
    end )

-- vim: nowrap:
