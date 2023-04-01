NAME  = ekdosis
SHELL = bash
CMP   = lualatex-dev
PWD   = $(shell pwd)
VERS  = $(shell ltxfileinfo -v $(NAME).dtx|sed -e 's/^v//')
LOCAL = $(shell kpsewhich --var-value TEXMFLOCAL)
UTREE = $(shell kpsewhich --var-value TEXMFHOME)
HOMEDIR := $$HOME
SAMPLES := samples

exts := md html ins dtx el
findopts := $(foreach ext,$(exts),-or -iname "*.$(ext)")

define do_documentation
	$(CMP) --shell-escape --recorder --interaction=nonstopmode $(NAME).dtx >/dev/null
endef

all:	sty $(NAME).pdf

testsamples:
	if [ ! -d $(SAMPLES) ] ; \
	then echo "$(SAMPLES)/ directory is needed. Aborting." && exit 1 ; \
	fi

sty: clean
	$(CMP) $(NAME).ins >/dev/null

$(NAME).pdf: testsamples $(NAME).dtx
	@ echo "Making the sample files first..."
	@ $(MAKE) --directory=$(SAMPLES) >/dev/null
	@ echo "Done making samples"
	@ echo "Building the documentation of $(NAME) with $(CMP). Please be patient..."
	@ $(do_documentation)
	@ echo "Now calling biber"
	@ biber $(NAME) >/dev/null
	@ echo "Returning to $(CMP)..."
	@ for run in {1..4}; do $(do_documentation); done
	@ echo "Building indexes..."
	@ if [ -f $(NAME).glo ]; then makeindex -q -s gglo.ist -o $(NAME).gls $(NAME).glo; fi
	@ if [ -f $(NAME).idx ]; then makeindex -q -s gind.ist -o $(NAME).ind $(NAME).idx; fi
	@ echo "Final runs of $(CMP)..."
	@ for run in {1..7}; do $(do_documentation); done
	@ echo "Done"

samples: clean sty
	$(MAKE) --directory=$(SAMPLES)

clean: testsamples
	@ echo "Cleaning $(NAME) directory"
	rm -rf auto
	rm -f $(NAME).bib $(PWD)/TMP/*.bib
	rm -rf .backup
	find -iname "*~" -or -iname "*.pdf" -or -iname "*_out*.tex" | xargs rm -rf
	find ./* -type f -iname "Makefile" $(findopts) > ls-R
	find ./* -type f -iname "*.tex" | grep '/samples/' >> ls-R
	rsync -aPr --files-from=ls-R . .backup
	rm -rf *
	cp -p -r .backup/* .
	rm -rf .backup

pandoc:
	pandoc -s README.md -o about.html

auctex:
	if [ ! -d "$(HOMEDIR)/.emacs.d/auctex/auto" ]; then \
	mkdir -p $(HOMEDIR)/.emacs.d/auctex/auto; \
	fi
	cp $(NAME)*.el $(HOMEDIR)/.emacs.d/auctex/auto

distclean: clean uninst

uninst:
	rm -rf $(UTREE)/{tex,source,doc}/lualatex/$(NAME)
	rm -rf $(HOMEDIR)/.emacs.d/auctex/auto/$(NAME).{el,elc}

inst: uninst auctex all
	@ echo "Installing $(NAME) locally"
	mkdir -p $(UTREE)/{tex,source,doc}/lualatex/$(NAME)
	cp $(NAME).dtx $(UTREE)/source/lualatex/$(NAME)
	cp $(NAME).sty $(UTREE)/tex/lualatex/$(NAME)
	cp $(NAME).lua $(UTREE)/tex/lualatex/$(NAME)
	cp $(NAME).pdf $(UTREE)/doc/lualatex/$(NAME)
	cp -r samples/ $(UTREE)/doc/lualatex/$(NAME)
	@ echo "Installation complete. Happy TeXing!"

local: uninst auctex
	$(CMP) $(NAME).ins
	mkdir -p $(UTREE)/{tex,source,doc}/lualatex/$(NAME)
	cp $(NAME).sty $(UTREE)/tex/lualatex/$(NAME)
	cp $(NAME).lua $(UTREE)/tex/lualatex/$(NAME)
	if [ -e "$(NAME).pdf" ]; then cp $(NAME).pdf $(UTREE)/doc/lualatex/$(NAME) &&\
	cp -r $(SAMPLES)/ $(UTREE)/doc/lualatex/$(NAME); fi

install: all
	sudo mkdir -p $(LOCAL)/{tex,source,doc}/latex/$(NAME)
	sudo cp $(NAME).dtx $(LOCAL)/source/latex/$(NAME)
	sudo cp $(NAME).sty $(LOCAL)/tex/latex/$(NAME)
	sudo cp $(NAME).pdf $(LOCAL)/doc/latex/$(NAME)
	cp -r $(SAMPLES)/ $(LOCAL)/doc/latex/$(NAME)

uninstall:
	rm -rf $(LOCAL)/{tex,source,doc}/latex/$(NAME)

zip: all
	ln -sf . $(NAME)
	zip -Drq $(PWD)/$(NAME)-$(VERS).zip $(NAME)/{samples,README.md,$(NAME).{pdf,sty,lua,el}}
	rm $(NAME)

package: distclean all
	mkdir $(NAME)/
	cp Makefile README.md $(NAME).{ins,dtx,pdf,el} $(NAME)/
	cp -r samples/ $(NAME)/
	mkdir -p tex/lualatex/$(NAME)/
	cp *.lua *.sty tex/lualatex/$(NAME)/
	mkdir -p doc/lualatex/$(NAME)/
	cp README.md *.el *.pdf doc/lualatex/$(NAME)/
	cp -r samples/ doc/lualatex/$(NAME)/
	mkdir -p source/lualatex/$(NAME)/
	cp Makefile *.ins *.dtx source/lualatex/$(NAME)/
	zip -r $(NAME).tds.zip tex doc source
	rm -rf tex/ source/ doc/
	tar czf $(NAME)-$(VERS).tar.gz $(NAME).tds.zip $(NAME)/
	rm -rf $(NAME)/

.SILENT: testsamples
.PHONY: all clean distclean pandoc inst local uninst install uninstall zip package samples testsamples
