#Copyright (C) 2020 by Charles P. Schaum <charles[dot]schaum@comcast.net>
#-------------------------------------------------------
#
#This file may be distributed and/or modified under the
#conditions of the LaTeX Project Public License, either version 1.3
#of this license or (at your option) any later version.
#The latest version of this license is in:
#
#   http://www.latex-project.org/lppl.txt
#
#and version 1.3 or later is part of all distributions of LaTeX 
#version 2005/12/01 or later.
#
# Name of package
NAME  = schemata
# LaTeX engine to use for package; below is the default.
# One can choose from latex, pdflatex, xelatex, lualatex, dvilualatex.
ENGINE ?= pdflatex
# Engine to use for test; below is the default.
TESTENGINE ?= pdftex
# Shell to use; default is bash
SHELL = bash
# Value of current working directory
PWD   = $(shell pwd)
# Package version info
VERS  = $(shell ltxfileinfo -v $(NAME).dtx|sed -e 's/^v//')
# Local, system-wide tex tree
LOCAL = $(shell kpsewhich --var-value TEXMFLOCAL)
# Tex tree in user's home directory
UTREE = $(shell kpsewhich --var-value TEXMFHOME)
#
# Default make target is release and its dependencies
release:    $(NAME).pdf
#
# The testing target also compiles the examples file.
testing:    $(NAME).pdf schematest.pdf
#
# This is the recipe for schematest.pdf. It will work also for dvi output.
schematest.pdf : schematest.tex
	$(TESTENGINE) --interaction=nonstopmode schematest > /dev/null
	if [ -f schematest.dvi ]; then dvipdf schematest; fi
	if [ -f schematest.out.ps ]; then rm schematest.out.ps; fi
#
# This is the recipe for the package docs. It will work also for dvi output.
$(NAME).pdf : $(NAME).dtx schemata.sty schemata.ins
	$(ENGINE) -shell-escape -recorder -interaction=batchmode $(NAME).dtx >/dev/null
	$(ENGINE) --recorder --interaction=nonstopmode $(NAME).dtx > /dev/null
	if [ -f $(NAME).glo ]; then makeindex -q -s gglo.ist -o $(NAME).gls $(NAME).glo; fi
	if [ -f $(NAME).idx ]; then makeindex -q -s gind.ist -o $(NAME).ind $(NAME).idx; fi
	$(ENGINE) --recorder --interaction=nonstopmode $(NAME).dtx > /dev/null
	$(ENGINE) --recorder --interaction=nonstopmode $(NAME).dtx > /dev/null
	if [ -f $(NAME).dvi ]; then dvipdf $(NAME); fi
#
# These are the recipes for all the files that need to be extracted
# from the dtx file. Any one of them simply extracts the following:
# README.md, schemata.ins, schemata.sty, schematest.tex
#
# Once any one of these recipes is run, the rest will be satisfied.
# But they need to be there for dependencies to work best.
README.md : $(NAME).dtx
	pdftex $(NAME).dtx

schemata.ins : $(NAME).dtx
	pdftex $(NAME).dtx

schemata.sty : $(NAME).dtx
	pdftex $(NAME).dtx

schematest.tex : $(NAME).dtx
	pdftex $(NAME).dtx
#
# Using this recipe deletes the auxiliary and log files
clean:
	rm -f $(NAME).{aux,fls,glo,gls,hd,idx,ilg,ind,ins,log,out,toc}
	rm -f schematest.{aux,fls,glo,gls,hd,idx,ilg,ind,ins,log,out,toc}
#
# Using this recipe cleans also all generated files
distclean: clean
	rm -f $(NAME).{dvi,pdf,sty,synctex.gz,"synctex(busy)"} README.md
	rm -f schematest.{dvi,pdf,synctex.gz,"synctex(busy)",tex}
	rm -f schemata-eps-converted-to.pdf
#
# Using this recipe deletes files for testong
testclean:
	rm -f schematest.{aux,fls,glo,gls,hd,idx,ilg,ind,ins,log,out,toc}
	rm -f schematest.{dvi,pdf,synctex.gz,"synctex(busy)"}
#
# This recipe installs the package release into the user's tree
inst: release
	mkdir -p $(UTREE)/{tex,source,doc}/generic/$(NAME)
	cp $(NAME).dtx $(UTREE)/source/generic/$(NAME)
	cp $(NAME).eps $(UTREE)/source/generic/$(NAME)
	cp Makefile $(UTREE)/source/generic/$(NAME)
	cp $(NAME).sty $(UTREE)/tex/generic/$(NAME)
	cp $(NAME).pdf $(UTREE)/doc/generic/$(NAME)
	cp schematest.tex $(UTREE)/doc/generic/$(NAME)
	cp README.md $(UTREE)/doc/generic/$(NAME)
#
# This recipe installs the package release into the system tree
install: release
	sudo mkdir -p $(LOCAL)/{tex,source,doc}/generic/$(NAME)
	sudo cp $(NAME).dtx $(LOCAL)/source/generic/$(NAME)
	sudo cp $(NAME).eps $(LOCAL)/source/generic/$(NAME)
	sudo cp Makefile $(LOCAL)/source/generic/$(NAME)
	sudo cp $(NAME).sty $(LOCAL)/tex/generic/$(NAME)
	sudo cp $(NAME).pdf $(LOCAL)/doc/generic/$(NAME)
	sudo cp schematest.tex $(LOCAL)/doc/generic/$(NAME)
	sudo cp README.md $(LOCAL)/doc/generic/$(NAME)
#
# This recipe creates a zip file for upload to CTAN
zip: release
	ln -sf . $(NAME)
	zip -Drq $(PWD)/$(NAME)-$(VERS).zip \
$(NAME)/{README.md,Makefile,$(NAME).{pdf,dtx,eps}}
	rm $(NAME)
