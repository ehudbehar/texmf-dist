-- Copyright (c) 2022 Thomas Kelkel kelkel@emaileon.de

-- This file may be distributed and/or modified under the
-- conditions of the LaTeX Project Public License, either
-- version 1.3c of this license or (at your option) any later
-- version. The latest version of this license is in

--    http://www.latex-project.org/lppl.txt

-- and version 1.3c or later is part of all distributions of
-- LaTeX version 2009/09/24 or later.

-- Version: 0.1a

local ID = node.id
local GLYPH = ID ( "glyph" )
local GLUE = ID ( "glue" )
local KERN = ID ( "kern" )
local WI = ID ( "whatsit" )
local BOUND = ID ( "boundary" )
local PENALTY = ID ( "penalty" )
local SWAPPED = table.swapped
local SUBTYPES = node.subtypes
local USERKERN = SWAPPED ( SUBTYPES ("kern") )["userkern"]
local LBPENALTY = SWAPPED ( SUBTYPES ("penalty") )["linebreakpenalty"]
local SPACESKIP = SWAPPED ( SUBTYPES ("glue") )["spaceskip"]
local NEW = node.new
local REM = node.remove
local PREV = node.prev
local NEXT = node.next
local INS_B = node.insert_before
local T_ID = node.traverse_id
local T_GLYPH = node.traverse_glyph
local WIS = node.whatsits()
local userdefined
local pairs = pairs
local FLOOR = math.floor
local GET_FONT = font.getfont
local ATC = luatexbase.add_to_callback

local no_iw_kern = false

function spacekern_no_iw_kern ()
    no_iw_kern = true
end

local function round ( num, dec )
    return FLOOR ( num * 10^dec + 0.5 ) / 10^dec
end

for key, value in pairs ( WIS ) do
    if value == "user_defined" then
        userdefined = key
    end
end

local function find_glyph ( n, d )
    if d ( n ) then
        n = d ( n )
        while n.id ~= GLYPH do
            if not d ( n ) or n.id == GLUE or n.id == BOUND or ( n.id == KERN and n.subtype == USERKERN ) then return false end
            n = d ( n )
        end
    else
        return false
    end
    return n
end

local function make_kern ( head, font, first_glyph, second_glyph, insert_point )
    local tfmdata = GET_FONT ( font )
    if tfmdata.resources then
        local resources = tfmdata.resources
        if resources.sequences then
            local seq = resources.sequences
            for _, t in pairs ( seq ) do
                if t.steps then
                    local steps = t.steps
                    for _, k in pairs ( steps ) do
                        if k.coverage then
                            local first_number = true
                            if k.coverage[first_glyph] then
                                local glyph_table = k.coverage[first_glyph]
                                if type ( glyph_table ) == "table" then
                                    for key, value in pairs ( glyph_table ) do
                                        if key == second_glyph and type ( value ) == "number" and first_number and ( k.format == "move" or tfmdata.specification.features.raw[t.name] ) then
                                            if tfmdata.specification.features.raw[t.name] then
                                                first_number = false
                                            end
                                            if PREV ( insert_point ).id == PENALTY then
                                                insert_point = PREV ( insert_point )
                                            end
                                            INS_B ( head, insert_point, NEW ( KERN ) )
                                            PREV ( insert_point ).kern = value / tfmdata.units_per_em * tfmdata.size
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

local function check_glyph ( n, d, has_prev_next_glyph, prev_next_glyph )
    if find_glyph ( n, d ) then
        prev_next_glyph = find_glyph ( n, d )
        has_prev_next_glyph = true
    end
    return has_prev_next_glyph, prev_next_glyph
end

local function make_kerns ( head, n )
    local has_prev_glyph = false
    local has_next_glyph = false
    local prev_glyph = n
    local next_glyph = n
    has_prev_glyph, prev_glyph = check_glyph ( n, PREV, has_prev_glyph, prev_glyph )
    has_next_glyph, next_glyph = check_glyph ( n, NEXT, has_next_glyph, next_glyph )
    if has_prev_glyph and prev_glyph.char and prev_glyph.font then
        make_kern ( head, prev_glyph.font, prev_glyph.char, 32, n )
    end
    if has_next_glyph and next_glyph.char and next_glyph.font then
        make_kern ( head, next_glyph.font, 32, next_glyph.char, n )
    end
    if not no_iw_kern and has_prev_glyph and has_next_glyph and prev_glyph.char and next_glyph.char and prev_glyph.font and next_glyph.font and ( prev_glyph.font == next_glyph.font ) then
        make_kern ( head, prev_glyph.font, prev_glyph.char, next_glyph.char, n )
    end
end

local function make_glues_and_kerns ( head )
    for n in T_ID ( GLUE, head ) do
        make_kerns ( head, n )
    end
    for n in T_GLYPH ( head ) do
        if n.char and n.char == 59 and ( not find_glyph ( n, PREV ) or find_glyph ( n, PREV ).char ~= 59 ) then
            if find_glyph ( n, NEXT ) then
                local next_glyph = n
                next_glyph = find_glyph ( n, NEXT )
                if next_glyph.char and next_glyph.char == 59 then
                    REM ( head, next_glyph )
                    local SIZE = 0
                    if n.font then
                        local tfmdata = GET_FONT ( n.font )
                        if tfmdata.size then
                            SIZE = tfmdata.size
                        end
                    end
                    INS_B ( head, n, NEW ( GLUE ) )
                    local glue_node = PREV ( n )
                    glue_node.subtype = SPACESKIP
                    glue_node.width = round ( SIZE * .16667, 0 )
                    local has_next_glyph = false
                    if find_glyph ( n, NEXT ) then
                        next_glyph = find_glyph ( n, NEXT )
                        has_next_glyph = true
                    end
                    if has_next_glyph and next_glyph.char and next_glyph.char == 59 then
                        INS_B ( head, glue_node, NEW ( PENALTY ) )
                        PREV ( glue_node ).subtype = LBPENALTY
                        PREV ( glue_node ).penalty = 10000
                        REM ( head, next_glyph )
                    end
                    REM ( head, n )
                    make_kerns ( head, glue_node )
                end
            end
        end
    end
end

ATC ( "ligaturing", make_glues_and_kerns, "kern between words and against space", 1 )