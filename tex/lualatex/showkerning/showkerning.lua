-- Copyright (c) 2022 Thomas Kelkel kelkel@emaileon.de

-- This file may be distributed and/or modified under the
-- conditions of the LaTeX Project Public License, either
-- version 1.3c of this license or (at your option) any later
-- version. The latest version of this license is in

--    http://www.latex-project.org/lppl.txt

-- and version 1.3c or later is part of all distributions of
-- LaTeX version 2009/09/24 or later.

-- Version: 0.1

local FLOOR = math.floor
local ABS = math.abs

local function round ( num, dec )
    return FLOOR ( num * 10^dec + 0.5 ) / 10^dec
end

local ID = node.id
local GLYPH = ID ( "glyph" )
local DISC = ID ( "disc" )
local KERN = ID ( "kern" )
local GLUE = ID ( "glue" )
local BOUND = ID ( "boundary" )
local WI = ID ( "whatsit" )
local HLIST = ID ( "hlist" )
local VLIST = ID ( "vlist" )
local USERKERN = table.swapped ( node.subtypes ("kern") )["userkern"]
local NEW = node.new
local COPY = node.copy
local REM = node.remove
local PREV = node.prev
local NEXT = node.next
local TAIL = node.tail
local HAS_GLYPH = node.has_glyph
local INS_B = node.insert_before
local INS_A = node.insert_after
local T = node.traverse
local T_ID = node.traverse_id
local T_GLYPH = node.traverse_glyph
local WIS = node.whatsits()
local pdfliteral
local pairs = pairs
local ATC = luatexbase.add_to_callback

local on_top = false
local DIR = PREV
local AB = INS_B
local f = 1

for key, value in pairs ( WIS ) do
    if value == "pdf_literal" then
        pdfliteral = key
    end
end

function showkerning_on_top ()
    on_top = true
    DIR = NEXT
    AB = INS_A
    f = - 1
end

local function calc_value ( value )
    value = round ( value / 65536, 3 )
    return value
end

local function find_glyph ( n, d )
    if d ( n ) then
        n = d ( n )
        while n.id ~= GLYPH and not ( n.id == DISC and n.replace and HAS_GLYPH ( n.replace ) ) do
            if not d ( n ) or n.id == GLUE or n.id == BOUND or ( n.id == KERN and n.subtype == USERKERN ) then return false end
            n = d ( n )
        end
    else
        return false
    end
    local return_value = n
    if n.id == DISC then
        for glyph_node in T_GLYPH ( n.replace ) do
            return_value = glyph_node
        end
    end
    return return_value, n
end

local function check_glyph ( n, d, has_prev_next_glyph, prev_next_glyph, insert_prev_next )
    if find_glyph ( n, d ) then
        prev_next_glyph, insert_prev_next = find_glyph ( n, d )
        has_prev_next_glyph = true
    end
    return has_prev_next_glyph, prev_next_glyph, insert_prev_next
end

local function get_x_value ( n, x_value )
    local exp_fac = 1
    if n.expansion_factor then
        exp_fac = n.expansion_factor / 1000000 + 1
    end
    if n.id == GLYPH and n.width then
        x_value = x_value + calc_value ( n.width ) * exp_fac
    elseif n.id == KERN and n.kern then
        x_value = x_value + calc_value ( n.kern ) * exp_fac
    end
    return x_value
end

local function make_rule ( head, n, kern_node, current_head, disc_list )
    local color = "0 0 0"
    local has_prev_glyph = false
    local has_next_glyph = false
    local prev_glyph = n
    local next_glyph = n
    local insert_prev = n
    local insert_next = n
    local insert_point = n
    local x_value = 0
    local height = 0
    local depth = 0
    local thickness = calc_value ( kern_node.kern )
    has_prev_glyph, prev_glyph, insert_prev = check_glyph ( n, PREV, has_prev_glyph, prev_glyph, insert_prev )
    has_next_glyph, next_glyph, insert_next = check_glyph ( n, NEXT, has_next_glyph, next_glyph, insert_next )
    if not on_top and has_prev_glyph then
        insert_point = insert_prev
        x_value = get_x_value ( prev_glyph, x_value )
        if disc_list and HAS_GLYPH ( current_head ) and TAIL ( current_head ) == kern_node then
            for some_node in T ( current_head ) do
                if some_node == TAIL ( current_head ) then break end
                x_value = get_x_value ( some_node, x_value )
            end
        end
    elseif on_top and has_next_glyph then
        insert_point = insert_next
        x_value = get_x_value ( next_glyph, x_value )
        if disc_list and HAS_GLYPH ( current_head ) and current_head == kern_node then
            for some_node in T ( current_head ) do
                if some_node ~= current_head then
                    x_value = get_x_value ( some_node, x_value )
                end
            end
        end
    end
    if disc_list and HAS_GLYPH ( current_head ) then
        if TAIL ( current_head ) == kern_node then
            has_prev_glyph = false
            has_prev_glyph, prev_glyph = check_glyph ( kern_node, PREV, has_prev_glyph, prev_glyph, insert_prev )
        end
        if current_head == kern_node then
            has_next_glyph = false
            has_next_glyph, next_glyph = check_glyph ( kern_node, NEXT, has_next_glyph, next_glyph, insert_next )
        end
    end
    if has_prev_glyph then
        height = calc_value ( prev_glyph.height )
        depth = calc_value ( prev_glyph.depth )
        if has_next_glyph then
            if next_glyph.height > prev_glyph.height then height = calc_value ( next_glyph.height ) end
            if next_glyph.depth > prev_glyph.depth then depth = calc_value ( next_glyph.depth ) end
        end
    elseif has_next_glyph then
        height = calc_value ( next_glyph.height )
        depth = calc_value ( next_glyph.depth )
    end
    if PREV ( kern_node ) and PREV ( kern_node ).id == KERN then
        thickness = get_x_value ( PREV ( kern_node ), thickness )
        if PREV ( PREV ( kern_node ) ) and PREV ( PREV ( kern_node ) ).id == KERN then
            thickness = get_x_value ( PREV ( PREV ( kern_node ) ), thickness )
        end
    end
    if ( thickness ~= 0 ) and ( thickness > calc_value ( tex.hsize ) * - 1 ) then
        head = AB ( head, insert_point, NEW ( WI, pdfliteral ) )
        if thickness > 0 then
            color = "0 1 0"
        else
            color = "1 0 0"
        end
        x_value = ( x_value + calc_value ( kern_node.expansion_factor ) + thickness * 0.5 ) * f
        DIR ( insert_point ).mode = 0
        DIR ( insert_point ).data = "q " .. ABS ( thickness )  .. " w " .. x_value .. " " .. - depth  .. " m  " .. x_value .. " " .. height .. " l " .. color .. " RG S Q"
    end
    return head, current_head
end

local function show_kerns ( head )
    for n in T ( head ) do
        if n.id == HLIST or n.id == VLIST then
            n.head = show_kerns ( n.head )
        elseif n.id == KERN and not ( NEXT ( n ) and NEXT ( n ).id == KERN ) then
            head = make_rule ( head, n, n, head, false )
        elseif n.replace then
            local REPLACE = n.replace
            for kern_node in T_ID ( KERN, REPLACE ) do
                if not ( n.subtype == USERKERN ) and not ( NEXT ( kern_node ) and NEXT ( kern_node ).id == KERN ) then
                    head, REPLACE = make_rule ( head , n, kern_node, REPLACE, true )
                end
            end
            n.replace = REPLACE
        end
    end
    return head
end

ATC ( "post_linebreak_filter", show_kerns, "show kerns in postline" )
ATC ( "hpack_filter", show_kerns, "show kerns in hpack" )