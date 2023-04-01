-----------------------------------------------------------------------
--         FILE:  xindex-cfg-common.lua
--  DESCRIPTION:  configuration file for xindex.lua
-- REQUIREMENTS:  
--       AUTHOR:  Herbert Voß
--      LICENSE:  LPPL1.3
--
-- $Id: xindex-cfg-common.lua 22 2022-02-07 12:18:15Z hvoss $
-----------------------------------------------------------------------

if not modules then modules = { } end modules ['xindex-cfg-common'] = {
      version = 0.47,
      comment = "configuration to xindex.lua",
       author = "Herbert Voss",
    copyright = "Herbert Voss",
      license = "LPPL 1.3"
}

indexheader = { 
  cs = {"Symboly", "Čísla", "czech"},
  da = {"Symboler", "Tal", "danish"},
  de = {"Symbole", "Zahlen", "austrian", "german", "germanb", "ngerman", "naustrian"},
  en = {"Symbols", "Numbers", "english", "USenglish", "american", "UKenglish", "british", "canadian", "australian", "newzealand"},
  es = {"Símbolos", "Números", "spanish"},
  fr = {"Symboles","Nombres", "french", "francais", "canadien", "acadian"},
  it = {"Simboli", "Numeri", "italian"},
  jp = {"シンボル","番号", "japanese"},
  nl = {"Symbolen", "Nummers", "dutch"},
  no = {"Symboler","Tall", "norsk", "nynorsk"},
  ru = {"Символы", "Числа", "russian"}, 
}

--[[   babel
afrikaans
azerbaijani 
basque
breton
bulgarian
catalan
croatian
czech
danish
dutch
english, USenglish, american, UKenglish, british, canadian, australian, newzealand
esperanto
estonian
finnish
french, francais, canadien, acadian
galician
austrian, german, germanb, ngerman, naustrian
greek, polutonikogreek
hebrew
icelandic
indonesian (bahasa, indon, bahasai) 
interlingua
irish
italian
latin
lowersorbian
malay, melayu (bahasam)
samin
norsk, nynorsk
polish
portuguese
brazilian (portuges, brazil)
romanian
russian
scottish
spanish
slovak
slovene
swedish
serbian
turkish
ukrainian
uppersorbian
welsh
]]


folium = { 
  cs = {"f.", "ff."},
  da = {"f", "ff"},
  de = {"f", "ff"},
  en = {"f", "ff"},
  es = {"f", "ff"},
  fr = {"\\,sq.","\\,sqq."},
  it = {"f", "ff"},
  jp = {"シンボル","番号"},
  nl = {"f.", "ff."},
  no = {"\\,f.","\\,ff."},
  ru = {"",""},       -- doesn't exist
}

alphabet_uppercase = {
    { 'α', 'Α' },
    { 'β', 'Β' },
    { 'ϐ', 'ϐ' },   
    { 'γ', 'Γ' },
    { 'δ', 'Δ' },
    { 'ε', 'Ε' },
    { 'ζ', 'Ζ' },
    { 'η', 'Η' },
    { 'θ', 'Θ' },
    { 'ι', 'Ι' },
    { 'κ', 'Κ' },
    { 'λ', 'Λ' },
    { 'μ', 'Μ' },
    { 'ν', 'Ν' },
    { 'ξ', 'Ξ' },
    { 'ο', 'Ο' },
    { 'π', 'Π' },
    { 'ρ', 'Ρ' },
    { 'σ', 'Σ' },
    { 'ς', 'ς' },
    { 'τ', 'Τ' },
    { 'υ', 'Υ' },
    { 'φ', 'Φ' },
    { 'χ', 'Χ' },
    { 'ψ', 'Ψ' },
    { 'ω', 'Ω' },
--
    { 'a', 'A' },
    { 'b', 'B' },
    { 'c', 'C' },
    { 'd', 'D' },
    { 'e', 'E' },
    { 'f', 'F' },
    { 'g', 'G' },
    { 'h', 'H' },
    { 'i', 'I' },
    { 'j', 'J' },
    { 'k', 'K' },
    { 'l', 'L' },
    { 'm', 'M' },
    { 'n', 'N' },
    { 'o', 'O' },
    { 'p', 'P' },
    { 'q', 'Q' },
    { 'r', 'R' },
    { 's', 'S' },
    { 't', 'T' },
    { 'u', 'U' },
    { 'v', 'V' },
    { 'w', 'W' },
    { 'x', 'X' },
    { 'y', 'Y' },
    { 'z', 'Z' },
--
    { 'а', 'А' },
    { 'б', 'Б' },
    { 'в', 'В' },
    { 'г', 'Г' },
    { 'д', 'Д' },
    { 'е', 'Е' },
    { 'ж', 'Ж' },
    { 'з', 'З' },
    { 'и', 'И' },
    { 'й', 'Й' },
    { 'к', 'К' },
    { 'л', 'Л' },
    { 'м', 'М' },
    { 'н', 'Н' },
    { 'о', 'О' },
    { 'п', 'П' },
    { 'р', 'Р' },
    { 'с', 'С' },
    { 'т', 'Т' },
    { 'у', 'У' },
    { 'ф', 'Ф' },
    { 'х', 'Х' },
    { 'ц', 'Ц' },
    { 'ч', 'Ч' },
    { 'ш', 'Ш' },
    { 'щ', 'Щ' },
    { 'ъ', 'Ъ' },
    { 'ы', 'Ы' },
    { 'ь', 'Ь' },
    { 'э', 'Э' },
    { 'ю', 'Ю' },
    { 'я', 'Я' }
}

local function create_map(char_list)
  local map = {}
  for i, pair in ipairs(char_list) do
    map[pair[1]] = pair[2]
  end
  return map
end

alphabet_uppercase_map = create_map(alphabet_uppercase)

