# $Id: Makefile 1296 2023-02-12 22:24:09Z karl $
# This file is public domain.  Originally written 2010, Karl Berry.
# Assumes GNU make.

# todo: look for xx below, among much more.

SHELL = /bin/sh

# setting PATH as it's nice to find our own (development) scripts,
# e.g., look for xmlint and vcss in ./extra-bin.
extra_bin = ./extra-bin
ht_bin = ../bin/ht/unix
PATH := $(shell echo $$PATH)
#
# per-user addition to PATH. We need to use LaTeX out of current TeX Live,
# since changes that affect tex4ht are often made. If set, include trailing :.
user_bin :=
#
export PATH := $(ht_bin):$(extra_bin):$(user_bin)$(PATH)

homedir ?= tex4ht.dir
wd = work.dir
htmldir = html.dir
xtpipesdir = xtpipes.dir
deriveddir = derived.dir
texmf_t4ht_bin = texmf/tex4ht/bin
# List of directories we'll substitute into tex4ht-dir.tex below:
dirs = homedir wd htmldir xtpipesdir deriveddir texmf_t4ht_bin

# do_java variable to control how tex4ht.jar is built.
# 0 = in Makefile only
# 1 = in .tex only
# 2 = no java compilation
#
# do_java=1 works only if tex4ht-dir.tex is not already built with
#           the do_java=0 option.
# do_java=0 will keep java compilation in tex in addition to
#           building in Makefile if tex4ht-dir.tex was already built
#	    with do_java=1
do_java ?= 2
java_in_make := false
java_in_tex := false
ifeq ($(do_java),0)
java_in_make := true
else ifeq ($(do_java),1)
java_in_tex := true
else ifneq ($(do_java),2)
$(error Invalid do_java, supported values are 0, 1, and 2)
endif

# The xtpipes.jar is an intermediate product that is needed only when
# java compilation is made through t4ht system call (do_java=1), not
# when the java compilation is made in Makefile (do_java=0)
ifeq ($(java_in_tex),true)
xtpipe_jar = $(wd)/bin/xtpipes.jar
else
xtpipe_jar = #
endif

tex_opts = --interaction=nonstopmode -recorder #--file-line-error
tex_1opt = "$(tex_opts)" # must be quoted, passing to shell script
dev_null = </dev/null    # when we don't call tex directly.

HTTEX = ht "etex $(tex_opts)"  # set tex options for plain tex

# Although many of the source files say to use xhlatex, we always use
# htlatex instead. xhlatex generates XHTML from the literate source and
# then validates each (sub)file with xmllint (as defined in tex4ht.env),
# which is hundreds of calls, none of which we care about. It's fine for
# us to just generate regular HTML, in the unlikely event of wanting to
# look at those generated files anyway.

default: all

# tex4ht.sty is read by most (all?) files, but we have to avoid
# depending on it for the file which generates it (tex4ht-sty.tex), so
# we need two different variables.
# 
common_no_tex4ht_sty = tex4ht-cpright.tex common.tex common-code.tex \
  ProTex.sty AlProTex.sty tex4ht-dir.tex
common = tex4ht.sty $(common_no_cond_sty)
common_info = $(common) common-info.tex
#
# mktex4ht.4ht is read by almost everything, but since it is mostly just
# the list of packages, it changes often, without any particular need to
# rebuild everything when it does. So leave it out.

# Substitute directories used, especially for Java.
tex4ht-dir.tex: tex4ht-dir.m4
	m4 $(foreach def,$(dirs) java_in_tex,-D $(def)="$($(def))") $< >$@ || rm -f $@

# Start long list of generated files from the literate sources. Needs more.
derived = 

derived += $(tex4ht_cond4ht_derived)
tex4ht_cond4ht_derived = cond4ht.4ht mktex4ht.4ht
derived += $(tex4ht_4ht_derived)
tex4ht_4ht_derived = \
  abstract.4ht adjustbox.4ht algorithmic.4ht amsmath.4ht \
	animate.4ht authblk.4ht appendix.4ht \
  biblatex.4ht biblatex-chicago.4ht book.4ht bussproofs.4ht \
  caption.4ht cleveref.4ht color.4ht colortbl.4ht csbulletin.4ht \
  fontspec.4ht fontspec-4ht.lua fontspec-luatex.4ht fontspec-xetex.4ht \
    footmisc.4ht framed.4ht frenchb.4ht floatpag.4ht \
  geometry.4ht graphics.4ht graphicx.4ht \
  hyperref.4ht hyperxmp.4ht \
  imakeidx.4ht \
  jurabib.4ht \
  latex.4ht lettrine.4ht listings.4ht longtable.4ht \
     ltugboat.4ht ltugboat-a.4ht ltugproc.4ht ltugproc-a.4ht \
  magyar.4ht mdframed.4ht memoir.4ht minted.4ht multicol.4ht multirow.4ht \
  nameref.4ht natbib.4ht \
  parallel.4ht proof.4ht pstricks.4ht pythontex.4ht \
  quoting.4ht \
  reading.4ht \
  scrartcl.4ht scrbook.4ht scrreprt.4ht scrjura.4ht sectionbreak.4ht \
    skak.4ht spanish.4ht subscript.4ht svg.4ht \
  tabu.4ht tcolorbox.4ht texpower.4ht titlesec.4ht tocloft.4ht \
    tuenc-luatex.4ht tuenc-xetex.4ht \
    tugboat.4ht \
  usepackage.4ht usepackage-fontspec.4ht \
  wrapfig.4ht \
  xcolor.4ht xr.4ht xr-hyper.4ht 
# xx and many, many more.

derived += $(tex4ht_bibtex2_derived)
tex4ht_bibtex2_derived = bibtex2.4ht

derived += $(tex4ht_c_derived)
tex4ht_c_derived = tex4ht.c

derived += $(tex4ht_docbook_derived)
tex4ht_docbook_derived = docbook.4ht docbook-math.4ht docbook-mml.4ht

ifeq ($(java_in_make),true)
derived += $(tex4ht_docbook_xtpipes_derived)
tex4ht_docbook_xtpipes_derived = docbook.4xt $(wd)/src/DbUtilities.java
endif

derived += $(tex4ht_env_derived)
tex4ht_env_derived = tex4ht.env-unix tex4ht.env-win32 tex4ht.env

derived += $(tex4ht_fonts_cjk_derived)
tex4ht_fonts_cjk_derived = \
  $(ht_fonts_devdir)/unicode/cjk/gbksong/gbksong01.htf
# and a whole lot more  

derived += $(tex4ht_fonts_cjk_utf8_derived)
tex4ht_fonts_cjk_utf8_derived = \
  $(ht_fonts_devdir)/unicode/cjk/utf8/unisonga0.htf

# noncjk.tex \input's modern, but seems more maintainable
# to have separate lists.
ht_fonts_devdir = $(homedir)/texmf/tex4ht/ht-fonts
derived += $(tex4ht_fonts_noncjk_derived)
tex4ht_fonts_noncjk_derived = \
  $(ht_fonts_devdir)/alias/ec/eccc.htf \
  $(ht_fonts_devdir)/unicode/ec/eccc-uni.htf \
  $(ht_fonts_devdir)/alias/t1fonts/ClearSans-BoldItalic-lf-t1.htf \
  $(ht_fonts_devdir)/alias/t1fonts/ipxg-r-t1.htf \
  $(ht_fonts_devdir)/unicode/jknappen/tc/tcrm.htf \
  $(ht_fonts_devdir)/unicode/misc/SkakNew.htf \
  $(ht_fonts_devdir)/unicode/adobe/courier/pcrro8r.htf \
  $(ht_fonts_devdir)/iso8859/1/tibetan/ctib.htf \
  $(ht_fonts_devdir)/unicode/tibetan/ctib.htf \
  $(ht_fonts_devdir)/alias/bera/fveb8r.htf \
  $(ht_fonts_devdir)/alias/bera/fveb8t.htf \
  $(ht_fonts_devdir)/alias/bera/fver8r.htf \
  $(ht_fonts_devdir)/alias/bera/fver8t.htf \
  $(ht_fonts_devdir)/alias/bera/fvero8r.htf \
  $(ht_fonts_devdir)/alias/bera/fvero8t.htf \
  $(ht_fonts_devdir)/alias/t1fonts/XCharter-Roman-tlf-t1--base.htf \
  $(ht_fonts_devdir)/alias/t1fonts/XCharter-Italic-tlf-t1--base.htf \
  $(ht_fonts_devdir)/alias/t1fonts/XCharter-Bold-tlf-t1--base.htf

# Although SearchFonts.java is created by fonts-noncjk, it's a
# development tool that we don't use and have no need for, so don't list
# it or try to compile it. (See source for a little more info.)
#   $(wd)/src/SearchFonts.java

derived += $(tex4ht_fonts_modern_derived)
tex4ht_fonts_modern_derived = \
  $(ht_fonts_devdir)/unicode/lm/l7x-lmcsc.htf \
  $(ht_fonts_devdir)/unicode/lm/l7x-lm.htf \
  $(ht_fonts_devdir)/unicode/lm/lm-ts1.htf \
  $(ht_fonts_devdir)/unicode/lm/rm-lm.htf \
  $(ht_fonts_devdir)/alias/lm/rm-lmt.htf \
  $(ht_fonts_devdir)/alias/lm/rm-lmvt.htf \
  lm-htf.tex

derived += $(tex4ht_fonts_ebgaramond_derived)
tex4ht_fonts_ebgaramond_derived = \
	$(ht_fonts_devdir)/unicode/EB_Garamond_Regular/EBGaramond-Regular-lf-t1.htf \
	$(ht_fonts_devdir)/alias/EB_Garamond_Bold/EBGaramond-Bold-osf-t1.htf

derived += $(tex4ht_fonts_libertine_derived)
tex4ht_fonts_libertine_derived = \
	$(ht_fonts_devdir)/unicode/Linux_Biolinum_T/LinBiolinumT-lf-sc-ly1.htf

derived += $(tex4ht_fonts_newtx_derived)
tex4ht_fonts_newtx_derived = \
	$(ht_fonts_devdir)/unicode/txbmiaX/ntxbmia.htf

derived += $(tex4ht_fonts_fourier_derived)
tex4ht_fonts_fourier_derived = \
	$(ht_fonts_devdir)/unicode/Fourier-Math-Letters/futmi.htf

derived += $(tex4ht_fonts_spectral_derived)
tex4ht_fonts_spectral_derived = \
	$(ht_fonts_devdir)/unicode/Spectral/Spectral-Regular-lf-sc-ly1.htf

derived += $(tex4ht_fonts_kpfonts_derived)
tex4ht_fonts_kpfonts_derived = \
	$(ht_fonts_devdir)/unicode/Kp-Light-M-Syd/jkplsyd.htf

derived += $(tex4ht_fonts_opensans_derived)
tex4ht_fonts_opensans_derived = \
	$(ht_fonts_devdir)/unicode/Open_Sans_Light/OpenSans-LightItalic-OT1-LF.htf
# xx and many more
# whither tmp?  how change target dir?  what happened to cmtex.htf?  etc.

derived += $(tex4ht_fonts_mnsymbol_derived)
tex4ht_fonts_mnsymbol_derived = \
	$(ht_fonts_devdir)/unicode/MnSymbol/MnSymbolA-Bold10.htf

derived += $(tex4ht_fonts_stix_derived)
tex4ht_fonts_stix_derived = \
	$(ht_fonts_devdir)/unicode/STIX/stix-mathbb.htf

derived += $(tex4ht_fonts_stix2_derived)
tex4ht_fonts_stix2_derived = \
	$(ht_fonts_devdir)/unicode/STIX_Two/stix2-mathbb.htf

derived += $(tex4ht_fonts_arphic_derived)
tex4ht_fonts_arphic_derived = \
	$(ht_fonts_devdir)/unicode/arphic/bsmiu9d.htf

# htcmd not used
#derived += $(tex4ht_htcmd_derived)
#tex4ht_htcmd_derived = htcmd.c

derived += $(tex4ht_fonts_4hf)
tex4ht_fonts_4hf = \
  $(ht_fonts_devdir)/mozilla/charset/unicode.4hf \
  $(ht_fonts_devdir)/unicode/charset/unicode.4hf \

# xx and many more

derived += $(tex4ht_html_speech_derived)
tex4ht_html_speech_derived = html-speech.4ht html-speech-math.4ht emacspeak.4ht

ifeq ($(java_in_make),true)
derived += $(tex4ht_html_speech_xtpipes_derived)
tex4ht_html_speech_xtpipes_derived = htspk.4xt $(wd)/src/HtSpk.java
endif

derived += $(tex4ht_html0_derived)
tex4ht_html0_derived = html0.4ht

derived += $(tex4ht_html32_derived)
tex4ht_html32_derived = html32.4ht html32-math.4ht 

derived += $(tex4ht_html4_derived)
tex4ht_html4_derived = \
  html4.4ht html4-math.4ht \
  html4-l2-url.4ht html4-russian-accents.4ht \
  onmouseover.4ht exerqz.4ht  

#xx big changes for unknown reasons 
derived += $(tex4ht_info_derived)
tex4ht_info_derived = info4ht.4ht

derived += $(tex4ht_info_html4_derived)
tex4ht_info_html4_derived = infoht4.4ht

derived += $(tex4ht_info_javahelp_derived)
tex4ht_info_javahelp_derived = infojh.4ht

derived += $(tex4ht_info_mml_derived)
tex4ht_info_mml_derived = infomml.4ht

derived += $(tex4ht_info_ooffice_derived)
tex4ht_info_ooffice_derived = infoof.4ht

derived += $(tex4ht_info_svg_derived)
tex4ht_info_svg_derived = infosvg.4ht

derived += $(tex4ht_javahelp_derived)
tex4ht_javahelp_derived = javahelp.4ht javahelp-a.4ht

ifneq ($(do_java),2)
derived += $(tex4ht_javahelp_xtpipes_derived)
tex4ht_javahelp_xtpipes_derived = javahelp.4xt
endif

derived += $(tex4ht_jsmath_derived)
tex4ht_jsmath_derived = jsmath.4ht html-jsmath.4ht

ifneq ($(do_java),2)
derived += $(tex4ht_jsml_xtpipes_derived)
tex4ht_jsml_xtpipes_derived = \
  jsml.4xt \
  $(addprefix $(wd)/src/,HtJsml.java GroupMn.java JsmlFilter.java JsmlMathBreak.java)
endif

derived += $(tex4ht_jsml_derived)
tex4ht_jsml_derived = jsml.4ht jsml-math.4ht

derived += $(tex4ht_mathltx_derived)
tex4ht_mathltx_derived = mathltx.4ht html-mltx.4ht

derived += $(tex4ht_mathml_derived)
tex4ht_mathml_derived = mathml.4ht html-mml.4ht

derived += $(tex4ht_mathplayer_derived)
tex4ht_mathplayer_derived = mathplayer.4ht

derived += $(tex4ht_mkht_derived)
tex4ht_mkht_derived = mkht.4ht mk4ht.perl mkht-scripts.4ht ht.unix ht.bat

derived += $(tex4ht_moz_derived)
tex4ht_moz_derived = mozilla.4ht

derived += $(tex4ht_html5_derived)
tex4ht_html5_derived = html5.4ht

ifneq ($(do_java),2)
derived += $(tex4ht_oo_xtpipes_derived)
tex4ht_oo_xtpipes_derived = \
   oo-math.4xt oo-text.4xt \
   $(addprefix $(wd)/src/,OoUtilities.java OomFilter.java OoFilter.java)
endif

derived += $(tex4ht_ooffice_derived)
tex4ht_ooffice_derived = ooffice.4ht ooffice-mml.4ht

derived += $(tex4ht_ooimpress_derived)
tex4ht_ooimpress_derived = ooimpress.4ht

derived += $(tex4ht_options_derived)
tex4ht_options_derived = tex4ht.4ht

derived += $(tex4ht_sty_derived)
tex4ht_sty_derived = tex4ht.sty

derived += $(tex4ht_svg_derived)
tex4ht_svg_derived = svg-option.4ht html4-svg.4ht

derived += $(tex4ht_t4ht_derived)
tex4ht_t4ht_derived = t4ht.c

derived += $(tex4ht_tei_derived)
tex4ht_tei_derived = tei.4ht tei-mml.4ht tei-math.4ht tei-mmltei.4ht

derived += $(tex4ht_jats_derived)
tex4ht_jats_derived = jats.4ht

derived += $(tex4ht_unicode_derived)
tex4ht_unicode_derived = unicode.4ht

derived += $(tex4ht_word_derived)
tex4ht_word_derived = htmlw.4ht

ifneq ($(do_java),2)
derived += $(tex4ht_xhtml_xtpipes_derived)
tex4ht_xhtml_xtpipes_derived = xhtml.4xt $(wd)/src/XhtmlEmails.java
endif

ifneq ($(do_java),2)
derived += $(tex4ht_xhtmml_xtpipes_derived)
tex4ht_xhtmml_xtpipes_derived = xhtmml.4xt $(wd)/src/XhtmmlUtilities.java
endif

derived += $(tex4ht_mathjax_derived)
tex4ht_mathjax_derived = mathjax-latex-4ht.4ht

# wripro.tex generates nothing (not literate).

ifneq ($(do_java),2)
derived += $(xtpipes_derived)
xtpipes_derived = \
  $(addprefix $(wd)/src/, \
	xtpipes.java \
	xtpipes/FileInfo.java \
	xtpipes/InputObject.java \
	xtpipes/Xtpipes.java \
	xtpipes/XtpipesPrintWriter.java \
	xtpipes/XtpipesUni.java \
	xtpipes/util/ScriptsManager.java \
	xtpipes/util/ScriptsManagerLH.java ) \
  xtpipes-default.4xt \
  xtpipes-map.dtd \
  xtpipes.dtd \
  $(xtpipes_jar)
  #
endif

# 
all: $(derived)
	rm -f texput.log; texlua checklog.lua *.log

$(tex4ht_4ht_derived): tex4ht-4ht.tex cond4ht.4ht $(common)
	etex $(tex_opts) $<

$(tex4ht_bibtex2_derived): tex4ht-bibtex2.tex $(common)
	latex $(tex_opts) $<

$(tex4ht_c_derived): tex4ht-c.tex $(common)
	etex $(tex_opts) $<

$(tex4ht_cond4ht_derived): tex4ht-cond4ht.tex mktex4ht-cnf.tex $(common)
	etex $(tex_opts) $<
	etex $(tex_opts) cond4ht.4ht

$(tex4ht_docbook_derived): tex4ht-docbook.tex $(common)
	htlatex $< "html,3" "" "" $(tex_1opt)

$(tex4ht_docbook_xtpipes_derived): tex4ht-docbook-xtpipes.tex $(common)
	htlatex $< "html,3" "" "" $(tex_1opt)

$(tex4ht_env_derived): tex4ht-env.tex $(common)
	htlatex $< "xhtml,3" "" "" $(tex_1opt)

$(tex4ht_fonts_cjk_derived): tex4ht-fonts-cjk.tex
	$(HTTEX) $< ""

$(tex4ht_fonts_cjk_utf8_derived): tex4ht-fonts-cjk-utf8.tex
	$(HTTEX) $< ""

$(tex4ht_fonts_noncjk_derived) $(tex4ht_fonts_modern_derived): \
  tex4ht-fonts-noncjk.tex tex4ht-fonts-modern.tex $(common)
	$(HTTEX) $< ""

$(tex4ht_fonts_ebgaramond_derived): tex4ht-fonts-ebgaramond.tex
	$(HTTEX) $< ""

$(tex4ht_fonts_libertine_derived): tex4ht-fonts-libertine.tex
	$(HTTEX) $< ""

$(tex4ht_fonts_newtx_derived): tex4ht-fonts-newtx.tex
	$(HTTEX) $< ""

$(tex4ht_fonts_fourier_derived): tex4ht-fonts-fourier.tex
	$(HTTEX) $< ""

$(tex4ht_fonts_spectral_derived): tex4ht-fonts-spectral.tex
	$(HTTEX) $< ""

$(tex4ht_fonts_kpfonts_derived): tex4ht-fonts-kpfonts.tex
	$(HTTEX) $< ""

$(tex4ht_fonts_opensans_derived): tex4ht-fonts-opensans.tex
	$(HTTEX) $< ""

$(tex4ht_fonts_mnsymbol_derived): tex4ht-fonts-mnsymbol.tex
	$(HTTEX) $< ""

$(tex4ht_fonts_stix_derived): tex4ht-fonts-stix.tex
	$(HTTEX) $< ""

$(tex4ht_fonts_stix2_derived): tex4ht-fonts-stix2.tex
	$(HTTEX) $< ""

$(tex4ht_fonts_arphic_derived): tex4ht-fonts-arphic.tex
	$(HTTEX) $< ""

# requires more memory than configured in other tex programs.
$(tex4ht_fonts_4hf): tex4ht-fonts-4hf.tex
	dvilualatex $< 
	tex4ht `basename $< .tex`
	t4ht `basename $< .tex`

$(tex4ht_htcmd_derived): tex4ht-htcmd.tex $(common)
	$(HTTEX) $< ""

$(tex4ht_html_speech_derived): tex4ht-html-speech.tex $(common)
	htlatex $< "html,3,sections+" "" "" $(tex_1opt)

$(tex4ht_html_speech_xtpipes_derived): tex4ht-html-speech-xtpipes.tex $(common)
	htlatex $< "html,next,3" "" "" $(tex_1opt)

$(tex4ht_html0_derived): tex4ht-html0.tex $(common)
	htlatex $< "html,3,sections+" "" "" $(tex_1opt)

$(tex4ht_html32_derived): tex4ht-html32.tex $(common)
	htlatex $< "html,3,sections+" "" "" $(tex_1opt)

$(tex4ht_html4_derived): tex4ht-html4.tex $(common)
	latex $(tex_opts) $<
	latex $(tex_opts) $<

$(tex4ht_html5_derived): tex4ht-html5.tex $(common)
	htlatex $< "xhtml,3,sections+" "" "" $(tex_1opt)

$(tex4ht_info_html4_derived): tex4ht-info-html4.tex $(common_info)
	htlatex $< "html,3,sections+" "" "" $(tex_1opt)

$(tex4ht_jats_derived): tex4ht-jats.tex $(common)
	htlatex $< "html,3,sections+" "" "" $(tex_1opt)

$(tex4ht_info_javahelp_derived): tex4ht-info-javahelp.tex $(common_info)
	htlatex $< "html,sections+" "" "" $(tex_1opt)

$(tex4ht_info_mml_derived): tex4ht-info-mml.tex $(common_info)
	latex $(tex_opts) $<

$(tex4ht_info_ooffice_derived): tex4ht-info-ooffice.tex $(common_info)
	htlatex $< "html,sections+" "" "" $(tex_1opt)

$(tex4ht_info_svg_derived): tex4ht-info-svg.tex $(common_info)
	latex $(tex_opts) $<

$(tex4ht_info_derived): tex4ht-info.tex $(common)
	htlatex $< "html,3,sections+" "" "" $(tex_1opt)

$(tex4ht_javahelp_derived): tex4ht-javahelp.tex $(common)
	htlatex $< "html,3,sections+" "" "" $(tex_1opt)

$(tex4ht_javahelp_xtpipes_derived): tex4ht-javahelp-xtpipes.tex $(common)
	htlatex $< "xhtml,next,3" "" "" $(tex_1opt)

$(tex4ht_jsmath_derived): tex4ht-jsmath.tex $(common)
	htlatex $< "html,3,sections+" "" "" $(tex_1opt)

$(tex4ht_jsml_xtpipes_derived): tex4ht-jsml-xtpipes.tex $(common) $(xtpipes_jar)
	htlatex $< "xhtml,next,3" "" "" $(tex_1opt)

$(tex4ht_jsml_derived): tex4ht-jsml.tex $(common)
	htlatex $< "html,3,sections+" "" "" $(tex_1opt)

$(tex4ht_mathjax_derived): tex4ht-mathjax.tex
	htlatex $<  "xhtml,3,next" "" "" $(tex_1opt)

$(tex4ht_mathltx_derived): tex4ht-mathltx.tex $(common)
	htlatex $< "html,3,sections+" "" "" $(tex_1opt)

$(tex4ht_mathml_derived): tex4ht-mathml.tex $(common)
	htlatex $< "html,3,sections+" "" "" $(tex_1opt)

$(tex4ht_mathplayer_derived): tex4ht-mathplayer.tex $(common)
	htlatex $< "html,3,sections+" "" "" $(tex_1opt)

$(tex4ht_mkht_derived): tex4ht-mkht.tex $(common)
	latex $(tex_opts) $<
	perl -c mk4ht.perl  # syntax check
	latex $(tex_opts) mkht-scripts.4ht

$(tex4ht_moz_derived): tex4ht-moz.tex $(common)
	htlatex $< "html,3,sections+" "" "" $(tex_1opt)

$(tex4ht_oo_xtpipes_derived): tex4ht-oo-xtpipes.tex $(common)
	htlatex $< "xhtml,next,3" "" "" $(tex_1opt)

$(tex4ht_ooffice_derived): tex4ht-ooffice.tex $(common)
	htlatex $< "xhtml,4,sections+" "" "" $(tex_1opt)

$(tex4ht_ooimpress_derived): tex4ht-ooimpress.tex $(common)
	htlatex $< "xhtml,4,sections+" "" "" $(tex_1opt)

$(tex4ht_options_derived): tex4ht-options.tex $(common)
	htlatex $< "html,3,sections+" "" "" $(tex_1opt)

$(tex4ht_sty_derived): tex4ht-sty.tex $(common_no_tex4ht_sty)
	$(HTTEX) $< ""

$(tex4ht_svg_derived): tex4ht-svg.tex $(common)
	htlatex $< "html,3,sections+" "" "" $(tex_1opt)

$(tex4ht_t4ht_derived): tex4ht-t4ht.tex $(common)
	$(HTTEX) $< ""

$(tex4ht_tei_derived): tex4ht-tei.tex $(common)
	htlatex $< "html,3,sections+" "" "" $(tex_1opt)

$(tex4ht_unicode_derived): tex4ht-unicode.tex $(common)
	htlatex $< "html,3,sections+" "" "" $(tex_1opt)

$(tex4ht_word_derived): tex4ht-word.tex $(common)
	htlatex $< "html,3,sections+" "" "" $(tex_1opt)

$(tex4ht_xhtml_xtpipes_derived): tex4ht-xhtml-xtpipes.tex $(common)
	htlatex $< "xhtml,3,next" "" "" $(tex_1opt)

$(tex4ht_xhtmml_xtpipes_derived): tex4ht-xhtmml-xtpipes.tex $(common)
	htlatex $< "xhtml,3,next" "" "" $(tex_1opt)

$(xtpipes_derived): xtpipes.tex $(common)
	htlatex $< "xhtml,3,next" "" "" $(tex_1opt)
# Derived files are generated in . and $(wd).
# (corresponds to src/java for xtpipes.tex)

# 
# Remake all *-fonts-*.tex files, i.e., update all htf. Since we list
# few dependencies for these, have to have some other way. Assume GNU make.
# Takes ~20 min and generates ~50MB of output.
update-all-fonts:
	date; for f in *-fonts-*.tex; do \
	  printf "\n\f making $$f"; \
	  $(MAKE) -W $$f || exit $?; done
	@echo "update-all-fonts done."

# Simple make abbrev for convenience.
upmake upm:
	svn update && make

# 
# Test installation. Does not work.
destdir = update.dir
dest_texmf = $(destdir)/texmf/tex/generic/tex4ht
dest_4ht = $(destdir)/texmf/tex4ht
dest_base = $(dest_4ht)/base
dest_xtpipes = $(dest_4ht)/xtpipes
dest_src = $(destdir)/src
dest_java = $(dest_src)/java
#
update = cp -pr
mkdir = install -d
#
update-env:
	$(mkdir) $(dest_base)/unix $(dest_base)/win32
	$(update) tex4ht.env-unix $(dest_base)/unix/tex4ht.env
	$(update) tex4ht.env-win32 $(dest_base)/win32/tex4ht.env

update: all
	$(update) $(tex4ht_bibtex2_derived) $(dest_src)/
#
	$(update) $(tex4ht_c_derived) $(dest_src)/
#
	$(update) $(tex4ht_cond4ht_derived) $(dest_texmf)/
#
	$(update) docbook.4xt $(dest_xtpipes)/
	$(update) DbUtilities.java $(dest_java)/
#
	$(update) $(tex4ht_docbook_derived) $(dest_texmf)/
#
	$(MAKE) update-env
#
	$(update) $(tex4ht_html_speech_xtpipes_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_html_speech_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_html0_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_html32_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_html4_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_info_mml_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_info_ooffice_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_info_svg_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_info_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_javahelp_xtpipes_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_javahelp_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_jsmath_derived) $(dest_texmf)/
#
	$(update) jsml.4xt $(dest_xtpipes)/
	$(update) HtJsml.java GroupMn.java JsmlFilter.java \
	          JsmlMathBreak.java $(dest_java)/
#
	$(update) $(tex4ht_jsml_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_mathltx_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_mathplayer_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_moz_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_html5_derived) $(dest_texmf)/
#
	$(update) oo-text.4xt oo-math.4xt $(dest_xtpipes)/
	$(update) OoUtilities.java OomFilter.java $(dest_java)/
#
	$(update) $(tex4ht_ooffice_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_ooimpress_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_options_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_sty_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_svg_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_t4ht_derived) $(dest_src)/
#
	$(update) $(tex4ht_tei_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_jats_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_unicode_derived) $(dest_texmf)/
#
	$(update) $(tex4ht_word_derived) $(dest_texmf)/
#
	$(update) xhtml.4xt $(dest_xtpipes)/
	$(update) XhtmlEmails.java $(dest_java)/
#
	$(update) xhtmml.4xt $(dest_xtpipes)/
	$(update) XhtmmlUtilities.java $(dest_java)/
#
# this has to be done last. Does anything else use $(wd)? We'll see.
	rmdir $(wd)/bin
	$(update) $(wd)/* $(dest_java)/
	$(update) xtpipes.dtd xtpipes-map.dtd xtpipes-default.4xt \
	  $(dest_xtpipes)/

clean: mostlyclean
	rm -rf $(wd)
	rm -f *.4ct *.4tc *.aux *.css *.dvi *.idv *.lg *.log *.tmp *.trc *.xref
	rm -f *.4es *.bat *.unix *.htf *.html *.png tmp
	rm -f *.fls
	rm -f tex4ht-dir.tex

mostlyclean:
	rm -f $(derived)

clean1:
	rm -f $(f).[0-s]* $(f).[u-z]* $(f).trc

# 
# Java.
ifeq ($(java_in_make),true)
.PHONY: jar
jar: $(homedir)/$(texmf_t4ht_bin)/tex4ht.jar
$(homedir)/$(texmf_t4ht_bin)/tex4ht.jar:
	$(tex4ht_docbook_xtpipes_derived) \
	$(tex4ht_fonts_noncjk_derived) \
	$(tex4ht_html_speech_xtpipes_derived) \
	$(tex4ht_jsml_xtpipes_derived) \
	$(tex4ht_oo_xtpipes_derived) \
	$(tex4ht_xhtml_xtpipes_derived) \
	$(tex4ht_xhtmml_xtpipes_derived) 
	find $(wd)/src -iname '*.java' -print0 \
	| xargs -0 javac -d $(xtpipesdir) -sourcepath $(wd)/src
	mkdir -p $(dir $@)
	cd $(xtpipesdir) && jar cf $(notdir $@) *
	mv $(xtpipesdir)/$(notdir $@) $(dir $@)
endif

# 
# The directories where tex4ht is installed in TeX Live,
# i.e., where we will copy and commit updates.

texmf = /v/texlive/karl/Master/texmf-dist
inst_dir_4ht = $(texmf)/tex/generic/tex4ht
inst_dir_top = $(texmf)/tex4ht
inst_dir_scripts = $(texmf)/scripts/tex4ht
inst_dir_source = $(texmf)/source/generic/tex4ht
#
inst_dir_all = $(inst_dir_4ht) $(inst_dir_top) $(inst_dir_scripts) \
               $(inst_dir_source)

# Simple command to "install" from dev to TL.
# (Other methods are also used.)
install_data = cp -p

# Diff and install the *.unix and *.bat scripts.
# The suffix changes from .unix in development to .sh in TL,
# and many of the scripts are not installed at all;
# don't worry about that. We also won't worry about the 
# Perl scripts (mk4ht) at present.
# 
diff-scripts:
	@echo; echo '>>> $@'
	for f in *.unix; do \
	  inst_f=$(inst_dir_scripts)/`basename $$f .unix`.sh; \
	  test -r $$inst_f || continue; \
	  $(diff) $$inst_f $$f; done

# Diff from installed to dev, but install from dev to installed.
install-scripts:
	@echo; echo '>>> $@'
	for f in *.unix; do \
	  inst_f=$(inst_dir_scripts)/`basename $$f .unix`.sh; \
	  test -r $$inst_f || continue; \
	  echo $(install_data) $$inst_f $$f; \
	  $(install_data) $$f $$inst_f; done

# 
# Checking and updating source files from development vs. TeX Live,
# from whence they get to CTAN.

srcfiles = $(shell svn status -v | awk '{print $$NF}' \
             | egrep -v '^\.|^archive|extra-bin|vcss|xmllint|mf|ProTex.sty$$')

# Diff source files from installed to dev.
diff-src:
	@echo; echo '>>> $@'
	for f in $(srcfiles); do $(diff) $(inst_dir_source)/$$f $$f; done
#
# Install from dev to installed.
update-src:
	for f in $(srcfiles); do $(install_data) $$f $(inst_dir_source); done
	svn status $(inst_dir_source)
#
# Just list the files.
list-src:
	@echo $(srcfiles) | tr ' ' '\n'

# 
# Checking and updating font support files.

# Where they are in the installed tree.
ht_fonts_instdir = $(inst_dir_top)/ht-fonts

# Compare only.
diff-htfonts:
	@echo; echo '>>> $@'
	./update-htfonts diff $(ht_fonts_devdir) $(ht_fonts_instdir) | tee /tmp/htdif

# Compare and update.
update-htfonts:
	./update-htfonts update $(ht_fonts_devdir) $(ht_fonts_instdir) | tee /tmp/htupd
.PHONY: update-htfonts

# svn status of results.
svnstatus st:
	svn status $(inst_dir_all) | sed s,$(texmf),, # reduce output
	@echo $(inst_dir_all)

# 
# diff all files in the main TeX Live installation directory against
# cwd (development). the --ignore-matching-lines below only works when
# that's the only change in the hunk, so ignore them all explicitly.
# also ignore commented changes.
#
# htf files, scripts, etc. are in different places, so don't include them here,
# 
# The diff-scripts output is usually empty, so we can run that;
# but diff-htfonts is too verbose to run every time.
diff-all: diff-src diff-scripts diff-htfonts
	@echo; echo '>>> $@'
	-for f in $(inst_dir_4ht)/*; do $(diff) $$f .; done \
	| tee /tmp/u | egrep -v '^ *[-+]%|^@@ |^- *$$|-1.version' \
	             | egrep -v '^..ifx.infoIVht.UnDeF.*//$$' \
		     | egrep -v '^--- '

# For checking the derived files that are explicitly listed above
# against installed (in TL) files. This is a small subset of all the
# generated files.
diff_files = $(filter-out %.htf %.4hf tex4ht.env% %.c lm-htf.tex \
                          mk4ht.perl ht.unix ht.bat,\
                          $(derived))
diff-derived:
	@echo; echo '>>> $@'
	-for f in $(diff_files); do $(diff) $(inst_dir_4ht)/$$f .; done \
	| tee /tmp/u | egrep -v '^ *[-+]%|^@@ |^- *$$|-1.version' \
	             | egrep -v '^..ifx.infoIVht.UnDeF.*//$$'

# Check that anything with a \version of this year
# also has a copyright of this year.
inst-check-copyright:
	@echo; echo '>>> $@'
	-cd $(inst_dir_4ht) && for f in *; do \
	  if grep "version.*`date +%Y`" $$f >/dev/null; then \
	    grep "Copyright.*`date +%Y`" $$f >/dev/null || echo $$f; fi; done

# Check that all *.4ht in dev are installed. Other file types are
# difficult, but all 4ht's should be present, except mktex4ht.4ht.
inst-check-files:
	@echo; echo '>>> $@'
	cd $(inst_dir_4ht) && ls -1 *.4ht >/tmp/instlist
	ls -1 *.4ht | fgrep -v mktex4ht.4ht >/tmp/devlist
	comm -3 /tmp/devlist /tmp/instlist
	
# Check for missing version identifications.
inst-check-version:
	@echo; echo '>>> $@'
	-cd $(inst_dir_4ht) && for f in *; do \
	  grep 'write-1.*version' $$f >/dev/null || echo $$f; done

# 
# diff one specified file, as in "make d1 d=filename.4ht".
diff1 d1:
	$(diff) $(inst_dir_4ht)/$(d) .

# the diff command used pervasively.
diff = diff -u0 --ignore-all-space --ignore-blank-lines \
  --ignore-matching-lines='write-1.version\|, generated from\|Copyright'

# run weekly by karl.
croncheck: upm diff-all \
	   inst-check-copyright inst-check-files inst-check-version \
	   diff-htfonts
