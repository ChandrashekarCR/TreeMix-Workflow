#!/bin/bash
#
# Example Usage of TreeMix Plotting Scripts
# This file shows common use cases for plot_with_legend.R
#

SCRIPT_DIR="/home/inf-21-2024/projects/Treemix/src/treemix_tests/plot_scripts"
TREEMIX_STEM="/home/inf-21-2024/projects/Treemix/plots/appendix/m_test/baseline_m_2_output"
OUTPUT_DIR="/home/inf-21-2024/projects/Treemix/plots"

cd "$SCRIPT_DIR"

echo "=== TreeMix Plotting Examples ==="
echo ""

# Example 1: Basic plot with legend in top right
echo "1. Creating plot with legend in top right (default)..."
Rscript plot_with_legend.R "$TREEMIX_STEM" "$OUTPUT_DIR/example1_default.pdf"

# Example 2: Legend in different position
echo "2. Creating plot with legend in top left..."
Rscript plot_with_legend.R "$TREEMIX_STEM" "$OUTPUT_DIR/example2_topleft.pdf" --legend-pos topleft

# Example 3: No legend
echo "3. Creating plot without legend..."
Rscript plot_with_legend.R "$TREEMIX_STEM" "$OUTPUT_DIR/example3_no_legend.pdf" --no-legend

# Example 4: Black and white (no colors or legend)
echo "4. Creating black and white plot..."
Rscript plot_with_legend.R "$TREEMIX_STEM" "$OUTPUT_DIR/example4_bw.pdf" --no-colors --no-legend

# Example 5: Without migration edges
echo "5. Creating plot without migrations..."
Rscript plot_with_legend.R "$TREEMIX_STEM" "$OUTPUT_DIR/example5_no_mig.pdf" --no-mig

# Example 6: Large PNG for presentation
echo "6. Creating large PNG..."
Rscript plot_with_legend.R "$TREEMIX_STEM" "$OUTPUT_DIR/example6_large.png" \
  --png --width 14 --height 10 --cex 1.0

echo ""
echo "=== All example plots created in $OUTPUT_DIR ==="
ls -lh "$OUTPUT_DIR"/example*.pdf "$OUTPUT_DIR"/example*.png 2>/dev/null
