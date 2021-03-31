ORG := $(shell git ls-files | grep '\.org$$')
MD := $(shell git ls-files | grep '\.md$$')
ADOC := $(shell git ls-files | grep '\.adoc$$')
DOT := $(shell git ls-files | grep '\.dot$$')

ORG_HTML := $(patsubst %.org,%.org.html,$(ORG))
MD_HTML := $(patsubst %.md,%.md.html,$(MD))
ADOC_HTML := $(patsubst %.adoc,%.adoc.html,$(ADOC))
ADOC_XML_HTML := $(patsubst %.adoc,%.adoc.xml.html,$(ADOC))
SVG := $(patsubst %.dot,%.svg,$(DOT))

# input/output directory names
CSS := css
IMG := img
PUB := pub
OUT := public

TP_CSS := $(PUB)/tufte-pandoc-css
T_CSS := $(TP_CSS)/tufte-css
TMPL := $(TP_CSS)/tufte.html5

# CSS to be included directly in HTML documents
# add local styles here, if any
STYLES := \
	$(T_CSS)/tufte.css \
	$(TP_CSS)/pandoc.css \
	$(TP_CSS)/tufte-extra.css \
	$(TP_CSS)/hyphens.css

# solarized theme for code blocks
#	$(TP_CSS)/pandoc-solarized.css \

# other CSS
STYLES_X := \
	$(T_CSS)/latex.css \
	$(T_CSS)/et-book/

CITEPROC_OPT := $(shell pandoc --help | grep -o '[-]-citeproc' || echo '--filter pandoc-citeproc')
SIDENOTE_OPT := $(shell which pandoc-sidenote >/dev/null 2>&1 && echo '--filter pandoc-sidenote')

space :=
space +=

all: org md adoc svg
org: $(ORG_HTML) css lib img svg
md: $(MD_HTML) css lib img svg
adoc: $(ADOC_XML_HTML) css lib img svg
svg: $(SVG)

# org -> pandoc html
%.org.html: %.org $(TMPL) $(STYLES)
	mkdir -p $(dir $(OUT)/$(dir $@))
	pandoc \
		--toc \
		--toc-depth 2 \
		--section-divs \
		--katex=$(subst %,,$(patsubst %,../,$(subst /,%,$(subst ./,,$(dir $@)))))$(LIB)/ \
		--from org+citations \
		--to html5+smart \
		$(shell test -e $<.yaml && echo --metadata-file=$<.yaml) \
		--template $(TMPL) \
		--highlight-style=monochrome \
		$(CITEPROC_OPT) \
		$(SIDENOTE_OPT) \
		$(foreach style,$(STYLES),--css $(subst %,,$(patsubst %,../,$(subst /,%,$(subst ./,,$(dir $@)))))$(CSS)/$(notdir $(style))) \
		$< | sed 's/href="\([^":]*\)\.org"/href="\1.html"/g' > $(OUT)/$(patsubst %.org,%.html,$<)

# md -> pandoc html
%.md.html: %.md $(TMPL) $(STYLES)
	mkdir -p $(dir $(OUT)/$(dir $@))
	pandoc \
		--toc \
		--toc-depth=2 \
		--section-divs \
		--katex=$(subst %,,$(patsubst %,../,$(subst /,%,$(subst ./,,$(dir $@)))))$(LIB)/ \
		--to html5+smart \
		$(shell test -e $<.yaml && echo --metadata-file=$<.yaml) \
		--template=$(TMPL) \
		$(CITEPROC_OPT) \
		$(SIDENOTE_OPT) \
		$(foreach style,$(STYLES),--css $(subst %,,$(patsubst %,../,$(subst /,%,$(subst ./,,$(dir $@)))))$(CSS)/$(notdir $(style))) \
		$< | sed 's/href="\([^":]*\)\.org"/href="\1.html"/g' > $(OUT)/$(patsubst %.md,%.html,$<)

# adoc -> docbook xml -> pandoc html
%.adoc.xml.html: %.adoc $(TMPL) $(STYLES)
	mkdir -p $(dir $(OUT)/$(dir $@))
	asciidoctor -v -b docbook5 -o - $< \
	| pandoc \
		--toc \
		--toc-depth 2 \
		--section-divs \
		--katex=$(subst %,,$(patsubst %,../,$(subst /,%,$(subst ./,,$(dir $@)))))$(LIB)/ \
		--from docbook \
		--to html5+smart \
		$(shell test -e $<.yaml && echo --metadata-file=$<.yaml) \
		--template $(TMPL) \
		$(CITEPROC_OPT) \
		$(SIDENOTE_OPT) \
		$(foreach style,$(STYLES),--css $(subst %,,$(patsubst %,../,$(subst /,%,$(subst ./,,$(dir $@)))))$(CSS)/$(notdir $(style))) \
		| sed 's/href="\([^":]*\)\.adoc"/href="\1.html"/g' > $(OUT)/$(patsubst %.adoc,%.html,$<)

%.svg: %.dot
	mkdir -p $(dir $(OUT)/$(dir $@))
	neato -Tsvg $< > $(OUT)/$@

css: $(OUT)/$(CSS)
lib: $(OUT)/$(LIB)
img: $(OUT)/$(IMG)

$(OUT)/$(CSS): $(STYLES) $(STYLES_X)
	mkdir -p $(OUT)/$(CSS)
	cp -a $(STYLES) $(STYLES_X) $(OUT)/$(CSS)

$(OUT)/$(LIB):
	mkdir -p $(OUT)/$(LIB)/contrib
	wget -cP $(OUT)/$(LIB) https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.9.0/katex.min.js
	wget -cP $(OUT)/$(LIB) https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.9.0/katex.min.css
	wget -cP $(OUT)/$(LIB)/contrib https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.9.0/contrib/auto-render.min.js
	wget -cP $(OUT)/$(LIB) https://cdnjs.cloudflare.com/ajax/libs/html5shiv/3.7.3/html5shiv-printshiv.min.js

$(OUT)/$(IMG):
	mkdir -p $(OUT)
	test -e $(IMG) && cp -a $(IMG) $(OUT)/ || true

clean:
	rm -rf $(OUT)

sub:
	git submodule update --init --recursive

.PHONY: clean
.PHONY: $(OUT)/$(CSS)
