-----------------------------------------------------------------------
--         FILE:  xindex-RU.lua
--  DESCRIPTION:  configuration file for xindex.lua
-- REQUIREMENTS:  
--       AUTHOR:  Alexey Kuznetzov
--      LICENSE:  LPPL1.3
--
-- $Id: xindex-DIN2.lua 13 2021-08-15 10:49:40Z hvoss $
-----------------------------------------------------------------------

if not modules then modules = { } end modules ['xindex-RU'] = {
      version = 0.47,
      comment = "configuration to xindex.lua",
       author = "Alexey Kuznetzov",
    copyright = "Herbert Voß",
      license = "LPPL 1.3"
}



itemPageDelimiter = ","     -- Hello, 14
compressPages     = true    -- something like 12--15, instead of 12,13,14,15. the |( ... |) syntax is still valid
fCompress         = false    -- 3f -> page 3, 4 and 3ff -> page 3, 4, 5
minCompress       = 2       -- 1--3 
rangeSymbol       = "--"
numericPage       = true    -- for non numerical pagenumbers, like "VI-17"
sublabels         = {"", "--- \\-", "--- --- \\-", "--- --- --- \\-"}  -- Russian (sub(sub(sub-items 
pageNoPrefixDel   = ""     -- a delimiter for page numbers like "VI-17"  -- not used !!!
idxnewletter      = "\\textbf"  -- Only valid if -n is not set
envStart          = "\\begin{theindex}"  
indexOpening      = "\\makeatletter\\def\\subitem{\\@idxitem}\\def\\subsubitem{\\@idxitem}\\def\\subsubsubitem{\\@idxitem}\\makeatother" -- Russian (sub(sub(sub-items
envStop           = "\\end{theindex}"

-- indexheader = { ru = {"Символы", "Числа", "russian"}, } -- Russian headers

-- There is no folio abbreviation in Russian
-- folium = { ru = { "" , "" }, } -- Is this correct? 

--[[
    Each character's position in this array-like table determines its 'priority'.
    Several characters in the same slot have the same 'priority'.
]]
alphabet_lower = { --   for sorting
    { ' ' },  -- only for internal tests
    { 'a', 'á', 'à', 'ä', 'â', 'å', 'æ', },
    { 'b' },
    { 'c', 'ç' },
    { 'd' },
    { 'е', 'ё' },
    { 'f' },
    { 'g' },
    { 'h' },
    { 'i', 'í', 'ì', 'î', 'ï' },
    { 'j' },
    { 'k' },
    { 'l' },
    { 'm' },
    { 'n', 'ñ' },
    { 'o', 'ó', 'ò', 'ö', 'ô', 'ø', 'œ', 'ø'},
    { 'p' },
    { 'q' },
    { 'r' },
    { 's', 'š' },
    { 'ss', 'ß' },
    { 't' },
    { 'u', 'ú', 'ù', 'ü' , 'û'},
    { 'v' },
    { 'w' },
    { 'x' },
    { 'y', 'ý', 'ÿ' },
    { 'z', 'ž' }
}
alphabet_upper = { -- for sorting
    { ' ' },
    { 'A', 'Á', 'À', 'Ä', 'Å', 'Æ', 'Â' },
    { 'B' },
    { 'C', 'Ç' },
    { 'D' },
    { 'Е', 'Ё' },
    { 'F' },
    { 'G' },
    { 'H' },
    { 'I', 'Í', 'Ì', 'Ï', 'Î' },
    { 'J' },
    { 'K' },
    { 'L' },
    { 'M' },
    { 'N', 'Ñ' },
    { 'O', 'Ó', 'Ò', 'Ö', 'Ø','Œ', 'Ø', 'Ô'},
    { 'P' },
    { 'Q' },
    { 'R' },
    { 'S', 'Š' },
    { 'T' },
    { 'U', 'Ú', 'Ù', 'Ü', 'Û' },
    { 'V' },
    { 'W' },
    { 'X' },
    { 'Y', 'Ý', 'Ÿ' },
    { 'Z', 'Ž' }
}
