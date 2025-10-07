# Makefile to build perf_howto_v1.0.pdf from README.md

# Input and output files
SRC = README.md
OUT = perf_howto_v1.0.pdf

# Pandoc options
PANDOC_OPTS = \
    -V papersize:A4 \
    -V documentclass=article \
    -V geometry:margin=1in \
    -V colorlinks \
    --toc \
    --toc-depth=2 \
    --pdf-engine=xelatex \
    -V monofont='Ubuntu Mono'

# Default target
all: $(OUT)

# Rule to build the PDF
$(OUT): $(SRC)
	pandoc $(SRC) -o $(OUT) $(PANDOC_OPTS)

# Clean generated files
clean:
	rm -f $(OUT)

# Convenience target to force rebuild
rebuild: clean all

.PHONY: all clean rebuild
