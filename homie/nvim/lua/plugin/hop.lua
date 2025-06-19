local hop = require "hop"
local setkey = vim.keymap.set

local hint_char1 = hop.hint_char1
local hint_char2 = hop.hint_char2
local hint_words = hop.hint_words
local hint_lines_skip_whitespace = hop.hint_lines_skip_whitespace

local HintDirection = require("hop.hint").HintDirection

hop.setup {
  char2_fallback_key = "<CR>",
  jump_on_sole_occurrence = true
}


-- f / F

local FMode = { "o", "x" }

setkey( FMode, "f", function()
  hint_char1 {
    direction = HintDirection.AFTER_CURSOR,
    current_line_only = true
  }
end )

setkey( FMode, "F", function()
  hint_char1 {
    direction = HintDirection.BEFORE_CURSOR,
    current_line_only = true
  }
end )


-- t / T

local TMode = { "o", "x", "n" }

setkey( TMode, "t", function()
  hint_char1 {
    direction = HintDirection.AFTER_CURSOR,
    current_line_only = true,
    hint_offset = -1
  }
end )

setkey( TMode, "T", function()
  hint_char1 {
    direction = HintDirection.BEFORE_CURSOR,
    current_line_only = true,
    hint_offset = 1
  }
end )


-- <Leader><Leader>j/k: up & down on a line basis

setkey( "n", "<Leader><Leader>j", function()
  hint_lines_skip_whitespace {
    direction = HintDirection.AFTER_CURSOR
  }
end )

setkey( "n", "<Leader><Leader>k", function()
  hint_lines_skip_whitespace{
    direction = HintDirection.BEFORE_CURSOR
  }
end )


-- ss: jump anywhere

setkey( "n", "ss", function()
  hint_char2 {
    multi_windows = true
  }
end )
