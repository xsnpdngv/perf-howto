# === Configuration ===
NAME ?= perf

CALLGRAPH_NODE_THRES_PCT = 0.5 # eliminate nodes below this threshold [default: 0.5]
CALLGRAPH_EDGE_THRES_PCT = 0.1 # eliminate edges below this threshold [default: 0.1]
CALLGRAPH_THEME_SKEW = 0.05    # skew the colorization curve.
                               # Values < 1.0 give more variety to lower percentages
                               # Values > 1.0 give less variety to lower percentages

FLAMEGRAPH_DIR = $(HOME)/git/FlameGraph

DATE = $(shell date +%Y-%m-%d)

SRC_MD     = README.md
DOC_PDF    = perf_howto_v1.0.pdf
PERF_DATA  = perf.data
PERF_SCRIPT= perf.script
CALL_DOT   = "$(NAME)_callgraph_$(DATE).dot"
CALL_PDF   = "$(NAME)_callgraph_$(DATE).pdf"
FLAME_SVG  = "$(NAME)_flamegraph_$(DATE).svg"


# === Options ===
PANDOC_OPTS = \
    -V papersize:A4 \
    -V documentclass=article \
    -V geometry:margin=1in \
    -V colorlinks \
    --toc \
    --toc-depth=2 \
    --pdf-engine=xelatex \
    -V monofont='Ubuntu Mono'

GPROF_OPTS = \
    --format=perf \
    --strip --wrap \
    --skew=$(CALLGRAPH_THEME_SKEW) \
    --node-thres=$(CALLGRAPH_NODE_THRES_PCT) \
    --edge-thres=$(CALLGRAPH_EDGE_THRES_PCT)

DOT_OPTS = \
    -Tpdf \
    -Glabel="$(NAME) cpu profile $(DATE)" \
    -Gfontsize=24 \
    -Glabelloc=top 


# === Default target ===
all: doc


# === Documentation ===
doc: $(DOC_PDF)

$(DOC_PDF): $(SRC_MD)
	pandoc $(SRC_MD) $(PANDOC_OPTS) -o $@ 


# === Perf script generation ===
# Only create perf.script if it doesn't exist and perf.data is available
$(PERF_SCRIPT):
	@if [ -f $(PERF_SCRIPT) ]; then \
		echo "✔ $(PERF_SCRIPT) already exists, skipping generation."; \
	elif [ -f $(PERF_DATA) ]; then \
		echo "🧩 Generating $(PERF_SCRIPT) from $(PERF_DATA)..."; \
		perf script > $(PERF_SCRIPT); \
	else \
		echo "❌ Neither $(PERF_SCRIPT) nor $(PERF_DATA) exist. Cannot continue."; \
		exit 1; \
	fi


# === Callgraph ===
cg callgraph: $(CALL_PDF)

$(CALL_DOT): $(PERF_SCRIPT)
	gprof2dot $(GPROF_OPTS) --output=$@ $<

$(CALL_PDF): $(CALL_DOT)
	dot $(DOT_OPTS) -o $@ $<


# === Flamegraph ===
fg flamegraph: $(FLAME_SVG)

$(FLAME_SVG): $(PERF_SCRIPT)
	$(FLAMEGRAPH_DIR)/stackcollapse-perf.pl $< \
	| sed -E 's/^(__libc_start_main|_start);//; s/;(__libc_start_main|_start)//g; s/;;/;/g; s/^;//; s/;$$//' \
	| $(FLAMEGRAPH_DIR)/flamegraph.pl  --title "$(NAME) cpu profile $(DATE)" > $@


# === Cleanup ===
clean:
	rm -f *.svg *.dot *.pdf


# === Rebuild everything ===
rebuild: clean all

.PHONY: all doc cg callgraph fg flamegraph clean rebuild
