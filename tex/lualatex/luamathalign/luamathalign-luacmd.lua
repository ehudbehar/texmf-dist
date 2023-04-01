----Copyright (C) 2019--2022 by Marcel Krueger
---
--- This file may be distributed and/or modified under the
--- conditions of the LaTeX Project Public License, either
--- version 1.3c of this license or (at your option) any later
--- version. The latest version of this license is in:
---
--- http://www.latex-project.org/lppl.txt
---
--- and version 1.3 or later is part of all distributions of
--- LaTeX version 2005/12/01 or later.
local func_tbl = lua.get_functions_table()
local set_lua = token.set_lua
local new_luafunction = luatexbase.new_luafunction
return function(name, func, ...)
  local idx = new_luafunction(name)
  set_lua(name, idx, ...)
  func_tbl[idx] = func
end
