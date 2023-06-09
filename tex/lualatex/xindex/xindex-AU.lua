-----------------------------------------------------------------------
--         FILE:  xindex-AU.lua
--  DESCRIPTION:  configuration file for xindex.lua
-- REQUIREMENTS:  
--       AUTHOR:  Herbert Voß
--      LICENSE:  LPPL1.3
--
-- $Id: xindex-DIN2.lua 13 2021-08-15 10:49:40Z hvoss $
-----------------------------------------------------------------------

if not modules then modules = { } end modules ['xindex-AU'] = {
      version = 0.47,
      comment = "configuration to xindex.lua",
       author = "Herbert Voss",
    copyright = "Herbert Voss",
      license = "LPPL 1.3"
}

itemPageDelimiter = ","     -- Hello, 14
compressPages     = true    -- something like 12--15, instead of 12,13,14,15. the |( ... |) syntax is still valid
fCompress	  = true    -- 3f -> page 3, 4 and 3ff -> page 3, 4, 5
minCompress       = 3       -- 14--17 or 
numericPage       = true    -- for non numerical pagenumbers, like "VI-17"
sublabels         = {"", "-\\,", "--\\,", "---\\,"} -- for the (sub(sub(sub-items  first one is for item
pageNoPrefixDel   = ""     -- a delimiter for page numbers like "VI-17"
indexOpening      = ""     -- commands after \begin{theindex}
rangeSymbol       = "--"
idxnewletter      = "\\textbf"  -- Only valid if -n is not set
envStart          = "\\begin{theindex}"  
envStop           = "\\end{theindex}"


--[[
    Each character's position in this array-like table determines its 'priority'.
    Several characters in the same slot have the same 'priority'.
]]

alphabet_lower = { --   for sorting
    { ' ' },  -- only for internal tests
    { 'a', 'á', 'à', 'å', 'æ', },
    { 'ä'},
    { 'b' },
    { 'c', 'ç' },
    { 'd' },
    { 'e', 'é', 'è', 'ë', 'ê' },
    { 'f' },
    { 'g' },
    { 'h' },
    { 'i', 'í', 'ì', 'î', 'ï' },
    { 'j' },
    { 'k' },
    { 'l' },
    { 'm' },
    { 'n', 'ñ' },
    { 'o', 'ó', 'ò', 'ô', 'ø', 'œ', 'ø'},
    { 'ö' },
    { 'p' },
    { 'q' },
    { 'r' },
    { 's', 'š' },
    { 'ss'},
    { 'ß' },
    { 't' },
    { 'u', 'ú', 'ù', 'û'},
    { 'ü' },
    { 'v' },
    { 'w' },
    { 'x' },
    { 'y', 'ý', 'ÿ' },
    { 'z', 'ž' }
}
alphabet_upper = { -- for sorting
    { ' ' },
    { 'A', 'Á', 'À', 'Å', 'Æ', 'Â'},
    { 'Ä'},
    { 'B' },
    { 'C', 'Ç' },
    { 'D' },
    { 'E', 'È', 'É', 'Ë', 'Ê' },
    { 'F' },
    { 'G' },
    { 'H' },
    { 'I', 'Í', 'Ì', 'Ï', 'Î' },
    { 'J' },
    { 'K' },
    { 'L' },
    { 'M' },
    { 'N', 'Ñ' },
    { 'O', 'Ó', 'Ò', 'Ø','Œ', 'Ø', 'Ô' },
    { 'Ö' },
    { 'P' },
    { 'Q' },
    { 'R' },
    { 'S', 'Š' },
    { 'T' },
    { 'U', 'Ú', 'Ù', 'Û' },
    { 'Ü' },
    { 'V' },
    { 'W' },
    { 'X' },
    { 'Y', 'Ý', 'Ÿ' },
    { 'Z', 'Ž' }
}

