
local M = {}

local alloc     = require ('minim-alloc')
local cb = require ('minim-callbacks')

alloc.remember('minim-math')

--1 Alphabet tables

--[[ There are gaps left in the unicode math alphabets
--   for characters that were already represented
--   elsewhere. These tables will be used for redirecting
--   characters mapped to these gaps.
--]]

local gaps =
    { [0x1d455] = 0x0210e -- H
    , [0x1d49d] = 0x0212c -- script B
    , [0x1d4a0] = 0x02130 -- script E
    , [0x1d4a1] = 0x02131 -- script F
    , [0x1d4a3] = 0x0210b -- script H
    , [0x1d4a4] = 0x02110 -- script I
    , [0x1d4a7] = 0x02112 -- script L
    , [0x1d4a8] = 0x02133 -- script M
    , [0x1d4ad] = 0x0211b -- script R
    , [0x1d4ba] = 0x0212f -- script e
    , [0x1d4bc] = 0x0210a -- script g
    , [0x1d4c4] = 0x02134 -- script o
    , [0x1d506] = 0x0212d -- fraktur C
    , [0x1d50b] = 0x0210c -- fraktur H
    , [0x1d50c] = 0x02111 -- fraktur I
    , [0x1d515] = 0x0211c -- fraktur R
    , [0x1d51d] = 0x02128 -- fraktur Z
    , [0x1d53a] = 0x02102 -- bb C
    , [0x1d53f] = 0x0210d -- bb H
    , [0x1d545] = 0x02115 -- bb N
    , [0x1d547] = 0x02119 -- bb P
    , [0x1d548] = 0x0211a -- bb Q
    , [0x1d549] = 0x0211d -- bb R
    , [0x1d551] = 0x02124 -- bb Z
    }

-- greek variants have irregular upright values
local varcorr =
    { [0x03f4] = 0x03a2 -- ϴ
    , [0x2207] = 0x03aa -- ∇
    , [0x2202] = 0x03ca -- ∂
    , [0x03f5] = 0x03cb -- ϵ
    , [0x03d1] = 0x03cc -- ϑ
    , [0x03f0] = 0x03cd -- ϰ
    , [0x03d5] = 0x03ce -- ϕ
    , [0x03f1] = 0x03cf -- ϱ
    , [0x03d6] = 0x03d0 -- ϖ
    }

--[[ When transforming to other stylistic variants, we need
--   to know which alphabet a character is in; the transformation
--   offsets differ for each alphabet.
--]]

local function getalphabet (n)
    if     n >= 0x61  and n <= 0x7A  then return 0x61  -- latin
    elseif n >= 0x41  and n <= 0x5A  then return 0x41  -- Latin
    elseif n >= 0x30  and n <= 0x39  then return 0x30  -- digits
    elseif n >= 0x3b1 and n <= 0x3c9 then return 0x3b1 -- greek
    elseif n >= 0x391 and n <= 0x3a9 then return 0x391 -- Greek
    elseif (varcorr[n] or 0xfff) < 0x3c0 then return 0x391 -- varGreek
    elseif (varcorr[n] or 0xfff) < 0x3f0 then return 0x3b1 -- vargreek
    else return 0 -- the character cannot transform
    end
end

--[[ In the offsets table, all transformations can be found for the first 
--   character in the alphabet. The numbers in the table are increments.
--]]

local offsets =
    { [0] = {}
    , [0x61] = -- latin
       { [1] = 0x1d3ed -- it     𝑎 = 0x1d44e
       , [3] = 0x1d421 -- bfit   𝒂 = 0x1d482
       , [4] = 0x1d4f1 -- bb     𝕒 = 0x1d552
       , [2] = 0x1d3b9 -- bf     𝐚 = 0x1d41a
       , [5] = 0x1d4bd -- frak   𝔞 = 0x1d51e
       , [6] = 0x1d525 -- bffrak 𝖆 = 0x1d586
       , [7] = 0x1d455 -- cal    𝒶 = 0x1d4b6
       , [8] = 0x1d489 -- bfcal  𝓪 = 0x1d4ea
       , [9] = 0x1d559 -- sans   𝖺 = 0x1d5ba
       , [10]= 0x1d5c1 -- sfit   𝘢 = 0x1d622
       , [11]= 0x1d58d -- sfbf   𝗮 = 0x1d5ee
       , [12]= 0x1d5f5 -- sfbfit 𝙖 = 0x1d656
       , [13]= 0x1d629 -- mono   𝚊 = 0x1d68a
    }
    , [0x41] = -- Latin
       { [1] = 0x1d3f3 -- it     𝐴 = 0x1d434
       , [3] = 0x1d427 -- bfit   𝑨 = 0x1d468
       , [4] = 0x1d4f7 -- bb     𝔸 = 0x1d538
       , [2] = 0x1d3bf -- bf     𝐀 = 0x1d400
       , [5] = 0x1d4c3 -- frak   𝔄 = 0x1d504
       , [6] = 0x1d52b -- bffrak 𝕬 = 0x1d56c
       , [7] = 0x1d45b -- cal    𝒜 = 0x1d49c
       , [8] = 0x1d48f -- bfcal  𝓐 = 0x1d4d0
       , [9] = 0x1d55f -- sans   𝖠 = 0x1d5a0
       , [10]= 0x1d5c7 -- sfit   𝘈 = 0x1d608
       , [11]= 0x1d593 -- sfbf   𝗔 = 0x1d5d4
       , [12]= 0x1d5fb -- sfbfit 𝘼 = 0x1d63c
       , [13]= 0x1d62f -- mono   𝙰 = 0x1d670
       }
    , [0x30] = -- digits
       { [2] = 0x1d79e -- bf     𝐀 = 0x1d7ce
       , [4] = 0x1d7a8 -- bb     𝔸 = 0x1d7d8
       , [9] = 0x1d7b2 -- sans   𝟬 = 0x1d47e2
       , [11]= 0x1d7bc -- bfsans 𝟬 = 0x1d47ec
       , [13]= 0x1d7c6 -- mono   𝟬 = 0x1d47f7
       }
    , [0x3b1] = -- greek
       { [1] = 0x1d34b -- it     𝛼 = 0x1d6fc
       , [2] = 0x1d311 -- bf     𝛂 = 0x1d6c2
       , [3] = 0x1d385 -- bfit   𝜶 = 0x1d736
       , [11]= 0x1d3bf -- sfbf   𝝖 = 0x1d756
       , [12]= 0x1d3f9 -- sfbfit 𝞪 = 0x1d7aa
       }
    , [0x391] = -- Greek
       { [1] = 0x1d351 -- it     𝛢 = 0x1d6e2
       , [2] = 0x1d317 -- bf     𝚨 = 0x1d6a8
       , [3] = 0x1d38b -- bfit   𝜜 = 0x1d71c
       , [11]= 0x1d3c5 -- sfbf   𝝖 = 0x1d756
       , [12]= 0x1d3ff -- sfbfit 𝞐 = 0x1d790
       }
    }

--[[ The function transform_char() returns a transformed character, or nil if 
--   the character cannot be transformed like that. It is used by the setmap 
--   function (which gives a warning on nil) and by the mlist callback (which 
--   ignores nil).
--]]

local function add_fam(num)
    local _, fam, _ = tex.getmathcodes(num)
    return num, fam
end

local function transform_char(num, style)
    if style == 0 then
        return add_fam(num)
    else
        local base = getalphabet(num)
        local n = offsets[base][style]
        if n == nil then
            return nil, nil
        else
            local res = varcorr[num] or num
            res = gaps[n+res] or n+res
            return add_fam(res)
        end
    end
end

--1 Parsing user input

--[[ We accept the following as argument to our lua-side functions:
--    * An alphabet or class name;
--    * A numerical range of the form [0-9]+@[0-9]+
--    * Ordinary strings
--]]

-- math alphabets like 𝒶𝒷𝒸, 𝔞𝔟𝔠, 𝕒𝕓𝕔, and classes like ord, rel etc.
local alphabets = alloc.saved_table('math:alphabets')

local function add_to_alphabet(num, code)
    alphabets[code] = (alphabets[code] or '') .. string.utfcharacter(num)
end

local function chars_iterator(input)
    local a = alphabets[input]
    if a then
        return string.utfvalues(a)
    else
        local from, to = string.match(input, '^([0-9]+)@([0-9]+)$')
        if from then
            local i, n = tonumber(from) - 1, tonumber(to)
            return function()
                i = i + 1
                if i <= n then return gaps[i] or i end
            end
        else
            return string.utfvalues(input)
        end
    end
end

local function apply_settings(input, fn, ...)
    for char in chars_iterator(input) do
        fn(char, ...)
    end
end

--1 Switching class and family

--[[ Setting class and family information is rather simple: the difficult part 
--   of this package is switching between math alphabets.
--]]

local classes = {}
classes.ord   = 0
classes.op    = 1
classes.bin   = 2
classes.rel   = 3
classes.fence = 3
classes.open  = 4
classes.close = 5
classes.punct = 6
classes.var   = 7

local function setclass(char, class)
    local _, fam , sym = tex.getmathcodes (char)
    tex.setmathcode (char, classes[class] or class, fam, sym)
end

local function setfam(char, fam)
    local class, _, sym = tex.getmathcodes (char)
    tex.setmathcode (char, class, fam, sym)
end

function M.setclass (input, class)
    apply_settings(input, setclass, class)
end

function M.setfam (input, fam)
    apply_settings(input, setfam, fam)
end

--1 Character variants

--[[ The settings of variant characters is not coupled to the style mechanism: 
--   rather, it changes the \Umathcode-s directly. Of course, the variant 
--   characters can transform.
--]]

M.greek_variants =
    { [0x3b5] = 0x3f5 -- ε ϵ
    , [0x398] = 0x3f4 -- Θ ϴ
    , [0x3b8] = 0x3d1 -- θ ϑ
    , [0x3ba] = 0x3f0 -- κ ϰ
    , [0x3c6] = 0x3d5 -- φ ϕ
    , [0x3c1] = 0x3f1 -- ρ ϱ
    , [0x3c0] = 0x3d6 -- π ϖ
    }

function M.usevariant (char)
    for num in string.utfvalues (char) do
        local class, fam, _ = tex.getmathcodes(num)
        tex.setmathcode (num, class, fam, M.greek_variants[num] or num)
    end
end

function M.usedefault (char)
    for num in string.utfvalues (char) do
        local class, fam, _ = tex.getmathcodes(num)
        tex.setmathcode (num, class, fam, num)
    end
end

--1 Styles

--[[ The style table gives a numerical value to every math style. The value 
--   `clear' unsets the style attribute.
--]]

local styles  = {}
styles.clear  = alloc.unset
styles.up     = 0
styles.rm     = 0
styles.it     = 1
styles.mit    = 1
styles.bf     = 2
styles.bfit   = 3
styles.bb     = 4
styles.frak   = 5
styles.bffrak = 6
styles.cal    = 7
styles.scr    = 7
styles.script = 7
styles.bfcal  = 8
styles.bfscr  = 8
styles.sf     = 9
styles.sans   = 9
styles.sfit   = 10
styles.sfbf   = 11
styles.sfbfit = 12
styles.mono   = 13
styles.tt     = 13

local style_attribute = alloc.new_attribute ('math style attribute')

function M.setstyle (style)
    tex.setattribute (style_attribute, styles[style])
end

--1 Switching alphabets

--[[ Which glyph a variable character should transform to is determined by 
--   a tex \count register. This ensures that changes to the math style respect 
--   grouping.
--   
--   On the lua side, we keep track of these counts in a table (it is filled 
--   from the tex side).
--]]

local transformcodes = alloc.saved_table ('math:transformcodes')

-- set a character as transformable
local function set_transform (num, char)
    local c = alloc.new_count ('math transform '..char)
    transformcodes[num] = c
    tex.setcount ('global', c, num)
end

-- query the destination
local function dest_char (num)
    local c = transformcodes[num]
    if c == nil then
        return num, nil
    else
        return add_fam(tex.count[c])
    end
end

-- set the destination
local function setmap (char, style)
    local target = transform_char (char, styles[style])
    if target == nil then
        texio.write_nl ('! minim warning: style '..style..' not available for char '..char..'.')
    else
        tex.count[transformcodes[char]] = target
    end
end

function M.setmap(input, style)
    apply_settings(input, setmap, style)
end

--[[ To allow saving and restoring math style settings, the following function 
--   is a dump of \count and \Umathcode values.
--]]

function M.save_mathstyles ()
    for _,v in pairs(transformcodes) do
        tex.sprint('\\count'..v..'='..tex.count[v]..'\\relax')
    end
    for v,_ in pairs(M.greek_variants) do
        local a,b,c = tex.getmathcodes(v)
        tex.sprint('\\Umathcode'..v..'='..a..' '..b..' '..c..'\\relax')
    end
end

--1 The transformation callback

--[[ The stilistic mappings are done in the mlist_to_mlist callback. The 
--   function noad_iterator returns an iterator over the noad list; all 
--   math_char nodes are inspected.
--
--   The listmathfields table contains all noad fields that can contain another 
--   list of noads.
--]]

local listmathfields = { 'head', 'nucleus', 'sub', 'sup', 'accent',
    'bot_accent', 'display', 'text', 'script', 'scriptscript', 'num', 'denom',
    'degree', 'next' } -- note that ‘next’ should be last!

local function noad_iterator (head)
    local nodelist = { link=nil, content=head }
    return function ()
        if nodelist == nil then return nil end
        local n = nodelist.content
        nodelist = nodelist.link
        for _,f in pairs(listmathfields) do
            if node.has_field (n, f) and n[f] ~= nil then
                nodelist = { link=nodelist, content=n[f] }
            end
        end
        return n
    end
end

local math_char = node.id ('math_char')

local function inspect_noads (h, _, _)
    for nd in noad_iterator (h) do
        if nd.id == math_char then
            local sa = node.has_attribute(nd, style_attribute)
            local char, fam
            if sa then
                char, fam = transform_char(nd.char, sa)
            else
                char, fam = dest_char(nd.char)
            end
            nd.char, nd.fam = char or nd.char, fam or nd.fam
        end
    end
    -- if we would not use minim-callbacks, we would have to call
    -- node.mlist_to_hlist (h,d,n) here
    return true
end

cb.register ('mlist_to_mlist', inspect_noads)

--1 Reading the math character table

--[[ The following are used for processing the character table. Control 
--   sequences are defined from the lua side; for accents and radicals this 
--   means using tex-side helper macros.
--
--   When using the add_mathchar function with accents or radicals, please keep 
--   in mind that it assumes \catcode`\:=11.
--]]

local default_fam = 0

local accents =
  { accent = 'accent{}'
  , botaccent = 'accent{bottom}'
  , overlay = 'accent{overlay}'
  , over = 'stack{}'
  , under = 'stack{bottom}'
  }
local is_delimiter =
  { fence = true
  , open = true
  , close = true
  }

local function tex_accent(class, num, char)
    return '\\math:'..accents[class]..'{'..num..'}'..char
end

local function add_mathchar(code, char, class, cs, alphabet)
    if char:sub(0,1) == ' ' then
        -- accents can be given above a space (compare ' ́' with '́')
        char = char:sub(2)
    end
    local class_nr = classes[class]
    if class_nr then
        tex.setmathcode(code, class_nr, default_fam, code)
        if cs then token.set_macro(cs, char) end
        if class_nr == 7 then set_transform(code, char) end
        if is_delimiter[class] then tex.setdelcode(code, default_fam, code, 0, 0) end
    elseif class == 'radical' then
        if cs then
            token.set_macro(cs, '\\math:radical{'..code..'}'..char)
            tex.print('\\mathlet\\'..char..'\\'..cs)
        end
    else
        -- TODO: in the future, allow accent characters by re-ordering them
        tex.setmathcode(code, 0, default_fam, 0) -- provisional
        if cs then token.set_macro(cs, tex_accent(class, code, char)) end
    end
    add_to_alphabet(code, class)
    if alphabet then
        add_to_alphabet(code, alphabet)
    end
end

function M.add_mathchar(t)
    add_mathchar(t.code, t.char, t.class, t.cs, t.alphabet)
end

--1 Tex-side user interface

alloc.luadef('math:mathcls', function() M.setclass(token.scan_string(), token.scan_string()) end)
alloc.luadef('math:mathfam', function() M.setfam(token.scan_string(), token.scan_string()) end)
alloc.luadef('math:mathmap', function() M.setmap(token.scan_string(), token.scan_string()) end)

alloc.luadef('usemathvariant', function() M.usevariant(token.scan_string()) end, 'protected')
alloc.luadef('usemathdefault', function() M.usedefault(token.scan_string()) end, 'protected')
alloc.luadef('mathstyle', function() M.setstyle(token.scan_string()) end, 'protected')

--

return M

