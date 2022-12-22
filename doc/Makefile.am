LATEXMKOPTS = -pdf -cd -use-make -pdflatex="pdflatex -interaction=nonstopmode %O %S"

EXTRA_DIST = $(srcdir)/*.tex $(srcdir)/*.sty $(srcdir)/**/*.tex \
	     $(srcdir)/**/**/*.tex $(srcdir)/**/*.eps $(srcdir)/**/*.pdf \
	     $(srcdir)/listings/

CLEANFILES = chapters/*.aux documentation.bbl documentation.run.xml \
	     texput.fls **/*-converted-to.*

doc_DATA = documentation.pdf

.PHONY: FORCE_MAKE

documentation.pdf: $(srcdir)/documentation.tex FORCE_MAKE
	$(LATEXMK) $(LATEXMKOPTS) $<

clean-local:
	$(LATEXMK) -C
