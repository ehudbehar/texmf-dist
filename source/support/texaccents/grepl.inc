* Function GREPL
* replaces all the items in SET1 with all the items in SET2
* SET1/2 must have the form "ITEM ITEM ITEM " -- space at the end
* guido.milanese@unicatt.it
* requires "repl.inc"
*   31.07.2022
#################################################################
# MIT License -  Copyright (c) 2022 Guido Milanese
# See file LICENSE in this package
#################################################################
            define("grepl(Pass,Set1,Set2)datum,I,N,T1,T2,A1,A2") 
-include "repl.inc"
				:(grepl_end)
grepl		
grepl_bg	
				T1 = TABLE()
				T2 = TABLE()	
				N = 0
grepl1		N = N + 1	
				Set1 ? break(' ') . datum len(1) rem . Set1 :f(grepl1_nd)
				T1[N] = datum :(grepl1)
grepl1_nd
				
				N = 0
grepl2		N = N + 1	
				Set2 ? break(' ') . datum len(1) rem . Set2 :f(grepl2_nd)
				T2[N] = datum :(grepl2)
grepl2_nd		
				A1 = convert(T1,"ARRAY")
				A2 = convert(T2,"ARRAY")
grepl3_bg			I = I + 1
				Pass = repl(Pass,A1[I,2],A2[I,2]) :S(grepl3_bg)F(grepl3_nd)
grepl3_nd		
grepl_rt     grepl = Pass           :(return)
grepl_end

*********************************************************************
*  This function, as Phil Budne's "repl", replaces string/string
*     but, as standard "replace", can replace a set with another set.
* In this way also Unicode chars can be replaced with no limitation
*     since they are treated as strings.
*	Text = "aiuole" 
*	S1   = "a e i o u "
*	S2   = "1 2 3 4 5 "
*	Text2 = grepl(Text,S1,S2)
*	will output: "1354l2"
*  But also:
*  Text = "aiuole"
*	S1   = "a e i o u "
*	S2   = "ā ē ī ō ū "
*	will output: "āīūōlē"
*  the standard REPLACE ("aeiou" / "āēīōū") will fail
*  because Unicode chars (>127 ASCII) do not have the same length of chars <127.
* Step by step:
* create two tables for sets: T1 and T2
* feed the tables scanning thes two sets (items must be separeted by spaces)
* convert from tables to arrays
* use REPL converting string/string in PASS: 
*     each item of SET1 is replaced by the corresponding item in S2
* if SET2 is shorter the exceeding item in SET1 is left unchanged
* if SET1 is shorter the exceeding item in SET2 is not used
* Please notice that separating items by spaces makes it possible to substitute
* also sets of strings, such as e.g. LaTeX accents.
