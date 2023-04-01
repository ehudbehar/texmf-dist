-- Copyright (c) 2022 Thomas Kelkel kelkel@emaileon.de

-- This file may be distributed and/or modified under the
-- conditions of the LaTeX Project Public License, either
-- version 1.3c of this license or (at your option) any later
-- version. The latest version of this license is in

--    http://www.latex-project.org/lppl.txt

-- and version 1.3c or later is part of all distributions of
-- LaTeX version 2009/09/24 or later.

-- Version: 0.1b

-- The ligtype package makes use of the German language
-- ligature suppression rules of the selnolig package by
-- Mico Loretan. The selnolig package can be downloaded at

--    https://www.ctan.org/pkg/selnolig

-- and may be distributed and/or modified under the
-- conditions of the LaTeX Project Public License.

local ID = node.id
local GLYPH = ID ( "glyph" )
local DISC = ID ( "disc" )
local GLUE = ID ( "glue" )
local KERN = ID ( "kern" )
local WI = ID ( "whatsit" )
local BOUND = ID ( "boundary" )
local HLIST = ID ( "hlist" )
local VLIST = ID ( "vlist" )
local USERKERN = table.swapped ( node.subtypes ("kern") )["userkern"]
local NEW = node.new
local REM = node.remove
local PREV = node.prev
local NEXT = node.next
local TAIL = node.tail
local HAS_GLYPH = node.has_glyph
local INS_B = node.insert_before
local INS_A = node.insert_after
local T = node.traverse
local T_GLYPH = node.traverse_glyph
local WIS = node.whatsits()
local userdefined
local pdfliteral
local pairs = pairs
local next = next
local type = type
local U = unicode.utf8
local CHAR = U.char
local GSUB = U.gsub
local SUB = U.sub
local LEN = U.len
local BYTE = U.byte
local FIND = U.find
local T_INS = table.insert
local T_CC = table.concat
local FLOOR = math.floor
local GET_FONT = font.getfont
local ATC = luatexbase.add_to_callback
local RFC = luatexbase.remove_from_callback

local make_marks = false
local no_short_f = false
local all_short_f = false
local no_default = false
local lig_table = {}

for key, value in pairs ( WIS ) do
    if value == "user_defined" then
        userdefined = key
    elseif value == "pdf_literal" then
        pdfliteral = key
    end
end

function ligtype_no_short_f ()
    no_short_f = true
end

function ligtype_all_short_f ()
    all_short_f = true
end

function ligtype_no_default ()
    no_default = true
end

local function to_ascii ( text )
    return GSUB ( text, "[äöüß]", "a" )
end

function ligtype_parse_macro ( text, marker, nolig )
    local text_ascii = to_ascii ( text )
    local marker_ascii = to_ascii ( marker )
    local pos = { nil, nil, nil, nil, nil }
    pos[1] = nolig
    local m_pos = FIND ( marker_ascii, "|" )
    pos[2] = SUB ( marker, m_pos - 1, m_pos - 1 ) .. SUB ( marker, m_pos + 1, m_pos + 1 )
    pos[3] = m_pos - 1
    pos[4] = m_pos
    if FIND ( text_ascii, "[%[]" ) then
        local plus_start = FIND ( text_ascii, "[%[]" ) + 1
        local plus_end = FIND ( text_ascii, "[%]]" ) - 1
        pos[6] = SUB ( text, plus_start, plus_end )
        text = SUB ( text, 1, plus_start - 2 ) .. "+"
    end
    pos[5] = text
    lig_table[#lig_table + 1] = pos
end

local function round ( num, dec )
    return FLOOR ( num * 10^dec + 0.5 ) / 10^dec
end

local function calc_value ( value )
    value = round ( value / 65536, 3 )
    return value
end

local function get_char_bytes ( text, text_len, reverse )
    local a = { nil, nil, nil, nil, nil }
    for i = 1, text_len do
        if reverse then
            a[text_len - i + 1] = BYTE ( text, i )
        else
            a[i] = BYTE ( text, i )
        end
    end
    return a
end

local function find_glyph ( n, d, replace )
    if d ( n ) then
        n = d ( n )
            while n.id ~= GLYPH do
                if not d ( n ) or n.id == GLUE or n.id == BOUND or ( n.id == KERN and n.subtype == USERKERN ) then replace = false break end
                n = d ( n )
            end
    else
        replace = false
    end
    return n, replace
end

local function get_ligs ( head )
    local lig_check = { ["ff"] = true, ["fi"] = true, ["fl"] = true, ["ffi"] = true, ["ffl"] = true, ["ft"] = true, ["fft"] = true, ["fb"] = true, ["ffb"] = true, ["fh"] = true, ["ffh"] = true, ["fk"] = true, ["ffk"] = true, ["fj"] = true, ["ffj"] = true, ["fff"] = true }
    local ligs = { ["ff"] = { nil, nil, nil, nil, nil }, ["fi"] = { nil, nil, nil, nil, nil }, ["fl"] = { nil, nil, nil, nil, nil }, ["ffi"] = { nil, nil, nil, nil, nil }, ["ffl"] = { nil, nil, nil, nil, nil }, ["ft"] = { nil, nil, nil, nil, nil }, ["fk"] = { nil, nil, nil, nil, nil }, ["fj"] = { nil, nil, nil, nil, nil }, ["fft"] = { nil, nil, nil, nil, nil }, ["fb"] = { nil, nil, nil, nil, nil }, ["ffb"] = { nil, nil, nil, nil, nil }, ["fh"] = { nil, nil, nil, nil, nil }, ["ffh"] = { nil, nil, nil, nil, nil }, ["ffk"] = { nil, nil, nil, nil, nil }, ["ffj"] = { nil, nil, nil, nil, nil }, ["fff"] = { nil, nil, nil, nil, nil } }
    for _, value in pairs ( lig_table ) do
        lig_check[value[2]] = true
        ligs[value[2]] = { nil, nil, nil, nil, nil }
    end
    local char_table = {}
    for key, _ in pairs ( lig_check ) do
        char_table[BYTE ( SUB ( key, 1, 1 ) )] = true
    end
    for n in T_GLYPH ( head ) do
        if n.char and char_table[n.char] then
            if NEXT ( n ) then
                local next_chars = { false, false }
                local second_glyph
                local success
                local next_glyph = n
                for i = 1, 2 do
                    next_glyph, success = find_glyph ( next_glyph, NEXT, true )
                    if success and next_glyph.char then
                        next_chars[i] = next_glyph.char
                        if i == 1 then
                            second_glyph = next_glyph
                        end
                    end
                end
                if next_chars[1] and next_chars[2] and lig_check[CHAR ( n.char ) .. CHAR ( next_chars[1] ) .. CHAR ( next_chars[2] )] then
                    local threestring = "ff" .. CHAR ( next_chars[2] )
                    T_INS ( ligs[threestring], next_glyph )
                end
                if next_chars[1] and lig_check[CHAR ( n.char ) .. CHAR ( next_chars[1] )] then
                    local ligstring = CHAR ( n.char ) .. CHAR ( next_chars[1] )
                    T_INS ( ligs[ligstring], second_glyph )
                end
            end
        end
    end
    return ligs
end

local function check_text ( replace, n, d, string_len, string_chars, plus_boolean )
    if d ( n ) then
        local MOVE = d ( n )
        for i = 1, string_len do
            while MOVE.id ~= GLYPH do
                if not d ( MOVE ) or MOVE.id == GLUE or MOVE.id == BOUND or ( MOVE.id == KERN and MOVE.subtype == USERKERN ) then replace = false break end
                MOVE = d ( MOVE )
            end
            if ( MOVE.char ~= string_chars[i] and string_chars[i] ~= 43 ) or ( string_chars[i] == 43 and not plus_boolean[MOVE.char] ) then replace = false break end
            if d ( MOVE ) then
                MOVE = d ( MOVE )
            elseif i ~= string_len then replace = false break end
        end
    else
        replace = false
    end
    return replace
end

local function no_lig ( nolig, lig, lig_beg, lig_end, text, head, ligs, plus )
    local chars = { lig = { nil, nil, nil }, before = { nil, nil, nil, nil, nil }, after = { nil, nil, nil, nil, nil }, plus = { nil, nil, nil, nil, nil, nil, nil, nil, nil } }
    local before_lig
    local after_lig
    local count = 0
    local text_len = LEN ( text )
    local before_lig_len = lig_beg - 1
    local after_lig_len = text_len - lig_end
    chars.lig = get_char_bytes ( lig, 2, false )
    if lig_beg > 1 then
        before_lig = SUB ( text, 1, before_lig_len )
        chars.before = get_char_bytes ( before_lig, before_lig_len, true )
    end
    if lig_end < text_len then
        after_lig = SUB ( text, (lig_end + 1), text_len )
        chars.after = get_char_bytes ( after_lig, after_lig_len, false )
    end
    local plus_boolean = { nil, nil, nil, nil, nil, nil, nil, nil, nil }
    if plus then
        chars.plus = get_char_bytes ( plus, LEN ( plus ), false )
        for _, value in pairs ( chars.plus ) do
            if not ( value == nil ) then
                plus_boolean[value] = true
            end
        end
    end
    for _, value in pairs ( ligs ) do
        count = count + 1
        local n
        if value.char ~= chars.lig[2] then
            local BEFORE = value
            BEFORE = find_glyph ( BEFORE, PREV, true )
            n = BEFORE
        else
            n = value
        end
        if n.char == chars.lig[2] then
            local replace = true
            local prev_glyph = n
            prev_glyph, replace = find_glyph ( prev_glyph, PREV, replace )
            if NEXT ( prev_glyph ) and NEXT ( prev_glyph ).user_id and NEXT ( prev_glyph ).user_id == 289473 and nolig then
                replace = false
            end
            if prev_glyph.char ~= chars.lig[1] then
                replace = false
            end
            if replace then
                if lig_beg > 1 then
                    replace = check_text ( replace, prev_glyph, PREV, before_lig_len, chars.before, plus_boolean )
                end
                if lig_end < text_len then
                    replace = check_text ( replace, n, NEXT, after_lig_len, chars.after, plus_boolean )
                end
                if replace then
                    if nolig then
                        INS_A ( head, prev_glyph, NEW ( WI, userdefined ) )
                        NEXT ( prev_glyph ).type = 100
                        NEXT ( prev_glyph ).user_id = 289473
                    else
                        if NEXT ( prev_glyph ) and NEXT ( prev_glyph ).user_id == 289473 then
                            REM ( head, NEXT ( prev_glyph ) )
                        end
                    end
                end
            end
        end
    end
end

local function find_disc ( n, d )
    local disc_node = nil
    while n.id ~= GLYPH do
        if d ( n ) then
            n = d ( n )
        else break end
        if n.id == DISC then
            disc_node = n
        break end
    end
    return disc_node
end

local function find_prev_next_glyph ( n, d )
    local some_node = d ( n )
    local lig_post = nil
    while some_node.id ~= GLYPH do
        if some_node.id == DISC and some_node.replace and HAS_GLYPH ( some_node.replace ) then
            for glyph_node in T_GLYPH ( some_node.replace ) do
                some_node = glyph_node
            end
            if d == PREV then
                for glyph_node in T_GLYPH ( some_node.post ) do
                    lig_post = glyph_node
                end
            end
        break end
        some_node = d ( some_node )
    end
    return some_node, lig_post
end

local function make_kern ( head )
    local glyph_count = 0
    for n in T_GLYPH ( head ) do
        glyph_count = glyph_count + 1
        if glyph_count > 4 then break end
    end
    if glyph_count > 4 then
        for n in T ( head ) do
            if n.id == WI and n.user_id == 289473 then
                local font_kern = true
                local hyphen_font_kern = true
                local post_lig_font_kern = true
                local prev_glyph, lig_post = find_prev_next_glyph ( n, PREV )
                local next_glyph = find_prev_next_glyph ( n, NEXT )
                local kern_value = 0
                local kern_add = 0
                local hyphen_kern = 0
                local post_lig_kern = 0
                if prev_glyph.font then
                    local tfmdata = GET_FONT ( prev_glyph.font )
                    if tfmdata.resources then
                        local resources = tfmdata.resources
                        if not no_short_f and resources.unicodes then
                            local uni = resources.unicodes
                            local ff = nil
                            local ff_short = nil
                            local f_short = nil
                            for key, value in pairs ( uni ) do
                                if key == "f_f" or key == "uniFB00" then
                                    ff = value
                                elseif key == "f_f.short" or key == "f_f.alt" then
                                    ff_short = value
                                elseif key == "f.short" or key == "f.alt" then
                                    f_short = value
                                end
                            end
                            if ( prev_glyph.char == 102 ) and f_short then
                                prev_glyph.char = f_short
                            elseif ( prev_glyph.char == ff ) and ff_short then
                                prev_glyph.char = ff_short
                            end
                        end
                        if resources.sequences then
                            local seq = resources.sequences
                            for _, t in pairs ( seq ) do
                                if t.steps then
                                    local steps = t.steps
                                    for _, k in pairs ( steps ) do
                                        if k.coverage and ( k.coverage[prev_glyph.char] or ( lig_post and k.coverage[lig_post.char] ) ) then
                                            if k.coverage[prev_glyph.char] then
                                                local glyph_table = k.coverage[prev_glyph.char]
                                                if type ( glyph_table ) == "table" then
                                                    for key, value in pairs ( glyph_table ) do
                                                        if ( key == next_glyph.char or key == 45 ) and type ( value ) == "number" and ( k.format == "move" or tfmdata.specification.features.raw[t.name] ) then
                                                            if font_kern and key == next_glyph.char then
                                                                kern_value = kern_value + ( value / tfmdata.units_per_em * tfmdata.size )
                                                                if tfmdata.specification.features.raw[t.name] then
                                                                    font_kern = false
                                                                end
                                                            elseif hyphen_font_kern and key == 45 then
                                                                hyphen_kern = hyphen_kern + ( value / tfmdata.units_per_em * tfmdata.size )
                                                                if tfmdata.specification.features.raw[t.name] then
                                                                    hyphen_font_kern = false
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                            if lig_post and k.coverage[lig_post.char] then
                                                local glyph_table = k.coverage[lig_post.char]
                                                if type ( glyph_table ) == "table" then
                                                    for key, value in pairs ( glyph_table ) do
                                                        if ( key == next_glyph.char ) and type ( value ) == "number" and ( k.format == "move" or tfmdata.specification.features.raw[t.name] ) then
                                                            if post_lig_font_kern and key == next_glyph.char then
                                                                post_lig_kern = post_lig_kern + ( value / tfmdata.units_per_em * tfmdata.size )
                                                                if tfmdata.specification.features.raw[t.name] then
                                                                    post_lig_font_kern = false
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                local disc_prev = find_disc ( n, PREV )
                local disc_next = find_disc ( n, NEXT )
                if disc_prev then
                    local REPLACE = disc_prev.replace
                    REPLACE = INS_A ( REPLACE, TAIL ( REPLACE ), NEW ( KERN ) )
                    TAIL ( REPLACE ).kern = kern_value
                    disc_prev.replace = REPLACE
                    local POST = disc_prev.post
                    POST = INS_A ( POST, TAIL ( POST ), NEW ( KERN ) )
                    TAIL ( POST ).kern = post_lig_kern
                    disc_prev.post = POST
                elseif disc_next then
                    local REPLACE = disc_next.replace
                    REPLACE = INS_B ( REPLACE, REPLACE, NEW ( KERN ) )
                    REPLACE.kern = kern_value
                    disc_next.replace = REPLACE
                    local PRE = disc_next.pre
                    PRE = INS_B ( PRE, PRE, NEW ( KERN ) )
                    PRE.kern = hyphen_kern
                    disc_next.pre = PRE
                else
                    INS_A ( head, n, NEW ( KERN ) )
                    NEXT ( n ).kern = kern_value
                end
            end
        end
    end
    return head
end

local function place_marks ( head )
    for n in T ( head ) do
        if n.id == HLIST or n.id == VLIST then
            n.head = place_marks ( n.head )
        elseif n.id == WI and n.user_id == 289473 then
            local kern_add = 0
            if NEXT ( n ) and NEXT ( n ).id == DISC and NEXT ( n ).replace and NEXT ( n ).replace.id == KERN then
                kern_add = kern_add + calc_value ( NEXT ( n ).replace.kern ) * 0.5
            elseif NEXT ( n ).id == KERN and NEXT ( n ).kern then
                kern_add = kern_add + calc_value ( NEXT ( n ).kern ) * 0.5
            end
            if PREV ( n ) and PREV ( n ).id == DISC and PREV ( n ).replace and TAIL ( PREV ( n ).replace ).id == KERN then
                kern_add = kern_add - calc_value ( TAIL ( PREV ( n ).replace ).kern ) * 0.5
            elseif PREV ( n ).id == KERN and PREV ( n ).kern then
                kern_add = kern_add - calc_value ( PREV ( n ).kern ) * 0.5
            end
            local size_factor = 1
            if font.current() then
                size_factor = calc_value ( GET_FONT ( font.current() ).size / 10 )
            end
            head = INS_B ( head, n, NEW ( WI, pdfliteral ) )
            PREV ( n ).mode = 0
            PREV ( n ).data = "q .2 .8 1 rg " .. kern_add .. " 0 m " .. ( kern_add + 2 * size_factor ) .. " " .. -3 * size_factor .. " l " .. ( kern_add - 2 * size_factor ) .. " " .. -3 * size_factor .. " l " .. kern_add .. " 0 l f Q"
            n.user_id = 848485
        end
    end
    return head
end

local function lig_parse ( head )
    if all_short_f then
        for n in T_GLYPH ( head ) do
            if n.char == 102 and n.font then
                local tfmdata = GET_FONT ( n.font )
                if tfmdata.resources then
                    local resources = tfmdata.resources
                    if resources.unicodes then
                        local uni = resources.unicodes
                        for key, value in pairs ( uni ) do
                            if key == "f.short" or key == "f.alt" then
                                n.char = value
                            end
                        end
                    end
                end
            end
        end
    end
    local glyph_count = 0
    for n in T_GLYPH ( head ) do
        glyph_count = glyph_count + 1
        if glyph_count > 4 then break end
    end
    if glyph_count > 4 then
        local text_table = { nil, nil, nil, nil, nil, nil, nil, nil, nil }
        local table_counter = 0
        for n in T_GLYPH ( head ) do
            if n.char then
                table_counter = table_counter + 1
                text_table[table_counter] = CHAR ( n.char )
            end
        end
        local text_string = {""}
        for i = 1, table_counter do
            text_string[#text_string + 1] = text_table[i]
        end
        text_string = T_CC (text_string)

        local function lt ( nolig, lig, lig_beg, lig_end, text, ligs, plus )
            if FIND ( text_string, text ) then
                no_lig ( nolig, lig, lig_beg, lig_end, text, head, ligs, plus )
            end
        end

        local ligs = get_ligs ( head )
        if not no_default then
            if next ( ligs["ff"] ) then
                lt ( true, "ff", 3, 4, "Auff+", ligs["ff"], "aeiloruyäöü" )
                lt ( true, "ff", 3, 4, "auff+", ligs["ff"], "aeiloruyäöü" )
                lt ( false, "ff", 4, 5, "Lauffen", ligs["ff"] )
                lt ( false, "ff", 5, 6, "Stauffach", ligs["ff"] )
                lt ( false, "ff", 5, 6, "Stauffen", ligs["ff"] )
                lt ( false, "ff", 5, 6, "stauffen", ligs["ff"] )
                lt ( false, "ff", 5, 6, "Stauffer", ligs["ff"] )
                lt ( false, "ff", 5, 6, "stauffer", ligs["ff"] )
                lt ( false, "ff", 5, 6, "Stauffisch", ligs["ff"] )
                lt ( false, "ff", 5, 6, "stauffisch", ligs["ff"] )
                lt ( false, "ff", 5, 6, "chauffier", ligs["ff"] )
                lt ( false, "ff", 5, 6, "Chauffier", ligs["ff"] )
                lt ( false, "ff", 5, 6, "chauffeur", ligs["ff"] )
                lt ( false, "ff", 5, 6, "Chauffeur", ligs["ff"] )
                lt ( false, "ff", 5, 6, "chauffement", ligs["ff"] )
                lt ( true, "ff", 5, 6, "Brieff", ligs["ff"] )
                lt ( true, "ff", 5, 6, "brieff", ligs["ff"] )
                lt ( true, "ff", 4, 5, "Cheff", ligs["ff"] )
                lt ( true, "ff", 4, 5, "cheff+", ligs["ff"], "aäeioöruü" )
                lt ( false, "ff", 4, 5, "cheffekt", ligs["ff"] )
                lt ( false, "ff", 5, 6, "Scheffel", ligs["ff"] )
                lt ( false, "ff", 5, 6, "scheffel", ligs["ff"] )
                lt ( false, "ff", 4, 5, "cheffizi", ligs["ff"] )
                lt ( false, "ff", 4, 5, "cheffé", ligs["ff"] )
                lt ( true, "ff", 4, 5, "cheffl+", ligs["ff"], "aiou" )
                lt ( true, "ff", 5, 6, "Dampff", ligs["ff"] )
                lt ( true, "ff", 5, 6, "dampff", ligs["ff"] )
                lt ( true, "ff", 4, 5, "Dorff+", ligs["ff"], "aäeiloöruü" )
                lt ( true, "ff", 4, 5, "dorff+", ligs["ff"], "aäeiloöruü" )
                lt ( true, "ff", 4, 5, "Hanff", ligs["ff"] )
                lt ( true, "ff", 4, 5, "hanff", ligs["ff"] )
                lt ( true, "ff", 3, 4, "Hoff+", ligs["ff"], "aäiloöruü" )
                lt ( false, "ff", 3, 4, "Hoffacker", ligs["ff"] )
                lt ( false, "ff", 3, 4, "Hoffart", ligs["ff"] )
                lt ( false, "ff", 3, 4, "Hoffärt", ligs["ff"] )
                lt ( false, "ff", 3, 4, "Hoffricht", ligs["ff"] )
                lt ( false, "ff", 3, 4, "Hoffranz", ligs["ff"] )
                lt ( true, "ff", 4, 5, "Golff", ligs["ff"] )
                lt ( true, "ff", 4, 5, "golff", ligs["ff"] )
                lt ( true, "ff", 3, 4, "Hoffern", ligs["ff"] )
                lt ( true, "ff", 3, 4, "hoffern", ligs["ff"] )
                lt ( true, "ff", 3, 4, "Hoffest", ligs["ff"] )
                lt ( true, "ff", 4, 5, "Impff", ligs["ff"] )
                lt ( true, "ff", 5, 6, "Kampff+", ligs["ff"], "aäeoöruü" )
                lt ( true, "ff", 5, 6, "kampff+", ligs["ff"], "aäeoöruü" )
                lt ( true, "ff", 4, 5, "Kopff+", ligs["ff"], "aäeoöruü" )
                lt ( true, "ff", 4, 5, "kopff+", ligs["ff"], "aäeoöruü" )
                lt ( true, "ff", 5, 6, "Klopff", ligs["ff"] )
                lt ( true, "ff", 5, 6, "klopff", ligs["ff"] )
                lt ( true, "ff", 4, 5, "Prüff", ligs["ff"] )
                lt ( true, "ff", 4, 5, "prüff", ligs["ff"] )
                lt ( true, "ff", 3, 4, "Ruffach", ligs["ff"] )
                lt ( true, "ff", 3, 4, "ruffach", ligs["ff"] )
                lt ( true, "ff", 5, 6, "Rumpff", ligs["ff"] )
                lt ( true, "ff", 5, 6, "Schaffang", ligs["ff"] )
                lt ( true, "ff", 5, 6, "Schaffarm", ligs["ff"] )
                lt ( true, "ff", 5, 6, "Schaffels", ligs["ff"] )
                lt ( true, "ff", 6, 7, "Schilff", ligs["ff"] )
                lt ( true, "ff", 6, 7, "schilff", ligs["ff"] )
                lt ( true, "ff", 4, 5, "Senff", ligs["ff"] )
                lt ( true, "ff", 4, 5, "senffa", ligs["ff"] )
                lt ( true, "ff", 4, 5, "senffl", ligs["ff"] )
                lt ( true, "ff", 5, 6, "Sumpff", ligs["ff"] )
                lt ( true, "ff", 5, 6, "sumpff", ligs["ff"] )
                lt ( true, "ff", 5, 6, "Tariff", ligs["ff"] )
                lt ( true, "ff", 5, 6, "tariff", ligs["ff"] )
                lt ( true, "ff", 4, 5, "Tieff", ligs["ff"] )
                lt ( true, "ff", 4, 5, "tieff", ligs["ff"] )
                lt ( false, "ff", 4, 5, "tieffekt", ligs["ff"] )
                lt ( false, "ff", 4, 5, "tieffiz", ligs["ff"] )
                lt ( true, "ff", 4, 5, "chaffron", ligs["ff"] )
                lt ( true, "ff", 3, 4, "eiffest", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffabrik", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffacet", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffachl", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffachm", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffäch", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffaden", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffäd", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffähig", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffahn", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffahr", ligs["ff"] )
                lt ( false, "ff", 2, 3, "iffahrt", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffähr", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffaktor", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffakult", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffall", ligs["ff"] )
                lt ( false, "ff", 1, 2, "ffallee", ligs["ff"] )
                lt ( false, "ff", 1, 2, "ffallerg", ligs["ff"] )
                lt ( false, "ff", 1, 2, "ffallokat", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffäll", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffalt", ligs["ff"] )
                lt ( false, "ff", 2, 3, "iffalt", ligs["ff"] )
                lt ( false, "ff", 2, 3, "offalt", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffält", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffami", ligs["ff"] )
                lt ( false, "ff", 3, 4, "Diffami", ligs["ff"] )
                lt ( false, "ff", 3, 4, "diffami", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffanat", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffans", ligs["ff"] )
                lt ( false, "ff", 3, 4, "riffans", ligs["ff"] )
                lt ( false, "ff", 3, 4, "toffans", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffanta", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffarb", ligs["ff"] )
                lt ( false, "ff", 1, 2, "ffarbeit", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffärb", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffaschi", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffassad", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffäul", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffecht", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffeder", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffedr", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffehl", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffeier", ligs["ff"] )
                lt ( false, "ff", 3, 4, "toffeier", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffeind+", ligs["ff"], "els" )
                lt ( false, "ff", 1, 2, "ffeindealer", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffeld", ligs["ff"] )
                lt ( false, "ff", 3, 4, "Büffeld", ligs["ff"] )
                lt ( false, "ff", 3, 4, "büffeld", ligs["ff"] )
                lt ( false, "ff", 1, 2, "ffeldenk", ligs["ff"] )
                lt ( false, "ff", 2, 3, "Iffeld", ligs["ff"] )
                lt ( false, "ff", 3, 4, "Löffeld", ligs["ff"] )
                lt ( false, "ff", 3, 4, "löffeld", ligs["ff"] )
                lt ( false, "ff", 3, 4, "Müffeld", ligs["ff"] )
                lt ( false, "ff", 3, 4, "müffeld", ligs["ff"] )
                lt ( false, "ff", 3, 4, "nüffeld", ligs["ff"] )
                lt ( false, "ff", 3, 4, "Riffeld", ligs["ff"] )
                lt ( false, "ff", 3, 4, "taffeld", ligs["ff"] )
                lt ( false, "ff", 3, 4, "toffeld", ligs["ff"] )
                lt ( false, "ff", 4, 5, "Trüffeld", ligs["ff"] )
                lt ( false, "ff", 4, 5, "trüffeld", ligs["ff"] )
                lt ( false, "ff", 3, 4, "Waffeld", ligs["ff"] )
                lt ( false, "ff", 3, 4, "waffeld", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffell", ligs["ff"] )
                lt ( false, "ff", 1, 2, "ffelleck", ligs["ff"] )
                lt ( false, "ff", 1, 2, "ffellinde", ligs["ff"] )
                lt ( false, "ff", 3, 4, "Muffell", ligs["ff"] )
                lt ( false, "ff", 3, 4, "muffell", ligs["ff"] )
                lt ( false, "ff", 2, 3, "öffell", ligs["ff"] )
                lt ( false, "ff", 3, 4, "taffell", ligs["ff"] )
                lt ( false, "ff", 3, 4, "toffell", ligs["ff"] )
                lt ( false, "ff", 2, 3, "üffell", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffeile", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffenster", ligs["ff"] )
                lt ( true, "ff", 1, 2, "fferien", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffernseh", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffertig", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffestl", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffests", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffetisch", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffetus", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffett", ligs["ff"] )
                lt ( false, "ff", 3, 4, "Buffett", ligs["ff"] )
                lt ( false, "ff", 3, 4, "Büffett", ligs["ff"] )
                lt ( false, "ff", 3, 4, "buffett", ligs["ff"] )
                lt ( false, "ff", 3, 4, "büffett", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffetz", ligs["ff"] )
                lt ( false, "ff", 3, 4, "Buffetz", ligs["ff"] )
                lt ( false, "ff", 3, 4, "Büffetz", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffeud", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffeue", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffilet", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffindung", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffirm", ligs["ff"] )
                lt ( false, "ff", 2, 3, "affirm", ligs["ff"] )
                lt ( false, "ff", 2, 3, "Affirm", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffolg", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffoli", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffolter", ligs["ff"] )
                lt ( false, "ff", 2, 3, "Affoltern", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffond", ligs["ff"] )
                lt ( true, "ff", 1, 2, "fforder", ligs["ff"] )
                lt ( true, "ff", 1, 2, "fförder", ligs["ff"] )
                lt ( true, "ff", 1, 2, "fforell", ligs["ff"] )
                lt ( true, "ff", 1, 2, "fform", ligs["ff"] )
                lt ( true, "ff", 1, 2, "fförm", ligs["ff"] )
                lt ( true, "ff", 1, 2, "fforsch", ligs["ff"] )
                lt ( true, "ff", 1, 2, "fforen", ligs["ff"] )
                lt ( true, "ff", 1, 2, "fforu", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffoto", ligs["ff"] )
                lt ( true, "ff", 1, 2, "fföt", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffracht", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffrag", ligs["ff"] )
                lt ( false, "ff", 3, 4, "Suffrage", ligs["ff"] )
                lt ( false, "ff", 3, 4, "suffrage", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffrak", ligs["ff"] )
                lt ( false, "ff", 3, 4, "toffrak", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffrank", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffräs", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffrau", ligs["ff"] )
                lt ( false, "ff", 1, 2, "ffraum", ligs["ff"] )
                lt ( false, "ff", 1, 2, "ffraub", ligs["ff"] )
                lt ( false, "ff", 1, 2, "ffrausch", ligs["ff"] )
                lt ( false, "ff", 1, 2, "ffraup", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffreak", ligs["ff"] )
                lt ( false, "ff", 3, 4, "toffreak", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffregat", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffrei", ligs["ff"] )
                lt ( false, "ff", 4, 5, "chiffrei", ligs["ff"] )
                lt ( false, "ff", 3, 4, "toffrei", ligs["ff"] )
                lt ( false, "ff", 2, 3, "uffreis", ligs["ff"] )
                lt ( false, "ff", 3, 4, "luffrei", ligs["ff"] )
                lt ( false, "ff", 2, 3, "iffreig", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffremd", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffreq", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffreu", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffrisch", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffried", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffries", ligs["ff"] )
                lt ( false, "ff", 3, 4, "toffries", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffrist", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffriseu", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffrisur", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffront", ligs["ff"] )
                lt ( false, "ff", 2, 3, "affront", ligs["ff"] )
                lt ( false, "ff", 2, 3, "Affront", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffrosch", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffrösch", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffrucht", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffrücht", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffrüh", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffund", ligs["ff"] )
                lt ( false, "ff", 2, 3, "iffund", ligs["ff"] )
                lt ( false, "ff", 3, 4, "toffund", ligs["ff"] )
                lt ( true, "ff", 1, 2, "fführ", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffunk", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffühl", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffüll", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffürst", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffuß", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffuss", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffüß", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffüss", ligs["ff"] )
                lt ( false, "ff", 2, 3, "iffuss", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffutter", ligs["ff"] )
                lt ( true, "ff", 1, 2, "ffütter", ligs["ff"] )
                lt ( true, "ff", 3, 4, "hoffan", ligs["ff"] )
                lt ( true, "ff", 3, 4, "hoffersch", ligs["ff"] )
                lt ( true, "ff", 3, 4, "hoffest", ligs["ff"] )
                lt ( true, "ff", 3, 4, "hoffete", ligs["ff"] )
                lt ( true, "ff", 2, 3, "lffach", ligs["ff"] )
                lt ( true, "ff", 2, 3, "offegen", ligs["ff"] )
                lt ( true, "ff", 2, 3, "pffach", ligs["ff"] )
                lt ( true, "ff", 2, 3, "pffern", ligs["ff"] )
                lt ( true, "ff", 2, 3, "pffest", ligs["ff"] )
                lt ( true, "ff", 2, 3, "pffels", ligs["ff"] )
                lt ( true, "ff", 2, 3, "pffont", ligs["ff"] )
                lt ( true, "ff", 2, 3, "pffüh", ligs["ff"] )
                lt ( true, "ff", 4, 5, "reiffern", ligs["ff"] )
                lt ( true, "ff", 2, 3, "rffan", ligs["ff"] )
                lt ( true, "ff", 2, 3, "rffeel", ligs["ff"] )
                lt ( true, "ff", 2, 3, "rffest", ligs["ff"] )
                lt ( true, "ff", 2, 3, "rffinn", ligs["ff"] )
                lt ( true, "ff", 2, 3, "rffleck", ligs["ff"] )
                lt ( true, "ff", 5, 6, "straffern", ligs["ff"] )
                lt ( false, "ff", 7, 8, "rtstraffern", ligs["ff"] )
                lt ( false, "ff", 7, 8, "ssstraffern", ligs["ff"] )
                lt ( true, "ff", 2, 3, "uffax", ligs["ff"] )
                lt ( true, "ff", 3, 4, "ünff", ligs["ff"] )
                lt ( true, "ff", 4, 5, "wurff+", ligs["ff"], "aäeiloöruü" )
            end
            if next ( ligs["fi"] ) then
                lt ( true, "fi", 3, 4, "Aufi", ligs["fi"] )
                lt ( true, "fi", 3, 4, "aufinstr", ligs["fi"] )
                lt ( true, "fi", 3, 4, "aufirr", ligs["fi"] )
                lt ( true, "fi", 3, 4, "aufisst", ligs["fi"] )
                lt ( true, "fi", 5, 6, "Briefi", ligs["fi"] )
                lt ( true, "fi", 5, 6, "briefi", ligs["fi"] )
                lt ( false, "fi", 5, 6, "Briefing", ligs["fi"] )
                lt ( false, "fi", 6, 7, "ebriefing", ligs["fi"] )
                lt ( true, "fi", 4, 5, "Chefi", ligs["fi"] )
                lt ( true, "fi", 4, 5, "chefi", ligs["fi"] )
                lt ( false, "fi", 4, 5, "Chefin", ligs["fi"] )
                lt ( true, "fi", 4, 5, "Chefin+", ligs["fi"] , "abcdefghijklmopqrstuvwxyzäöü" )
                lt ( false, "fi", 4, 5, "chefin", ligs["fi"] )
                lt ( true, "fi", 4, 5, "chefind", ligs["fi"] )
                lt ( false, "fi", 4, 5, "chefibel", ligs["fi"] )
                lt ( false, "fi", 4, 5, "chefiebe", ligs["fi"] )
                lt ( false, "fi", 4, 5, "chefigur", ligs["fi"] )
                lt ( false, "fi", 4, 5, "chefilm", ligs["fi"] )
                lt ( false, "fi", 4, 5, "chefili", ligs["fi"] )
                lt ( false, "fi", 4, 5, "chefirm", ligs["fi"] )
                lt ( false, "fi", 4, 5, "chefisch", ligs["fi"] )
                lt ( true, "fi", 4, 5, "Dorfi", ligs["fi"] )
                lt ( true, "fi", 4, 5, "dorfi", ligs["fi"] )
                lt ( true, "fi", 3, 4, "Hofi", ligs["fi"] )
                lt ( false, "fi", 3, 4, "Hofier", ligs["fi"] )
                lt ( true, "fi", 5, 6, "Kampfi", ligs["fi"] )
                lt ( true, "fi", 5, 6, "kampfi", ligs["fi"] )
                lt ( true, "fi", 4, 5, "Kaufi", ligs["fi"] )
                lt ( true, "fi", 4, 5, "kaufi", ligs["fi"] )
                lt ( true, "fi", 4, 5, "Laufi", ligs["fi"] )
                lt ( true, "fi", 4, 5, "laufi", ligs["fi"] )
                lt ( false, "fi", 4, 5, "Laufig", ligs["fi"] )
                lt ( false, "fi", 5, 6, "Blaufi", ligs["fi"] )
                lt ( false, "fi", 4, 5, "laufilter", ligs["fi"] )
                lt ( false, "fi", 4, 5, "laufiedr", ligs["fi"] )
                lt ( true, "fi", 3, 4, "rüfi", ligs["fi"] )
                lt ( true, "fi", 5, 6, "Rumpfi", ligs["fi"] )
                lt ( true, "fi", 5, 6, "rumpfi", ligs["fi"] )
                lt ( false, "fi", 5, 6, "rumpfig", ligs["fi"] )
                lt ( true, "fi", 4, 5, "chafi", ligs["fi"] )
                lt ( false, "fi", 5, 6, "schafigu", ligs["fi"] )
                lt ( true, "fi", 5, 6, "chlafi", ligs["fi"] )
                lt ( false, "fi", 5, 6, "chlafitt", ligs["fi"] )
                lt ( true, "fi", 5, 6, "Strafi", ligs["fi"] )
                lt ( true, "fi", 5, 6, "strafi", ligs["fi"] )
                lt ( true, "fi", 5, 6, "Tarifi", ligs["fi"] )
                lt ( true, "fi", 5, 6, "tarifi", ligs["fi"] )
                lt ( false, "fi", 5, 6, "Tarifier", ligs["fi"] )
                lt ( false, "fi", 5, 6, "tarifier", ligs["fi"] )
                lt ( true, "fi", 4, 5, "Tiefinn", ligs["fi"] )
                lt ( true, "fi", 4, 5, "tiefinn", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fidee", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fideol", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fidentif", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fidentit", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fidol", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fidyll", ligs["fi"] )
                lt ( true, "fi", 1, 2, "figel", ligs["fi"] )
                lt ( false, "fi", 1, 2, "figelehrt", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fikone", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fillus", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fimman", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fimmob", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fimmun", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fimp", ligs["fi"] )
                lt ( true, "fi", 1, 2, "findex", ligs["fi"] )
                lt ( true, "fi", 1, 2, "findikat", ligs["fi"] )
                lt ( true, "fi", 1, 2, "findiv", ligs["fi"] )
                lt ( true, "fi", 1, 2, "findiz", ligs["fi"] )
                lt ( true, "fi", 1, 2, "findust", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finfekt", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finfiz", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finfo", ligs["fi"] )
                lt ( false, "fi", 4, 5, "Delfinfo", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finfra", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finfus", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fingenieur", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finhab", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finhalat", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finhalt", ligs["fi"] )
                lt ( false, "fi", 4, 5, "Delfinhalt", ligs["fi"] )
                lt ( false, "fi", 4, 5, "raffinhalt", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finitia", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finjekt", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finkont", ligs["fi"] )
                lt ( false, "fi", 4, 5, "Delfinkont", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finnenaus", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finnenohr", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finnenfl", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finnenl", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finnenraum", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finnenräum", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finnens", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finner", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finnig", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finnov", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finsass", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finsekt", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finsel", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finserat", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finsign", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finspek", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finsta", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finstinkt", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finstitu", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finstrukt+", ligs["fi"] , "io" )
                lt ( true, "fi", 1, 2, "finstrum", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finsuff", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finszen", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fintars", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fintell", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fintegr", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fintens", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finter", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finton", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fintrig", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finvent", ligs["fi"] )
                lt ( true, "fi", 1, 2, "finvest", ligs["fi"] )
                lt ( true, "fi", 1, 2, "firis", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fironi", ligs["fi"] )
                lt ( true, "fi", 1, 2, "firre", ligs["fi"] )
                lt ( true, "fi", 1, 2, "firru", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fisolat", ligs["fi"] )
                lt ( true, "fi", 1, 2, "fisolie", ligs["fi"] )
            end
            if next ( ligs["fl"] ) then
                lt ( true, "fl", 3, 4, "Aufl+", ligs["fl"], "aeiouyäöü" )
                lt ( true, "fl", 3, 4, "aufl", ligs["fl"] )
                lt ( false, "fl", 3, 4, "auflair", ligs["fl"] )
                lt ( false, "fl", 3, 4, "aufläche", ligs["fl"] )
                lt ( false, "fl", 3, 4, "aufliegl", ligs["fl"] )
                lt ( false, "fl", 3, 4, "auflüssig", ligs["fl"] )
                lt ( false, "fl", 4, 5, "baufl", ligs["fl"] )
                lt ( false, "fl", 4, 5, "Baufl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "bauflösen", ligs["fl"] )
                lt ( false, "fl", 5, 6, "blaufl", ligs["fl"] )
                lt ( true, "fl", 5, 6, "blaufloch", ligs["fl"] )
                lt ( true, "fl", 5, 6, "blauflog", ligs["fl"] )
                lt ( false, "fl", 5, 6, "Blaufl", ligs["fl"] )
                lt ( false, "fl", 5, 6, "fraufl", ligs["fl"] )
                lt ( false, "fl", 5, 6, "Fraufl", ligs["fl"] )
                lt ( false, "fl", 4, 5, "gauflöte", ligs["fl"] )
                lt ( false, "fl", 5, 6, "graufl", ligs["fl"] )
                lt ( false, "fl", 5, 6, "Graufl", ligs["fl"] )
                lt ( false, "fl", 5, 6, "onauflo", ligs["fl"] )
                lt ( false, "fl", 5, 6, "onauflu", ligs["fl"] )
                lt ( false, "fl", 7, 8, "Moskaufl", ligs["fl"] )
                lt ( false, "fl", 6, 7, "Schauflieg", ligs["fl"] )
                lt ( false, "fl", 6, 7, "Schaufloß", ligs["fl"] )
                lt ( false, "fl", 6, 7, "schauflöß", ligs["fl"] )
                lt ( false, "fl", 6, 7, "Schauflug", ligs["fl"] )
                lt ( false, "fl", 6, 7, "Schauflüg", ligs["fl"] )
                lt ( false, "fl", 6, 7, "schauflieg", ligs["fl"] )
                lt ( false, "fl", 6, 7, "schaufloß", ligs["fl"] )
                lt ( false, "fl", 6, 7, "schauflöß", ligs["fl"] )
                lt ( false, "fl", 6, 7, "schauflug", ligs["fl"] )
                lt ( false, "fl", 6, 7, "schauflüg", ligs["fl"] )
                lt ( false, "fl", 4, 5, "Taufliege", ligs["fl"] )
                lt ( true, "fl", 5, 6, "Briefl", ligs["fl"] )
                lt ( true, "fl", 5, 6, "briefl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "Chefl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "chefl", ligs["fl"] )
                lt ( false, "fl", 5, 6, "achefl", ligs["fl"] )
                lt ( false, "fl", 5, 6, "ichefl", ligs["fl"] )
                lt ( false, "fl", 5, 6, "schefl", ligs["fl"] )
                lt ( false, "fl", 4, 5, "chefläche", ligs["fl"] )
                lt ( true, "fl", 5, 6, "Dampfl", ligs["fl"] )
                lt ( true, "fl", 5, 6, "dampfl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "Dorfl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "dorfl", ligs["fl"] )
                lt ( false, "fl", 4, 5, "dorfliese", ligs["fl"] )
                lt ( false, "fl", 4, 5, "dorflüg", ligs["fl"] )
                lt ( true, "fl", 4, 5, "Fünfl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "fünfl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "Golfl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "golfl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "Hanfl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "hanfl", ligs["fl"] )
                lt ( false, "fl", 5, 6, "thanflamm", ligs["fl"] )
                lt ( true, "fl", 3, 4, "Hofl", ligs["fl"] )
                lt ( true, "fl", 3, 4, "hofl", ligs["fl"] )
                lt ( false, "fl", 3, 4, "hoflosk", ligs["fl"] )
                lt ( true, "fl", 3, 4, "Huflatt", ligs["fl"] )
                lt ( true, "fl", 3, 4, "huflatt", ligs["fl"] )
                lt ( true, "fl", 3, 4, "Hufled", ligs["fl"] )
                lt ( true, "fl", 3, 4, "hufled", ligs["fl"] )
                lt ( true, "fl", 4, 5, "Impfl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "impfla", ligs["fl"] )
                lt ( false, "fl", 5, 6, "eimpflanz", ligs["fl"] )
                lt ( true, "fl", 4, 5, "impfle", ligs["fl"] )
                lt ( false, "fl", 5, 6, "eimpfleg", ligs["fl"] )
                lt ( false, "fl", 5, 6, "timpfleg", ligs["fl"] )
                lt ( true, "fl", 4, 5, "impflücke", ligs["fl"] )
                lt ( true, "fl", 5, 6, "Kampfl", ligs["fl"] )
                lt ( true, "fl", 5, 6, "kampfl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "Kopfl+", ligs["fl"], "äeioöuüy" )
                lt ( true, "fl", 4, 5, "kopfl+", ligs["fl"], "äeioöuüy" )
                lt ( true, "fl", 4, 5, "Köpfl+", ligs["fl"], "aäioöuüy" )
                lt ( true, "fl", 4, 5, "köpfl+", ligs["fl"], "aäioöuüy" )
                lt ( true, "fl", 3, 4, "opfla", ligs["fl"] )
                lt ( false, "fl", 4, 5, "kopflaster", ligs["fl"] )
                lt ( false, "fl", 4, 5, "kopfleg", ligs["fl"] )
                lt ( false, "fl", 4, 5, "kopflaum", ligs["fl"] )
                lt ( true, "fl", 5, 6, "Pfeifl", ligs["fl"] )
                lt ( true, "fl", 5, 6, "pfeifl", ligs["fl"] )
                lt ( true, "fl", 5, 6, "Pfiffl", ligs["fl"] )
                lt ( true, "fl", 5, 6, "pfiffl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "Prüfl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "prüfl", ligs["fl"] )
                lt ( true, "fl", 6, 7, "Reliefl", ligs["fl"] )
                lt ( true, "fl", 6, 7, "reliefl", ligs["fl"] )
                lt ( true, "fl", 3, 4, "Rufl", ligs["fl"] )
                lt ( true, "fl", 3, 4, "rufl", ligs["fl"] )
                lt ( false, "fl", 5, 6, "Durufl", ligs["fl"] )
                lt ( false, "fl", 6, 7, "mbarufl", ligs["fl"] )
                lt ( false, "fl", 3, 4, "ruflagge", ligs["fl"] )
                lt ( false, "fl", 3, 4, "rufleisch", ligs["fl"] )
                lt ( true, "fl", 5, 6, "Schafl", ligs["fl"] )
                lt ( true, "fl", 5, 6, "schafl", ligs["fl"] )
                lt ( true, "fl", 6, 7, "Schiefl", ligs["fl"] )
                lt ( true, "fl", 6, 7, "schiefl", ligs["fl"] )
                lt ( true, "fl", 6, 7, "Schilfl", ligs["fl"] )
                lt ( true, "fl", 6, 7, "schilfl", ligs["fl"] )
                lt ( true, "fl", 6, 7, "Schlafl", ligs["fl"] )
                lt ( true, "fl", 6, 7, "schlafl", ligs["fl"] )
                lt ( true, "fl", 7, 8, "Schleifl", ligs["fl"] )
                lt ( true, "fl", 7, 8, "schleifl", ligs["fl"] )
                lt ( true, "fl", 8, 9, "Schrumpfl", ligs["fl"] )
                lt ( true, "fl", 8, 9, "schrumpfl", ligs["fl"] )
                lt ( true, "fl", 7, 8, "Schweifl", ligs["fl"] )
                lt ( true, "fl", 7, 8, "schweifl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "Senfl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "senfl+", ligs["fl"], "aä" )
                lt ( true, "fl", 5, 6, "Steifl", ligs["fl"] )
                lt ( true, "fl", 5, 6, "steifl", ligs["fl"] )
                lt ( true, "fl", 5, 6, "Strafl", ligs["fl"] )
                lt ( true, "fl", 5, 6, "strafl", ligs["fl"] )
                lt ( true, "fl", 7, 8, "Strumpfl", ligs["fl"] )
                lt ( true, "fl", 7, 8, "strumpfl", ligs["fl"] )
                lt ( true, "fl", 5, 6, "Sumpfl", ligs["fl"] )
                lt ( true, "fl", 5, 6, "sumpfl", ligs["fl"] )
                lt ( false, "fl", 6, 7, "nsumpfl", ligs["fl"] )
                lt ( false, "fl", 6, 7, "isumpfl", ligs["fl"] )
                lt ( false, "fl", 6, 7, "ssumpfl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "Surfl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "surfl", ligs["fl"] )
                lt ( false, "fl", 4, 5, "surfleck", ligs["fl"] )
                lt ( false, "fl", 4, 5, "surflüg", ligs["fl"] )
                lt ( false, "fl", 4, 5, "surflüss", ligs["fl"] )
                lt ( true, "fl", 5, 6, "Tarifl", ligs["fl"] )
                lt ( true, "fl", 5, 6, "tarifl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "Tiefl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "tiefl", ligs["fl"] )
                lt ( false, "fl", 4, 5, "tiefläche", ligs["fl"] )
                lt ( false, "fl", 5, 6, "atieflaute", ligs["fl"] )
                lt ( false, "fl", 5, 6, "atieflut", ligs["fl"] )
                lt ( true, "fl", 4, 5, "Topfl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "topfl", ligs["fl"] )
                lt ( false, "fl", 4, 5, "Topflagg", ligs["fl"] )
                lt ( false, "fl", 4, 5, "Topflitz", ligs["fl"] )
                lt ( false, "fl", 4, 5, "Topflor", ligs["fl"] )
                lt ( false, "fl", 5, 6, "rtopfli", ligs["fl"] )
                lt ( false, "fl", 4, 5, "topfläch", ligs["fl"] )
                lt ( false, "fl", 4, 5, "topfleg", ligs["fl"] )
                lt ( true, "fl", 5, 6, "rtopfleg", ligs["fl"] )
                lt ( false, "fl", 4, 5, "topflop", ligs["fl"] )
                lt ( false, "fl", 4, 5, "topflug", ligs["fl"] )
                lt ( false, "fl", 4, 5, "topflüg", ligs["fl"] )
                lt ( true, "fl", 4, 5, "Torfl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "torfl", ligs["fl"] )
                lt ( false, "fl", 4, 5, "Torflagge", ligs["fl"] )
                lt ( false, "fl", 4, 5, "Torflügel", ligs["fl"] )
                lt ( false, "fl", 4, 5, "Torflut", ligs["fl"] )
                lt ( false, "fl", 4, 5, "torfläche", ligs["fl"] )
                lt ( false, "fl", 4, 5, "torflasch", ligs["fl"] )
                lt ( false, "fl", 4, 5, "torflieg", ligs["fl"] )
                lt ( false, "fl", 4, 5, "torflimm", ligs["fl"] )
                lt ( false, "fl", 4, 5, "torflitz", ligs["fl"] )
                lt ( false, "fl", 4, 5, "torfloss", ligs["fl"] )
                lt ( false, "fl", 4, 5, "torflott", ligs["fl"] )
                lt ( false, "fl", 4, 5, "torfluch", ligs["fl"] )
                lt ( false, "fl", 4, 5, "torflug", ligs["fl"] )
                lt ( false, "fl", 4, 5, "torflüg", ligs["fl"] )
                lt ( false, "fl", 4, 5, "torflüss", ligs["fl"] )
                lt ( false, "fl", 4, 5, "torfluss", ligs["fl"] )
                lt ( false, "fl", 4, 5, "torfluß", ligs["fl"] )
                lt ( true, "fl", 5, 6, "Tropfl", ligs["fl"] )
                lt ( true, "fl", 5, 6, "tropfl", ligs["fl"] )
                lt ( false, "fl", 5, 6, "tropflug", ligs["fl"] )
                lt ( true, "fl", 4, 5, "Wurfl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "wurfl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "Würfl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "würfl", ligs["fl"] )
                lt ( true, "fl", 3, 4, "alflede", ligs["fl"] )
                lt ( true, "fl", 2, 3, "aflied", ligs["fl"] )
                lt ( true, "fl", 2, 3, "aflos", ligs["fl"] )
                lt ( false, "fl", 2, 3, "aflosk", ligs["fl"] )
                lt ( false, "fl", 3, 4, "rafloss", ligs["fl"] )
                lt ( true, "fl", 2, 3, "aflück", ligs["fl"] )
                lt ( true, "fl", 4, 5, "ampfl+", ligs["fl"], "aäou" )
                lt ( false, "fl", 4, 5, "ampfläch", ligs["fl"] )
                lt ( false, "fl", 4, 5, "ampflanz", ligs["fl"] )
                lt ( false, "fl", 4, 5, "ampfleg", ligs["fl"] )
                lt ( true, "fl", 3, 4, "arflad", ligs["fl"] )
                lt ( true, "fl", 3, 4, "äufle", ligs["fl"] )
                lt ( true, "fl", 3, 4, "eufle", ligs["fl"] )
                lt ( false, "fl", 3, 4, "eufleiß", ligs["fl"] )
                lt ( false, "fl", 3, 4, "eufleiss", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flaberer", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flabor", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flage", ligs["fl"] )
                lt ( false, "fl", 3, 4, "siflage", ligs["fl"] )
                lt ( false, "fl", 3, 4, "ouflage", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flagun", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flähm", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flaminat", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flamp", ligs["fl"] )
                lt ( true, "fl", 1, 2, "fland", ligs["fl"] )
                lt ( false, "fl", 1, 2, "flandern", ligs["fl"] )
                lt ( false, "fl", 1, 2, "flandrisch", ligs["fl"] )
                lt ( true, "fl", 1, 2, "fländ", ligs["fl"] )
                lt ( true, "fl", 1, 2, "fläng", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flapp", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flärm", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flauf", ligs["fl"] )
                lt ( true, "fl", 1, 2, "fläuf", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flaun", ligs["fl"] )
                lt ( true, "fl", 1, 2, "fleb", ligs["fl"] )
                lt ( false, "fl", 4, 5, "huffleb", ligs["fl"] )
                lt ( true, "fl", 3, 4, "alfleder", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flehn", ligs["fl"] )
                lt ( false, "fl", 2, 3, "nflehn", ligs["fl"] )
                lt ( false, "fl", 2, 3, "rflehn", ligs["fl"] )
                lt ( false, "fl", 3, 4, "Hoflehn", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flehr", ligs["fl"] )
                lt ( true, "fl", 1, 2, "fleiden", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flein", ligs["fl"] )
                lt ( true, "fl", 1, 2, "fleist", ligs["fl"] )
                lt ( true, "fl", 1, 2, "fleit", ligs["fl"] )
                lt ( false, "fl", 6, 7, "Kaltefleiter", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flektür", ligs["fl"] )
                lt ( true, "fl", 1, 2, "fler", ligs["fl"] )
                lt ( false, "fl", 4, 5, "Hoefler", ligs["fl"] )
                lt ( false, "fl", 7, 8, "Knoepffler", ligs["fl"] )
                lt ( false, "fl", 2, 3, "fflerhyth", ligs["fl"] )
                lt ( true, "fl", 1, 2, "fleut", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flich", ligs["fl"] )
                lt ( false, "fl", 1, 2, "flicht", ligs["fl"] )
                lt ( true, "fl", 3, 4, "öpflicht", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flieb", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flief", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flift", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flig", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flila", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flinde", ligs["fl"] )
                lt ( true, "fl", 1, 2, "fling", ligs["fl"] )
                lt ( false, "fl", 5, 6, "Bempfling", ligs["fl"] )
                lt ( false, "fl", 3, 4, "Haflinge", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flini", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flinse", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flisch", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flist", ligs["fl"] )
                lt ( true, "fl", 1, 2, "fliter", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flizenz", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flobby", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flöch", ligs["fl"] )
                lt ( false, "fl", 1, 2, "flöchte", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flöff", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flohn", ligs["fl"] )
                lt ( false, "fl", 1, 2, "flohnetz", ligs["fl"] )
                lt ( false, "fl", 3, 4, "ntflohn", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flöhn", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flok", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flord", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flösch", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flösu", ligs["fl"] )
                lt ( true, "fl", 1, 2, "fluft", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flung", ligs["fl"] )
                lt ( true, "fl", 1, 2, "flust", ligs["fl"] )
                lt ( true, "fl", 4, 5, "Gipfle", ligs["fl"] )
                lt ( true, "fl", 4, 5, "gipfle", ligs["fl"] )
                lt ( true, "fl", 5, 6, "chopfl", ligs["fl"] )
                lt ( true, "fl", 2, 3, "lflady", ligs["fl"] )
                lt ( true, "fl", 2, 3, "lflast", ligs["fl"] )
                lt ( true, "fl", 2, 3, "lflos", ligs["fl"] )
                lt ( false, "fl", 2, 3, "lfloss", ligs["fl"] )
                lt ( false, "fl", 2, 3, "lflosk", ligs["fl"] )
                lt ( true, "fl", 2, 3, "nflehm", ligs["fl"] )
                lt ( true, "fl", 2, 3, "oflad", ligs["fl"] )
                lt ( true, "fl", 2, 3, "ofläd", ligs["fl"] )
                lt ( true, "fl", 2, 3, "oflück", ligs["fl"] )
                lt ( false, "fl", 4, 5, "gopflaum", ligs["fl"] )
                lt ( false, "fl", 4, 5, "iopflast", ligs["fl"] )
                lt ( false, "fl", 4, 5, "nopflaster", ligs["fl"] )
                lt ( false, "fl", 3, 4, "opflair", ligs["fl"] )
                lt ( false, "fl", 3, 4, "opflanz", ligs["fl"] )
                lt ( true, "fl", 3, 4, "öpfle", ligs["fl"] )
                lt ( true, "fl", 3, 4, "orflad", ligs["fl"] )
                lt ( true, "fl", 2, 3, "pflaut", ligs["fl"] )
                lt ( true, "fl", 2, 3, "pfleier", ligs["fl"] )
                lt ( true, "fl", 2, 3, "pflehm", ligs["fl"] )
                lt ( true, "fl", 2, 3, "pfleis", ligs["fl"] )
                lt ( true, "fl", 2, 3, "pfleu", ligs["fl"] )
                lt ( true, "fl", 2, 3, "pflid", ligs["fl"] )
                lt ( true, "fl", 2, 3, "pflied", ligs["fl"] )
                lt ( true, "fl", 2, 3, "pfloch", ligs["fl"] )
                lt ( true, "fl", 2, 3, "pflos", ligs["fl"] )
                lt ( false, "fl", 2, 3, "pfloss", ligs["fl"] )
                lt ( true, "fl", 2, 3, "pflös", ligs["fl"] )
                lt ( true, "fl", 2, 3, "pflup", ligs["fl"] )
                lt ( true, "fl", 2, 3, "pflux", ligs["fl"] )
                lt ( true, "fl", 2, 3, "rfläd", ligs["fl"] )
                lt ( true, "fl", 2, 3, "rflück", ligs["fl"] )
                lt ( true, "fl", 2, 3, "rfluke", ligs["fl"] )
                lt ( true, "fl", 4, 5, "reifl", ligs["fl"] )
                lt ( true, "fl", 4, 5, "Reifl", ligs["fl"] )
                lt ( false, "fl", 5, 6, "Breifl", ligs["fl"] )
                lt ( false, "fl", 5, 6, "breifl", ligs["fl"] )
                lt ( false, "fl", 5, 6, "Dreifl", ligs["fl"] )
                lt ( false, "fl", 5, 6, "dreifl", ligs["fl"] )
                lt ( false, "fl", 5, 6, "Freifl", ligs["fl"] )
                lt ( false, "fl", 5, 6, "freifl", ligs["fl"] )
                lt ( false, "fl", 7, 8, "eiereifl", ligs["fl"] )
                lt ( false, "fl", 4, 5, "reifläch", ligs["fl"] )
                lt ( false, "fl", 4, 5, "reiflagg", ligs["fl"] )
                lt ( false, "fl", 4, 5, "reiflamm", ligs["fl"] )
                lt ( false, "fl", 4, 5, "reiflasch", ligs["fl"] )
                lt ( false, "fl", 4, 5, "reiflies", ligs["fl"] )
                lt ( false, "fl", 4, 5, "reiflock", ligs["fl"] )
                lt ( false, "fl", 4, 5, "reifloh", ligs["fl"] )
                lt ( false, "fl", 4, 5, "reiflöhe", ligs["fl"] )
                lt ( false, "fl", 4, 5, "reiflott", ligs["fl"] )
                lt ( true, "fl", 3, 4, "Tafle", ligs["fl"] )
                lt ( true, "fl", 3, 4, "tafle", ligs["fl"] )
                lt ( false, "fl", 3, 4, "tafleck", ligs["fl"] )
                lt ( false, "fl", 3, 4, "taflege", ligs["fl"] )
                lt ( true, "fl", 3, 4, "urflad", ligs["fl"] )
                lt ( true, "fl", 3, 4, "ürfla", ligs["fl"] )
                lt ( true, "fl", 3, 4, "urfloch", ligs["fl"] )
                lt ( true, "fl", 3, 4, "ürfloch", ligs["fl"] )
                lt ( true, "fl", 3, 4, "wafle", ligs["fl"] )
                lt ( true, "fl", 3, 4, "wefle", ligs["fl"] )
                lt ( true, "fl", 4, 5, "weifle", ligs["fl"] )
                lt ( false, "fl", 4, 5, "weifleck", ligs["fl"] )
                lt ( true, "fl", 4, 5, "werfl", ligs["fl"] )
                lt ( false, "fl", 6, 7, "chwerfl", ligs["fl"] )
                lt ( false, "fl", 4, 5, "werflitz", ligs["fl"] )
            end
            if next ( ligs["ffi"] ) then
                lt ( true, "ff", 2, 3, "affind", ligs["ffi"] )
                lt ( false, "ff", 4, 5, "araffind", ligs["ffi"] )
                lt ( true, "ff", 1, 2, "ffibel", ligs["ffi"] )
                lt ( true, "ff", 1, 2, "ffieb", ligs["ffi"] )
                lt ( true, "ff", 1, 2, "ffigu", ligs["ffi"] )
                lt ( true, "ff", 1, 2, "ffilm", ligs["ffi"] )
                lt ( true, "ff", 1, 2, "ffilter", ligs["ffi"] )
                lt ( true, "ff", 1, 2, "ffinal", ligs["ffi"] )
                lt ( true, "ff", 1, 2, "ffinte", ligs["ffi"] )
                lt ( false, "ff", 3, 4, "raffinte", ligs["ffi"] )
                lt ( true, "ff", 1, 2, "ffinanz", ligs["ffi"] )
                lt ( true, "ff", 1, 2, "ffistel", ligs["ffi"] )
                lt ( true, "ff", 1, 2, "ffixier", ligs["ffi"] )
                lt ( true, "ff", 2, 3, "iffind", ligs["ffi"] )
                lt ( true, "ff", 2, 3, "lffing", ligs["ffi"] )
                lt ( true, "ff", 2, 3, "lffisch", ligs["ffi"] )
                lt ( true, "ff", 2, 3, "nffing", ligs["ffi"] )
                lt ( true, "ff", 2, 3, "pffi", ligs["ffi"] )
                lt ( true, "ff", 4, 5, "reiffing", ligs["ffi"] )
                lt ( true, "fi", 5, 6, "Stoffi", ligs["ffi"] )
                lt ( true, "fi", 5, 6, "stoffi", ligs["ffi"] )
                lt ( false, "fi", 5, 6, "stoffiz", ligs["ffi"] )
                lt ( false, "fi", 5, 6, "stoffig", ligs["ffi"] )
                lt ( true, "fi", 2, 3, "ffinnen", ligs["ffi"] )
            end
            if next ( ligs["ffl"] ) then
                lt ( true, "fl", 5, 6, "Griffl", ligs["ffl"] )
                lt ( true, "fl", 5, 6, "griffl", ligs["ffl"] )
                lt ( true, "fl", 3, 4, "Offline", ligs["ffl"] )
                lt ( true, "fl", 3, 4, "offline", ligs["ffl"] )
                lt ( true, "fl", 5, 6, "Pfiffl", ligs["ffl"] )
                lt ( true, "fl", 6, 7, "Scheffle", ligs["ffl"] )
                lt ( true, "fl", 6, 7, "scheffle", ligs["ffl"] )
                lt ( true, "fl", 6, 7, "Schiffl", ligs["ffl"] )
                lt ( true, "fl", 6, 7, "schiffl", ligs["ffl"] )
                lt ( true, "fl", 5, 6, "Stoffl", ligs["ffl"] )
                lt ( true, "fl", 5, 6, "stoffl", ligs["ffl"] )
                lt ( true, "fl", 3, 4, "afflu", ligs["ffl"] )
                lt ( true, "fl", 2, 3, "fflamell", ligs["ffl"] )
                lt ( true, "fl", 2, 3, "fflast", ligs["ffl"] )
                lt ( true, "fl", 2, 3, "fflatsch", ligs["ffl"] )
                lt ( true, "fl", 2, 3, "ffloch", ligs["ffl"] )
                lt ( true, "fl", 2, 3, "fflos", ligs["ffl"] )
                lt ( true, "fl", 3, 4, "ifflo", ligs["ffl"] )
                lt ( true, "fl", 3, 4, "offlad", ligs["ffl"] )
                lt ( true, "fl", 3, 4, "öffle", ligs["ffl"] )
                lt ( true, "fl", 3, 4, "offlo", ligs["ffl"] )
                lt ( true, "fl", 4, 5, "pufflack", ligs["ffl"] )
                lt ( true, "fl", 4, 5, "taffle", ligs["ffl"] )
                lt ( true, "fl", 3, 4, "ufflad", ligs["ffl"] )
                lt ( true, "fl", 3, 4, "uffläd", ligs["ffl"] )
                lt ( true, "fl", 4, 5, "luffleck", ligs["ffl"] )
                lt ( true, "fl", 3, 4, "äffle", ligs["ffl"] )
                lt ( true, "fl", 3, 4, "üffle", ligs["ffl"] )
                lt ( true, "ff", 3, 4, "Auffl", ligs["ffl"] )
                lt ( true, "ff", 3, 4, "auffl", ligs["ffl"] )
                lt ( true, "ff", 3, 4, "eiffleck", ligs["ffl"] )
                lt ( true, "ff", 1, 2, "fflatter", ligs["ffl"] )
                lt ( true, "ff", 1, 2, "ffläch", ligs["ffl"] )
                lt ( true, "ff", 1, 2, "fflech", ligs["ffl"] )
                lt ( true, "ff", 1, 2, "ffleisch", ligs["ffl"] )
                lt ( true, "ff", 1, 2, "fflexib", ligs["ffl"] )
                lt ( true, "ff", 1, 2, "fflies", ligs["ffl"] )
                lt ( true, "ff", 1, 2, "fflimm", ligs["ffl"] )
                lt ( true, "ff", 1, 2, "ffluch", ligs["ffl"] )
                lt ( true, "ff", 1, 2, "fflüch", ligs["ffl"] )
                lt ( true, "ff", 1, 2, "fflug", ligs["ffl"] )
                lt ( true, "ff", 1, 2, "fflüg", ligs["ffl"] )
                lt ( true, "ff", 1, 2, "fflur", ligs["ffl"] )
                lt ( true, "ff", 1, 2, "ffluss", ligs["ffl"] )
                lt ( true, "ff", 1, 2, "fflüs", ligs["ffl"] )
                lt ( true, "ff", 1, 2, "fflut", ligs["ffl"] )
                lt ( true, "ff", 3, 4, "iefflieg", ligs["ffl"] )
                lt ( true, "ff", 3, 4, "iefflog", ligs["ffl"] )
                lt ( true, "ff", 2, 3, "lfflach", ligs["ffl"] )
                lt ( true, "ff", 3, 4, "mpffl", ligs["ffl"] )
                lt ( true, "ff", 3, 4, "opffl", ligs["ffl"] )
                lt ( true, "ff", 3, 4, "upffl", ligs["ffl"] )
                lt ( true, "ff", 2, 3, "rfflad", ligs["ffl"] )
                lt ( true, "ff", 2, 3, "rfflasch", ligs["ffl"] )
                lt ( true, "ff", 4, 5, "wurffl", ligs["ffl"] )
            end
            if next ( ligs["ft"] ) then
                lt ( true, "ft", 3, 4, "Auft+", ligs["ft"] , "aähioöruüy" )
                lt ( true, "ft", 3, 4, "auft+", ligs["ft"] , "aähioöruüy" )
                lt ( true, "ft", 5, 6, "Brieft", ligs["ft"] )
                lt ( true, "ft", 5, 6, "brieft", ligs["ft"] )
                lt ( true, "ft", 4, 5, "Cheft", ligs["ft"] )
                lt ( true, "ft", 4, 5, "cheft+", ligs["ft"] , "abcdefghijklmnopqrstuvwxyzäöü" )
                lt ( false, "ft", 7, 8, "omicheft+", ligs["ft"] , "ceg" )
                lt ( true, "ft", 4, 5, "Dorft", ligs["ft"] )
                lt ( true, "ft", 4, 5, "dorft", ligs["ft"] )
                lt ( true, "ft", 3, 4, "Elfte", ligs["ft"] )
                lt ( true, "ft", 3, 4, "elfte", ligs["ft"] )
                lt ( false, "ft", 3, 4, "elfterfolg", ligs["ft"] )
                lt ( true, "ft", 4, 5, "Fünft+", ligs["ft"] , "aäeoöruy" )
                lt ( true, "ft", 4, 5, "fünft+", ligs["ft"] , "aäeoöruy" )
                lt ( false, "ft", 4, 5, "fünfterfolg", ligs["ft"] )
                lt ( false, "ft", 4, 5, "Fünfterfolg", ligs["ft"] )
                lt ( false, "ft", 4, 5, "fünftrang", ligs["ft"] )
                lt ( false, "ft", 4, 5, "Fünftrang", ligs["ft"] )
                lt ( false, "ft", 4, 5, "fünftreich", ligs["ft"] )
                lt ( false, "ft", 4, 5, "Fünftreich", ligs["ft"] )
                lt ( false, "ft", 4, 5, "Fünftoper", ligs["ft"] )
                lt ( false, "ft", 4, 5, "Fünftrund", ligs["ft"] )
                lt ( false, "ft", 4, 5, "Fünftäon", ligs["ft"] )
                lt ( false, "ft", 4, 5, "fünftältest", ligs["ft"] )
                lt ( false, "ft", 4, 5, "Fünftältest", ligs["ft"] )
                lt ( true, "ft", 4, 5, "Golft", ligs["ft"] )
                lt ( true, "ft", 4, 5, "golft+", ligs["ft"] , "hiruüy" )
                lt ( true, "ft", 5, 6, "Greift+", ligs["ft"] , "eio" )
                lt ( true, "ft", 4, 5, "Hanftau", ligs["ft"] )
                lt ( true, "ft", 3, 4, "Hoft+", ligs["ft"] , "aäehioöruüy" )
                lt ( true, "ft", 3, 4, "hoft+", ligs["ft"] , "aähioöruü" )
                lt ( true, "ft", 3, 4, "Huftra", ligs["ft"] )
                lt ( true, "ft", 4, 5, "Kopft+", ligs["ft"] , "aäehioöruüy" )
                lt ( true, "ft", 4, 5, "Laufte", ligs["ft"] )
                lt ( true, "ft", 4, 5, "Prüft+", ligs["ft"] , "aähioöruüy" )
                lt ( true, "ft", 4, 5, "prüft+", ligs["ft"] , "aähioöruü" )
                lt ( true, "ft", 3, 4, "Ruft+", ligs["ft"] , "aäehioöruüy" )
                lt ( true, "ft", 5, 6, "Schaftal", ligs["ft"] )
                lt ( true, "ft", 5, 6, "Schaftor", ligs["ft"] )
                lt ( true, "ft", 5, 6, "Schaftreib", ligs["ft"] )
                lt ( true, "ft", 5, 6, "schaftal", ligs["ft"] )
                lt ( true, "ft", 5, 6, "schaftor", ligs["ft"] )
                lt ( true, "ft", 5, 6, "schaftreib", ligs["ft"] )
                lt ( true, "ft", 6, 7, "Schlaft", ligs["ft"] )
                lt ( true, "ft", 6, 7, "schlaft+", ligs["ft"] , "aähioöruüy" )
                lt ( true, "ft", 6, 7, "Schilft+", ligs["ft"] , "äehiruüy" )
                lt ( true, "ft", 6, 7, "schilft+", ligs["ft"] , "hiruüy" )
                lt ( true, "ft", 4, 5, "Senft+", ligs["ft"] , "aäehioöruy" )
                lt ( false, "ft", 4, 5, "Senftenberg", ligs["ft"] )
                lt ( true, "ft", 5, 6, "Straft+", ligs["ft"] , "aähioöruüy" )
                lt ( true, "ft", 5, 6, "straft+", ligs["ft"] , "aähioöruüy" )
                lt ( false, "ft", 5, 6, "straftheit", ligs["ft"] )
                lt ( true, "ft", 4, 5, "Sufft", ligs["ft"] )
                lt ( true, "ft", 4, 5, "Surft+", ligs["ft"] , "ähiöüy" )
                lt ( true, "ft", 5, 6, "Tarift", ligs["ft"] )
                lt ( true, "ft", 5, 6, "tarift", ligs["ft"] )
                lt ( true, "ft", 4, 5, "Tieft", ligs["ft"] )
                lt ( true, "ft", 4, 5, "Torft", ligs["ft"] )
                lt ( true, "ft", 4, 5, "torft", ligs["ft"] )
                lt ( true, "ft", 4, 5, "Wurft", ligs["ft"] )
                lt ( true, "ft", 4, 5, "wurft", ligs["ft"] )
                lt ( true, "ft", 2, 3, "fft+", ligs["ft"] , "aähioöruüy" )
                lt ( true, "ft", 8, 9, "Abstreiftest", ligs["ft"] )
                lt ( true, "ft", 6, 7, "Ankauftest", ligs["ft"] )
                lt ( true, "ft", 7, 8, "Hörprüftest", ligs["ft"] )
                lt ( true, "ft", 4, 5, "Hüpftest", ligs["ft"] )
                lt ( true, "ft", 4, 5, "Impftest", ligs["ft"] )
                lt ( true, "ft", 4, 5, "Kauftest", ligs["ft"] )
                lt ( true, "ft", 5, 6, "Klopftest", ligs["ft"] )
                lt ( true, "ft", 5, 6, "Kneiftest", ligs["ft"] )
                lt ( true, "ft", 12, 13, "Lichtschweiftest", ligs["ft"] )
                lt ( true, "ft", 7, 8, "Rückruftest", ligs["ft"] )
                lt ( true, "ft", 7, 8, "Schnupftest", ligs["ft"] )
                lt ( true, "ft", 5, 6, "Sumpftest", ligs["ft"] )
                lt ( true, "ft", 5, 6, "Tropftest", ligs["ft"] )
                lt ( true, "ft", 9, 10, "Wettkampftest", ligs["ft"] )
                lt ( true, "ft", 4, 5, "tofftest", ligs["ft"] )
                lt ( true, "ft", 2, 3, "aftee", ligs["ft"] )
                lt ( true, "ft", 3, 4, "auftee", ligs["ft"] )
                lt ( true, "ft", 4, 5, "lauftest", ligs["ft"] )
                lt ( true, "ft", 3, 4, "eiftie", ligs["ft"] )
                lt ( true, "ft", 3, 4, "eiftit", ligs["ft"] )
                lt ( true, "ft", 3, 4, "eiftr", ligs["ft"] )
                lt ( true, "ft", 5, 6, "elieft", ligs["ft"] )
                lt ( true, "ft", 3, 4, "enftei", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftabell", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftablett", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftafel", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftag", ligs["ft"] )
                lt ( false, "ft", 1, 2, "ftagent", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftäg", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftalsg", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftanz", ligs["ft"] )
                lt ( false, "ft", 1, 2, "ftanzahl", ligs["ft"] )
                lt ( false, "ft", 1, 2, "ftanzeig", ligs["ft"] )
                lt ( false, "ft", 1, 2, "ftanzieh", ligs["ft"] )
                lt ( false, "ft", 1, 2, "ftanzüg", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftänz", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftari", ligs["ft"] )
                lt ( false, "ft", 1, 2, "ftaristokr", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftarn", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftasse", ligs["ft"] )
                lt ( false, "ft", 1, 2, "ftassel", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftatb", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftaten", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftätig", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftauch", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftaugl", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftaume", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftax", ligs["ft"] )
                lt ( true, "ft", 1, 2, "fteam", ligs["ft"] )
                lt ( false, "ft", 1, 2, "fteamt", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftechn", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftedd", ligs["ft"] )
                lt ( true, "ft", 1, 2, "fteich", ligs["ft"] )
                lt ( false, "ft", 2, 3, "nfteich", ligs["ft"] )
                lt ( false, "ft", 2, 3, "ifteich", ligs["ft"] )
                lt ( true, "ft", 1, 2, "fteigw", ligs["ft"] )
                lt ( true, "ft", 1, 2, "fteil", ligs["ft"] )
                lt ( false, "ft", 1, 2, "fteilfr", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftelef", ligs["ft"] )
                lt ( true, "ft", 1, 2, "fteleph", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftelegr", ligs["ft"] )
                lt ( true, "ft", 1, 2, "fteller", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftempel", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftemper", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftempo", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftendenz", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftentak", ligs["ft"] )
                lt ( true, "ft", 1, 2, "fteppi", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftermin", ligs["ft"] )
                lt ( false, "ft", 1, 2, "fterminder", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftermit", ligs["ft"] )
                lt ( false, "ft", 1, 2, "ftermitt", ligs["ft"] )
                lt ( true, "ft", 1, 2, "fterrain", ligs["ft"] )
                lt ( true, "ft", 1, 2, "fterrass", ligs["ft"] )
                lt ( true, "ft", 1, 2, "fterrin", ligs["ft"] )
                lt ( true, "ft", 1, 2, "fterror", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftestat", ligs["ft"] )
                lt ( false, "ft", 1, 2, "ftestation", ligs["ft"] )
                lt ( false, "ft", 1, 2, "ftestatist", ligs["ft"] )
                lt ( true, "ft", 1, 2, "fteuf", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftext", ligs["ft"] )
                lt ( false, "ft", 1, 2, "ftextrakt", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftheat", ligs["ft"] )
                lt ( true, "ft", 1, 2, "fthem", ligs["ft"] )
                lt ( false, "ft", 1, 2, "fthemm", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftheor", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftherap", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftick", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftief", ligs["ft"] )
                lt ( false, "ft", 1, 2, "ftiefigur", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftier", ligs["ft"] )
                lt ( false, "ft", 3, 4, "haftier", ligs["ft"] )
                lt ( false, "ft", 3, 4, "Muftier", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftipp", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftirad", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftisch", ligs["ft"] )
                lt ( false, "ft", 4, 5, "stiftisch", ligs["ft"] )
                lt ( false, "ft", 3, 4, "ünftisch", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftod", ligs["ft"] )
                lt ( false, "ft", 1, 2, "ftodem", ligs["ft"] )
                lt ( true, "ft", 1, 2, "fton", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftön", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftool", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftopf", ligs["ft"] )
                lt ( false, "ft", 1, 2, "ftopfer", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftöpf", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftorig", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftour", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftrader", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftradition", ligs["ft"] )
                lt ( true, "ft", 1, 2, "fträg", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftrain", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftränk", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftransp", ligs["ft"] )
                lt ( true, "ft", 1, 2, "fträume", ligs["ft"] )
                lt ( false, "ft", 2, 3, "afträume", ligs["ft"] )
                lt ( false, "ft", 2, 3, "äfträume", ligs["ft"] )
                lt ( false, "ft", 3, 4, "rifträume", ligs["ft"] )
                lt ( false, "ft", 2, 3, "ufträume", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftrauri", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftreff", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftresor", ligs["ft"] )
                lt ( false, "ft", 1, 2, "ftresorp", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftret", ligs["ft"] )
                lt ( false, "ft", 1, 2, "ftrett", ligs["ft"] )
                lt ( false, "ft", 1, 2, "ftreturn", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftrick", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftrieb", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftrief", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftrift", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftrimest", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftritt", ligs["ft"] )
                lt ( false, "ft", 1, 2, "ftritter", ligs["ft"] )
                lt ( false, "ft", 3, 4, "Luftritt", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftrott", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftrüb", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftrunk", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftrupp", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftuch", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftüch", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftürk", ligs["ft"] )
                lt ( true, "ft", 1, 2, "fturm", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftürm", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftyp", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftyr", ligs["ft"] )
                lt ( true, "ft", 1, 2, "ftwist", ligs["ft"] )
                lt ( true, "ft", 4, 5, "graftum", ligs["ft"] )
                lt ( true, "ft", 4, 5, "graftüm", ligs["ft"] )
                lt ( true, "ft", 3, 4, "hoftest", ligs["ft"] )
                lt ( true, "ft", 3, 4, "iefta", ligs["ft"] )
                lt ( true, "ft", 3, 4, "iefto", ligs["ft"] )
                lt ( true, "ft", 3, 4, "ieftö", ligs["ft"] )
                lt ( true, "ft", 3, 4, "ieftra", ligs["ft"] )
                lt ( true, "ft", 2, 3, "lfta", ligs["ft"] )
                lt ( true, "ft", 2, 3, "lfto", ligs["ft"] )
                lt ( true, "ft", 2, 3, "lftö", ligs["ft"] )
                lt ( true, "ft", 2, 3, "lftum", ligs["ft"] )
                lt ( true, "ft", 2, 3, "nftü", ligs["ft"] )
                lt ( false, "ft", 2, 3, "nftüb", ligs["ft"] )
                lt ( true, "ft", 2, 3, "nftübchen", ligs["ft"] )
                lt ( true, "ft", 3, 4, "ölfte", ligs["ft"] )
                lt ( true, "ft", 2, 3, "pft+", ligs["ft"] , "aähioöruüy" )
                lt ( false, "ft", 2, 3, "pftheit", ligs["ft"] )
                lt ( true, "ft", 2, 3, "pftee", ligs["ft"] )
                lt ( true, "ft", 2, 3, "pfteig", ligs["ft"] )
                lt ( true, "ft", 2, 3, "pftender", ligs["ft"] )
                lt ( true, "ft", 2, 3, "rftr", ligs["ft"] )
                lt ( false, "ft", 5, 6, "tdurftrö", ligs["ft"] )
                lt ( false, "ft", 4, 5, "Werftr", ligs["ft"] )
                lt ( false, "ft", 4, 5, "werftr", ligs["ft"] )
                lt ( true, "ft", 4, 5, "werftrage", ligs["ft"] )
                lt ( true, "ft", 2, 3, "rftu", ligs["ft"] )
                lt ( false, "ft", 4, 5, "Werftu", ligs["ft"] )
                lt ( false, "ft", 4, 5, "werftu", ligs["ft"] )
                lt ( true, "ft", 2, 3, "uftas", ligs["ft"] )
                lt ( false, "ft", 3, 4, "Duftas", ligs["ft"] )
                lt ( false, "ft", 3, 4, "duftas", ligs["ft"] )
                lt ( false, "ft", 4, 5, "Gruftas", ligs["ft"] )
                lt ( false, "ft", 4, 5, "gruftas", ligs["ft"] )
                lt ( false, "ft", 3, 4, "Luftas", ligs["ft"] )
                lt ( false, "ft", 3, 4, "luftas", ligs["ft"] )
                lt ( false, "ft", 2, 3, "uftassoz", ligs["ft"] )
                lt ( true, "ft", 3, 4, "urfta", ligs["ft"] )
                lt ( false, "ft", 5, 6, "tdurfta", ligs["ft"] )
                lt ( true, "ft", 3, 4, "urfto", ligs["ft"] )
                lt ( true, "ft", 3, 4, "ünftor", ligs["ft"] )
            end
            if next ( ligs["fb"] ) then
                lt ( true, "fb", 1, 2, "fb", ligs["fb"] )
            end
            if next ( ligs["fh"] ) then
                lt ( true, "fh", 1, 2, "fh", ligs["fh"] )
            end
            if next ( ligs["fk"] ) then
                lt ( true, "fk", 1, 2, "fk", ligs["fk"] )
                lt ( false, "fk", 3, 4, "Kafka", ligs["fk"] )
                lt ( false, "fk", 3, 4, "kafka", ligs["fk"] )
                lt ( false, "fk", 4, 5, "Piefke", ligs["fk"] )
                lt ( false, "fk", 4, 5, "piefkei", ligs["fk"] )
                lt ( false, "fk", 3, 4, "Safka", ligs["fk"] )
                lt ( false, "fk", 6, 7, "Potrafke", ligs["fk"] )
                lt ( false, "fk", 5, 6, "Sprafke", ligs["fk"] )
                lt ( false, "fk", 6, 7, "Shirafkan", ligs["fk"] )
                lt ( false, "fk", 5, 6, "Tirafkan", ligs["fk"] )
                lt ( false, "fk", 4, 5, "Selfkant", ligs["fk"] )
                lt ( false, "fk", 3, 4, "Rifkin", ligs["fk"] )
            end
            if next ( ligs["fj"] ) then
                lt ( true, "fj", 1, 2, "fj", ligs["fj"] )
                lt ( false, "fj", 1, 2, "fjord", ligs["fj"] )
                lt ( false, "fj", 1, 2, "fjör", ligs["fj"] )
                lt ( false, "fj", 4, 5, "Ísafjarðarbær", ligs["fj"] )
                lt ( false, "fj", 1, 2, "fjell", ligs["fj"] )
                lt ( false, "fj", 1, 2, "fjall", ligs["fj"] )
                lt ( false, "fj", 1, 2, "fjäll", ligs["fj"] )
                lt ( false, "fj", 1, 2, "fjöll", ligs["fj"] )
                lt ( false, "fj", 6, 7, "Prokofjew", ligs["fj"] )
                lt ( false, "fj", 3, 4, "Sufjan", ligs["fj"] )
                lt ( false, "fj", 3, 4, "Eefje", ligs["fj"] )
                lt ( false, "fj", 5, 6, "Astafjew", ligs["fj"] )
            end
            if next ( ligs["fff"] ) then
                lt ( true, "ff", 2, 3, "fff", ligs["fff"] )
            end
        end
        for _, value in ipairs ( lig_table ) do
            lt ( value[1], value[2], value[3], value[4], value[5], ligs[value[2]], value[6] )
        end
    end
end

local function no_ligs ( head )
    local ligs = get_ligs ( head )
    local string_table = { "ff", "fi", "fl", "ft", "fb", "fh", "fk", "fj" }
    local lig_check = {}
    for _, value in pairs ( lig_table ) do
        lig_check[value[2]] = true
    end
    for key, value in pairs ( lig_check ) do
        if value then
            string_table[#string_table + 1] = key
        end
    end
    for _, value in pairs ( string_table ) do
        no_lig ( true, value, 1, 2, value, head, ligs[value] )
    end
end

function ligtype_write_ligs ( s )
    ATC ( "ligaturing", no_ligs, "no ligs" )
    local lig_check = {}
    for _, value in pairs ( lig_table ) do
        lig_check[value[2]] = true
    end
    local ligs_string = "ff fi fl ft fb fh fk fj"
    for key, value in pairs ( lig_check ) do
        if value and not FIND ( ligs_string, key ) then
            ligs_string = ligs_string .. " " .. key
        end
    end
    local par_end = [[\par\addvspace{\baselineskip}]]
    tex.sprint ( [[\newpage{}\pagestyle{empty}\parindent=0em{}]] .. ligs_string .. par_end .. [[\textbf{]] .. ligs_string .. [[}]] .. par_end .. [[\textit{]] .. ligs_string .. [[}]] .. par_end .. [[\textit{\textbf{]] .. ligs_string .. [[}}]] .. par_end .. [[{\sffamily{}]] .. ligs_string .. par_end .. [[\textbf{]] .. ligs_string .. [[}]] .. par_end .. [[\textit{]] .. ligs_string .. [[}]] .. par_end .. [[\textit{\textbf{]] .. ligs_string .. [[}}]] .. par_end .. [[}\newpage{}]] )
end

function ligtype_make_marks ()
    make_marks = true
    ATC ( "post_linebreak_filter", place_marks, "place marks postline" )
    ATC ( "hpack_filter", place_marks, "place marks hpack" )
end

function ligtype_on ()
    ATC ( "ligaturing", lig_parse, "make and break ligatures" )
    ATC ( "pre_linebreak_filter", make_kern, "make kerns preline" )
    ATC ( "hpack_filter", make_kern, "make kerns hpack", 2 )
end

function ligtype_off ()
    RFC ( "ligaturing", "make and break ligatures" )
    RFC ( "pre_linebreak_filter", "make kerns preline" )
    RFC ( "hpack_filter", "make kerns hpack" )
end