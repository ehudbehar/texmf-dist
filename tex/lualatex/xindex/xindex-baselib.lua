-----------------------------------------------------------------------
--         FILE:  xindex-baselib.lua
--  DESCRIPTION:  baselibrary for xindex.lua
-- REQUIREMENTS:  
--       AUTHOR:  Herbert Voß
--      LICENSE:  LPPL1.3
--
-- $Id: xindex-baselib.lua 22 2022-02-07 12:18:15Z hvoss $
-----------------------------------------------------------------------

if not modules then modules = { } end modules ['xindex-baselib'] = {
      version = 0.47,
      comment = "base library  to xindex.lua",
       author = "Herbert Voss",
    copyright = "Herbert Voss",
      license = "LPPL 1.3"
}

function dofile(filename)
  local file = kpse.find_file(filename) 
  local f = assert(loadfile(file))
  return f()
end

-- see if the file exists
function file_exists(file)
local f = io.open(file, "rb")
if f then f:close() end
return f ~= nil
end

function array_concat(...) 
    local t = {}
    for n = 1,select("#",...) do
        local arg = select(n,...)
        if type(arg)=="table" then
            for _,v in ipairs(arg) do
                t[#t+1] = v
            end
        else
            t[#t+1] = arg
        end
    end
    return t
end

function IntegerOrString(str)
  local x = tonumber(str)
  if x == nil  -- true, if str contains _not_ only digits -> integer 
    then return str
    else return x
  end
end

function getPathFileExt(str)
  local filepath = str:match("(.*[/\\])")
  local filename = str:match("^.+/(.+)$")
  local fileext = str:match("^.+(%..+)$")
  return filepath,filename,fileext
end

local romanMap = { 
    I = 1,
    V = 5,
    X = 10,
    L = 50,
    C = 100, 
    D = 500, 
    M = 1000,
}

local numbers = { 1, 5, 10, 50, 100, 500, 1000 }
local romanchars = { "I", "V", "X", "L", "C", "D", "M" }
local RomanNumerals = { }

function numberToRoman(s)
    --s = tostring(s)
    s = tonumber(s)
    if not s or s ~= s then error"Unable to convert to number" end
    if s == math.huge then error"Unable to convert infinity" end
    s = math.floor(s)
    if s <= 0 then return s end
	local ret = ""
        for i = #numbers, 1, -1 do
        local num = numbers[i]
        while s - num >= 0 and s > 0 do
            ret = ret .. romanchars[i]
            s = s - num
        end
        for j = 1, i - 1 do
            local n2 = numbers[j]
            if s - (num - n2) >= 0 and s < num and s > 0 and num - n2 ~= n2 then
                ret = ret .. romanchars[j] .. romanchars[i]
                s = s - (num - n2)
                break
            end
        end
    end
    return ret
end

function romanToNumber(s)
--  if args_v then print("romanToNumber: "..tostring(s)) end
--  if not s then return end
  s = s:upper()
  local ret = 0
  local i = 1
  while i <= s:len() do
    local c = s:sub(i, i)
    if c ~= " " then -- allow spaces
      local m = romanMap[c] 
      if not m then return nil end           --error("Unknown Roman Numeral '" .. c .. "'")
      local next = s:sub(i + 1, i + 1)
      local nextm = romanMap[next]
      if next and nextm then
        if nextm > m then 
          ret = ret + (nextm - m)
          i = i + 1
        else
          ret = ret + m
        end
      else
        ret = ret + m
      end
    end
      i = i + 1
  end
  return ret
end

function toNumber(s) -- number as string or a roman number to arabic number
  if s == nil then return s end
  if type(s) == "number" then return s end   -- it is already a number
  local rnum = romanToNumber(s)              -- check if roman
  if rnum then return rnum end               -- if yes, return converted roman
  return tonumber(s)                         -- return string to number
end

--[[
function string:split()
   local sep, fields = " ", {}
   local pattern = string.format("([^%s]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end
]]

function string:split(s)
   local D
   if not s then 
     D = '%s'
   else
     D = tostring(s)
   end
   local sep, fields = " ", {}
   local pattern = string.format("([^"..D.."]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end


function shellsort(a)
    local inc = math.ceil( #a / 2 )
    while inc > 0 do
        for i = inc, #a do
            local tmp = a[i]
            local j = i
            while j > inc and not UTFCompare(a[j-inc],tmp) do
                a[j] = a[j-inc]
                j = j - inc
            end
            a[j] = tmp
        end
        inc = math.floor( 0.5 + inc / 2.2 )
    end 
    return a
end
 
function stripLeadingSpaces(str)
  return str:gsub("^%s*(.-)%s*$", "%1")
end


