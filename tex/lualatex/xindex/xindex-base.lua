-----------------------------------------------------------------------
--         FILE:  xindex-base.lua
--  DESCRIPTION:  base file for xindex.lua
-- REQUIREMENTS:  
--       AUTHOR:  Herbert Voß
--      LICENSE:  LPPL1.3
--
-- $Id: xindex-base.lua 22 2022-02-07 12:18:15Z hvoss $
-----------------------------------------------------------------------

local info = { version = 0.47 } 

-- check config
if pageNoPrefixDel ~= "" then 
--  numericPage = false 
   pageNoPrefixPattern = "^.*"..pageNoPrefixDel
end

local lines = {}

if useStdInput then
  writeLog(2,"Read Data from stdin ... \n",0)
  for line in io.lines() do
    lines[#lines+1] = line
  end
  writeLog(2,#lines.." lines of data read\n",0)
else
  for i=1,#inFiles do
    writeLog(2,"Read Data from file "..inFiles[i].." ... \n",0)
    lines = array_concat(lines, read_lines_from(inFiles[i]))
    writeLog(2,#lines.." lines of data read\n",0)
  end
end
print("Anzahl Zeilen: "..#lines)
if #lines == 0 then
    print("=========================================")
    print("Input file(s) is/are empty!")
    print("Leaving program xindex")
    print("=========================================")
    outFile:write("\n")
    outFile:write(envStart.."\n")
    if indexOpening ~= "" then   -- commands after \begin{theindex}
      outFile:write(indexOpening) 
    end
    outFile:write(envStop.."\n")
    outFile:close()
    os.exit()
end

print("Presort of \\indexentry lines")
table.sort(lines)
if vlevel > 1 then 
  print("Pres-Sorted index list:")
  for _,l in pairs(lines) do print (l) end
end


if vlevel > 1 then 
  writeLog(1,"--------------- Input data -----------------\n",2)
  for _,l in pairs(lines) do writeLog(1,l.."\n",2) end
  writeLog(1,"--------------- end Input data -----------------\n",2)
end

local Index = {}  -- Entry = "Seitenzahl(en)"
local pages = {}
local noEntryfound
local noPagefound

hyperpage, lines = checkHyperpage(lines)  -- hyperref used?
if hyperpage then writeLog(1,"We have hyperpages ... \n",1) end

--for _,l in pairs(lines) do print (l) end

writeLog(1,"Change escape chars with macros ... \n",0)
for k,v in ipairs(lines) do  
  if not commandEntry(v) then
    for i, str0 in ipairs(escape_chars) do  -- str0: esc-char, coded, char
--      print(str0[1],str0[2],v)
      v = string.gsub(v,str0[1],str0[2])
--      print("==> "..v)
    end
    if k < #lines then
      if commandEntry(lines[k+1]) then   -- is the next line not a \indexentry ?
        Index = getEntryAndPage(v,lines[k+1],Index)-- read two lines
      else
        Index = getEntryAndPage(v,"",Index)-- current line
      end
    else
      Index = getEntryAndPage(v,"",Index)-- current line
    end
  end
end

writeLog(1,"... done\n",0)
writeLog(1,"------------------ Start list after getEntryAndPage() ------------------------\n,",2) 
printList(Index,2)
writeLog(1,"\n------------------ end list after getEntryAndPage() ------------------------\n",2)
writeLog(2,"Sorting entries: for LARGE idx files it can take some minutes ... \n",0)

if SORTprehook then
  writeLog(2, "PreHook begin\n", 0)
  Index = SORTprehook(Index)
  writeLog(2, "PreHook end\n", 0)
end

writeLog(2, "GenerateSortKeys begin\n", 0)
GenerateSortKeys(Index)
writeLog(2, "GenerateSortKeys end\n", 0)

k = 0
writeLog(2, "Sort begin\n", 0)
table.sort(Index,UTFCompare)
writeLog(2, "Sort end\n", 0)
if SORTposthook then
  writeLog(2, "PostHook begin\n", 0)
  Index = SORTposthook(Index)
  writeLog(2, "PostHook end\n", 0)
end

writeLog(1,"\n------------------ Start list after table.sort(Index,UTFCompare)------------\n",2)
printList(Index,2)
writeLog(1,require 'xindex-pretty'.dump(Index),3)    -- only for internal dump
writeLog(1,"\n------------------ end list after table.sort(Index,UTFCompare)------------\n",2)

writeLog(1,"\n",0)
writeLog(2,"\ncheck for |(...|) \n",0)
writeLog(1,"------------------ Start list before checkParenthesis(Index)------------\n",2)
writeLog(1,require 'xindex-pretty'.dump(Index),3)   -- only for internal dump
--for i=1,#Index do print(Index[i]["Entry"],Index[i]["pages"][1]["number"],Index[i]["pages"][1]["special"]) end

Index = checkParenthesis(Index)

writeLog(1,"\n",0)

--for i=1,#Index do print(Index[i]["Entry"],Index[i]["pages"][1]["number"],Index[i]["pages"][1]["special"]) end
writeLog(1,require 'xindex-pretty'.dump(Index),3)   -- only for internal dump
printList(Index,2)
writeLog(1,"------------------ End list after checkParenthesis(Index) ------------\n",2)
writeLog(2,"done\n",0)


writeLog(2,"Replace @-operator ...\n",0)
writeLog(1,"------------------ Start list before compressEntryList(Index)------------\n",1)
--writeLog(1,require 'xindex-pretty'.dump(Index),3)   -- only for internal dump

local NewIndex = {}
NewIndex = compressEntryList(Index)   -- replaces also foo@bar -> bar

-- for i=1,#NewIndex do print(NewIndex[i]["Entry"],NewIndex[i]["pages"][1]["number"],NewIndex[i]["pages"][1]["special"]) end
--writeLog(1,require 'xindex-pretty'.dump(NewIndex),3)   -- only for internal dump
printList(NewIndex,2)
writeLog(1,"------------------ End list after compressEntryList(Index)------------\n",1)
writeLog(2,"done\n",0)

-- output the .ind-list
--[[
for i, str0 in ipairs(escape_chars) do
  outFile:write("\\def"..str0[2].."{"..str0[3].."}\n")
end
]]   -- no more needed, we redo the setting 

if use_UCA then
  writeLog(2,"Endhook for UCA ...",0)
  for i=1, #NewIndex do
    v = NewIndex[i]
    -- the collator:get_lowest_char will return character on the given
    -- position. It will be lowercase and without accents.
    local codepoints = collator_obj:string_to_codepoints(NormalizedUpper(v.SortKey))
    v.sortChar = getSortChar(codepoints) --or getSortChar(collator_obj:string_to_codepoints(NormalizedUpper(v.Entry)))
    if not v.sortChar then
      -- alternativelly use v.Entry if SortKey doesn't contain usable string
      codepoints = collator_obj:string_to_codepoints(NormalizedUpper(v.Entry))
      v.sortChar = getSortChar(codepoints)
    end
  end
  writeLog(2,"done\n",0)
end

if SORTendhook then
  NewIndex = SORTendhook(NewIndex)
end

outFile:write("\n")
outFile:write(envStart.."\n")

if indexOpening ~= "" then   -- commands after \begin{theindex}
  outFile:write(indexOpening) 
end

local entry
local firstCLine = true
local firstNLine = true
local firstSLine = true
local firstChar
local symbols = true
local numbers = false
local letters = false
local charType
local currentChar
local currentCharType = 0 -- assume Symbol;  1 number; 2 letter
local oldChar = ""
local excl = 0 --  number of ! symbols in one entry 
local lastItems = {"","",""}
indLines = 0
writeLog(2,"Start writing .ind file ... \n",0)
require 'xindex-pretty'.dump(NewIndex)   -- only for internal dump

-- first the special cases for symbols and numbers:

writeLog(1,"---------- Start list to write the ind file --------------\n",1)
writeLog(1,require 'xindex-pretty'.dump(NewIndex),3)   -- only for internal dump

for k=1,#NewIndex do
--  require 'xindex-pretty'.dump(NewIndex[k])   -- only for internal dump
  if NewIndex[k]["Entry"] then
    local v = NewIndex[k]
    writeLog(1," NewIndex[k]: "..v["Entry"].."\n",2)
    writeLog(1,require 'xindex-pretty'.dump(v),3)   -- only for internal dump
    entry = v["Entry"] 
    writeLog(1,"\nBase start: "..entry.."\n",2)
--    local c = utf.sub(v["sortChar"],1,1)
--    if utf8.codepoint(c) < 12288 then -- Japanese starts at hex 3000
--      firstChar = v["sortChar"]
--    else 
    if language == "cs" then   -- Czech language has special char ch
      if utf.sub(v["sortChar"],1,2) == "CH" then
	firstChar = "Ch"
      else
        firstChar = utf.sub(v["sortChar"],1,1)
      end
    else
      firstChar = utf.sub(v["sortChar"],1,1)  -- catch a translatet Ö->OE
    end
--    end
    currentChar = firstChar
    if string.len(firstChar) > 1 then 
      charType = getCharType(utf.sub(firstChar,1,1))
    else
      charType = getCharType(firstChar)
    end
    if charType == 0 then 
      numbers = false 
      symbols = true
      letters = false 
    end
    if charType == 1 then 
      numbers = true 
      symbols = false
      letters = false 
    end
    if charType > 1 then 
      numbers = false 
      symbols = false
      letters = true 
    end
    if symbols then 
      writeLog(1,"We have symbols to print ...\n",3) 
      if firstSLine then
        firstSLine = false
        if not no_headings then
          outFile:write(idxnewletter.."{"..index_header[1].."}")
          indLines = indLines + 1
--          outFile:write("\\par"..idxnewletter.."{"..index_header[1].."}")
          if no_labels then
            outFile:write("\n\\nopagebreak[4]\n")
          else
            if (labelPrefix == "") then
              outFile:write("\\label{xindex-symbols}\n\\nopagebreak[4]\n")
            else
              outFile:write("\\label{"..labelPrefix.."-xindex-symbols}\n\\nopagebreak[4]\n")
            end
          end
        end
      end
      if specialItemOutput then
        lastItems = specialItemOutput(lastItems, v, hyperpage)
      else
        lastItems = itemOutput(lastItems, v, hyperpage)
      end
    else
      writeLog(1,"We have no symbols to print ...\n",3)
    end
    if numbers then 
      writeLog(1,"We have numbers to print ...\n",3)
      if firstNLine then
        firstNLine = false
        outFile:write("\n\\indexspace\n")
        indLines = indLines + 1
        if not no_headings  then
          outFile:write(idxnewletter.."{"..index_header[2].."}")
          indLines = indLines + 1
          if no_labels then
            outFile:write("\n\\nopagebreak[4]\n")
            indLines = indLines + 1
          else
            if (labelPrefix == "") then
              outFile:write("\\label{xindex-numbers}\n\\nopagebreak[4]\n")
            else
              outFile:write("\\label{"..labelPrefix.."-xindex-numbers}\n\\nopagebreak[4]\n")
            end
            indLines = indLines + 1
          end
        end
      end
      if specialItemOutput then
        lastItems = specialItemOutput(lastItems, v, hyperpage)
      else
        lastItems = itemOutput(lastItems, v, hyperpage)
      end
    else
      writeLog(1,"We have no numbers to print ...\n",3)
    end
    if letters then
      writeLog(1,"We have letters to print ...\n",3) 
      if (currentChar ~= oldChar) and (charType == 2) then 
        outFile:write("\n\\indexspace\n")
        indLines = indLines + 1
        if not no_headings then
          outFile:write(idxnewletter.."{"..currentChar.."}")
          indLines = indLines + 1
          if no_labels then
            outFile:write("\n\\nopagebreak[4]\n")
          else
            if (labelPrefix == '""') then
              outFile:write("\\label{xindex-"..currentChar.."}\n\\nopagebreak[4]\n")
            else
              outFile:write("\\label{"..labelPrefix.."-xindex-"..currentChar.."}\n\\nopagebreak[4]\n")
            end
            indLines = indLines + 1
          end
        end  -- not no_headings
        oldChar = currentChar
      end
      if specialItemOutput then
        lastItems = specialItemOutput(lastItems, v, hyperpage)
      else
        lastItems = itemOutput(lastItems, v, hyperpage)
      end
    end
    if v["Macro"]  then outFile:write(v["Macro"].."\n") end
  end
end
outFile:write(envStop.."\n")
writeLog(2,indLines.." lines of data wrote into the "..outfilename.." file\n",0)
outFile:close()

writeLog(2,"\ndone! closing program\n",0)

