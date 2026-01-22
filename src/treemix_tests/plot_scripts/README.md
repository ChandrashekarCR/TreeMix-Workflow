# TreeMix Plotting Scripts

High-quality plotting scripts for TreeMix phylogenetic trees with continental region colors and legends.

## Files

- **plotting_funcs.R** - Core TreeMix plotting functions (bug-free custom implementation)
- **plot_with_legend.R** - Main plotting script with region color legend support

## Quick Start

### Basic Usage

Plot a TreeMix tree with colored populations and legend:

```bash
Rscript plot_with_legend.R <stem> [output_file]
```

### Example

```bash
# Plot with default settings (colors + legend in top right)
Rscript plot_with_legend.R plots/appendix/m_test/baseline_m_2_output

# Custom output file
Rscript plot_with_legend.R plots/appendix/m_test/baseline_m_2_output my_plot.pdf

# Change legend position
Rscript plot_with_legend.R plots/appendix/m_test/baseline_m_2_output --legend-pos topleft
```

## Options

### Display Options
- `--no-colors` - Plot in black and white (no region colors)
- `--no-legend` - Don't show the region legend
- `--no-mig` - Don't show migration edges

### Legend Position
- `--legend-pos <position>` - Set legend position:
  - `topright` (default)
  - `topleft`
  - `bottomright`
  - `bottomleft`

### Output Options
- `--png` - Save as PNG instead of PDF
- `--width <n>` - Plot width in inches (default: 10)
- `--height <n>` - Plot height in inches (default: 8)
- `--cex <n>` - Text size multiplier (default: 0.8)

## Examples

### 1. Standard Plot with Legend
```bash
Rscript plot_with_legend.R plots/appendix/m_test/baseline_m_2_output output.pdf
```
Creates a PDF with:
- Population labels colored by continental region
- Migration edges shown
- Legend in top right corner
- High-quality formatting

### 2. Large PNG for Presentation
```bash
Rscript plot_with_legend.R plots/appendix/m_test/baseline_m_2_output \
  presentation.png \
  --png \
  --width 14 \
  --height 10 \
  --cex 1.0
```

### 3. Plot Without Migrations
```bash
Rscript plot_with_legend.R plots/appendix/m_test/baseline_m_2_output \
  no_mig.pdf \
  --no-mig
```

### 4. Black and White Plot
```bash
Rscript plot_with_legend.R plots/appendix/m_test/baseline_m_2_output \
  bw_plot.pdf \
  --no-colors \
  --no-legend
```

### 5. Custom Legend Position
```bash
Rscript plot_with_legend.R plots/appendix/m_test/baseline_m_2_output \
  custom.pdf \
  --legend-pos bottomleft
```

## Color Scheme

Populations are colored by continental region:

| Region | Color | Hex Code |
|--------|-------|----------|
| Subsaharan Africa | Red | #E41A1C |
| North Africa | Orange | #FF7F00 |
| Europe | Green | #4DAF4A |
| Oceania | Purple | #984EA3 |
| America | Pink | #F781BF |
| Asia | Blue | #377EB8 |
| Middle East | Brown | #A65628 |

Region mappings are defined in: `/home/inf-21-2024/projects/Treemix/raw_data/region_mapping.json`

## Using in R Scripts

You can also use the plotting functions directly in R:

```r
# Source the functions
source("plot_with_legend.R")

# Plot with default settings
plot_treemix_with_legend(
  stem = "plots/appendix/m_test/baseline_m_2_output",
  output_file = "my_plot.pdf"
)

# Customize settings
plot_treemix_with_legend(
  stem = "plots/appendix/m_test/baseline_m_2_output",
  output_file = "custom_plot.pdf",
  use_colors = TRUE,
  add_legend = TRUE,
  legend_pos = "topleft",
  plot_migrations = TRUE,
  width = 12,
  height = 9,
  cex = 0.9,
  lwd = 2.5
)

# Add legend to existing plot
add_region_legend(x = "topright", cex = 0.7)
```

## Plot Quality Settings

The scripts use optimized settings for publication-quality plots:

- **Text size (cex)**: 0.8 (adjustable)
- **Line width (lwd)**: 2
- **Font**: Bold (font=2) for population labels
- **Resolution**: 150 DPI for PNG outputs
- **Default size**: 10×8 inches
- **Legend**: Transparent background with region colors

## Input Files Required

The TreeMix output stem should point to files without extensions. Required files:
- `<stem>.vertices.gz` - Vertex data
- `<stem>.edges.gz` - Edge data
- `<stem>.covse.gz` - Covariance standard errors

Example:
- If files are `baseline_m_2_output.vertices.gz`, `baseline_m_2_output.edges.gz`, etc.
- Use stem: `baseline_m_2_output`

## Troubleshooting

### Error: "TreeMix output files not found"
Check that your stem path is correct and points to the files without extension.

### Error: "Region mapping file not found"
The script looks for region mappings in:
`/home/inf-21-2024/projects/Treemix/raw_data/region_mapping.json`

If this file doesn't exist, populations will be plotted in black.

### Colors not showing
Make sure:
1. Region mapping JSON file exists
2. `--no-colors` option is not used
3. Population names in TreeMix match names in region_mapping.json

## Dependencies

Required R packages:
- jsonlite
- RColorBrewer

Install with:
```r
install.packages(c("jsonlite", "RColorBrewer"))
```
