# === Configurable name prefix ===
NAME ?= perf
DATE := $(shell date +%Y-%m-%d)

# === Files ===
SRC_MD     = README.md
DOC_PDF    = perf_howto_v1.0.pdf
PERF_DATA  = perf.data
PERF_SCRIPT = perf.script
CALL_DOT   = $(NAME)_callgraph_$(DATE).dot
CALL_PDF   = $(NAME)_callgraph_$(DATE).pdf
FLAME_SVG  = $(NAME)_flamegraph_$(DATE).svg

# === Flamegraph path (set this to your Flamegraph directory) ===
FG ?= $(HOME)/git/FlameGraph

# === Pandoc options ===
PANDOC_OPTS = \
    -V papersize:A4 \
    -V documentclass=article \
    -V geometry:margin=1in \
    -V colorlinks \
    --toc \
    --toc-depth=2 \
    --pdf-engine=xelatex \
    -V monofont='Ubuntu Mono'

# === Default target ===
all: doc

# === Documentation ===
doc: $(DOC_PDF)

$(DOC_PDF): $(SRC_MD)
	pandoc $(SRC_MD) -o $(DOC_PDF) $(PANDOC_OPTS)

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
	cat $(PERF_SCRIPT) | gprof2dot -f perf > $(CALL_DOT)

$(CALL_PDF): $(CALL_DOT)
	cat $(CALL_DOT) | dot -Tpdf -o $(CALL_PDF)  -Glabel="$(NAME) cpu profile $(DATE)" -Gfontsize=24 -Glabelloc=top

# === Flamegraph ===
fg flamegraph: $(FLAME_SVG)

$(FLAME_SVG): $(PERF_SCRIPT)
	cat $(PERF_SCRIPT) | \
	$(FG)/stackcollapse-perf.pl | \
	$(FG)/flamegraph.pl  --title "$(NAME) cpu profile $(DATE)" >> $(FLAME_SVG)

# === Cleanup ===
clean:
	rm -f *.svg *.dot *.pdf

# === Rebuild everything ===
rebuild: clean all

.PHONY: all doc cg callgraph fg flamegraph clean rebuild
