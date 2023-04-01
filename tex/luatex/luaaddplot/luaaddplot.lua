-- File 'luaaddplot.lua', generated from luaaddplot.dtx'.
--[[
%%
%% luaaddplot.dtx
%% Copyright 2022 Reinhard Kotucha <reinhard.kotucha@gmx.net>
%%
%% This work may be distributed and/or modified under the
%% conditions of the LaTeX Project Public License, either version 1.3
%% of this license or (at your option) any later version.
%% The latest version of this license is in
%%   http://www.latex-project.org/lppl.txt
%% and version 1.3 or later is part of all distributions of LaTeX
%% version 2005/12/01 or later.
%%
%% This work has the LPPL maintenance status `maintained'.
%%
%% The Current Maintainer of this work is Reinhard Kotucha.
%%
%% This work consists of the files luaaddplot.dtx and luaaddplot.ins
%% and the derived files luaaddplot.tex, luaaddplot.sty, and luaaddplot.lua.
--]]

module('luaaddplot', package.seeall)

function readfile (file, lambda)
  if not lfs.isfile(file) then
    error('\nERROR: File "'..file..'" not found.')
  end

  local data = io.open(file)

  for line in data:lines() do
    line = line:gsub('^%s+', '')
    if line:match('^%-?%.?[0-9]') then
      line = line:gsub('[\t:;,]', ' ')
      local a, b
      local cols = line:explode (' +')
      for i, col in ipairs(cols) do
        cols[i] = tonumber(cols[i])
      end

      if lambda then
        a, b = lambda(cols)
        if a and b then
          tex.print(string.format('%g %g', a, b))
        end
      else
        tex.print(string.format('%g %g', cols[1], cols[2]))
      end
    end
  end
  tex.print('};')
  data:close()
end

function opts (s)
  tex.print('\\addplot'..s..' table {')
end


