-----------------------------------------------------------------------
--         FILE:  xindex-cfg.lua
--  DESCRIPTION:  configuration file for xindex.lua
-- REQUIREMENTS:  
--       AUTHOR:  Herbert Voß
--      LICENSE:  LPPL1.3
--
-- $Id: xindex-dtk.lua 22 2022-02-07 12:18:15Z hvoss $
-----------------------------------------------------------------------

if not modules then modules = { } end modules ['xindex-cfg'] = {
      version = 0.47,
      comment = "DTK configuration to xindex.lua",
       author = "Herbert Voss",
    copyright = "Herbert Voss",
      license = "LPPL 1.3"
}

itemPageDelimiter = ""     -- Hello, 14
compressPages     = true    -- something like 12--15, instead of 12,13,14,15. the |( ... |) syntax is still valid
fCompress	  = true    -- 3f -> page 3, 4 and 3ff -> page 3, 4, 5
minCompress       = 3       -- 14--17 or 
numericPage       = true    -- for non numerical pagenumbers, like "VI-17"
sublabels         = {"-","--","---",""} -- for the sub(sub(sub-items
pageNoPrefixDel   = ""      -- a delimiter for page numbers like "VI-17"  -- not used !!!
rangeSymbol       = "--"
indexOpening      = "" --[[\providecommand*\lettergroupDefault[1]{}
\providecommand*\lettergroup[1]{%
      \par\textbf{#1}\par
      \nopagebreak
  } 
]]
idxnewletter      = "\\textbf"  -- Only valid if -n is not set
envStart          = "\\begin{theindex}"  
envStop           = "\\end{theindex}"


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
    { 'o', 'ó', 'ò', 'ö', 'ô', 'ø', 'œ', 'ø'},
    { 'p' },
    { 'q' },
    { 'r' },
    { 's', 'š', 'ß' },
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

function specialGetPageList(v,hyperpage)
  local Pages = {}
  if v["pages"] then
    table.sort(v["pages"],pageCompare)-- nur nötig, da User manuell eine Zeile einfügen kann
    if specialCompressPageList then
      Pages = specialCompressPageList(v["pages"])
    else
      Pages = compressPageList(v["pages"])
    end
    local pageNo
    if hyperpage then
        if string.find(v["pages"][1]["special"],"hyperindexformat") then
          pageNo = v["pages"][1]["special"].."{"..checkFF(Pages[1]["number"].."}")
        else
          pageNo = "\\hyperpage{"..checkFF(Pages[1]["number"]).."}"
        end
      for i=2,#Pages do
        if string.find(v["pages"][i]["special"],"hyperindexformat") then
          pageNo = pageNo..", "..v["pages"][i]["special"].."{"..checkFF(Pages[i]["number"].."}")
        else
          pageNo = pageNo..", \\hyperpage{"..checkFF(Pages[i]["number"]).."}"
        end
--        Pages[i] = nil
      end
    else
      if args_v then print("getPageList: "..tostring(Pages[1]["special"])..tostring(Pages[1]["number"])) end 
      if (Pages[1]["special"] == nil) or (Pages[1]["number"] == nil) then return ""  end 
      if #Pages == 1 then
        return "\\relax "..Pages[1]["number"].."\\@nil"
      else        
        pageNo = "\\relax "..Pages[1]["number"] 
        for i=2,#Pages do
          if Pages[i]["number"] then
            pageNo = pageNo..", "..Pages[i]["number"]
            Pages[i] = {}
          end
        end
        pageNo = pageNo.."\\@nil" -- add \@nil
      end
      return pageNo
    end
  else
    return ""
  end
end

function specialItemOutput(last, v, hyperpage)
  local lastItems = last
  local currentItems = {}
  local Entry = v["Entry"]
  local name = getItem(Entry,0)
  local address = getItem(Entry,1)
  outFile:write("  \\item "..name..itemPageDelimiter.."\n")
  str = "    \\subitem "..itemPageDelimiter.." "..address..getPageList(v,hyperpage).."\n"
  for i, str0 in ipairs(escape_chars) do       -- undo the escape char setting
    str = str:gsub(str0[2],str0[3])
  end
  outFile:write(str)
  return last
end


