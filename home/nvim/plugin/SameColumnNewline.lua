--
-- Create new empty line and insert necessary amount of indentations
-- to preserve cursor's column position.
--

local fn = vim.fn
local cmd = vim.cmd


SameColumnNewline = {}

--
-- direction: "prev" / "next"
--
SameColumnNewline.run = function( direction )
  local line = fn.line('.')

  local col = fn.col('.')
  local virtcol = fn.virtcol('.')

  local realcol = (function()
    if col <= virtcol then
      return virtcol
    else
      return col
    end
  end)()

  local indentations = string.rep( " ", realcol )

  if direction == "prev" then
    fn.append( line - 1, indentations )
    cmd "normal! k"
  elseif direction == "next" then
    fn.append( line + 0, indentations )
    cmd "normal! j"
  else
    -- nothing
  end

  cmd "startinsert"
end
