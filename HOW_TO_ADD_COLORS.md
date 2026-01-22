# How to Get Colored TreeMix Plots Like baseline_output.png

## The Problem You're Facing

Your current plot (`test.R`) shows:
- ❌ Black population labels (no colors)
- ❌ May have different spacing

The baseline_output.png shows:
- ✅ Colored population labels by region
- ✅ Professional formatting

## The Solution: Two Key Changes

### 1. Add the `o` Parameter (Population Colors)

The **critical missing piece** in your script is the `o` parameter. Here's the comparison:

#### ❌ Your Current Code (No Colors):
```R
plot_tree("baseline")
```

#### ✅ What You Need (With Colors):
```R
plot_tree("baseline",
          o = poporder)    # ← THIS adds colors!
```

The `o` parameter expects a dataframe with:
- **Column 1 (V1)**: Population names
- **Column 2 (V2)**: Colors (as hex codes or color names)

### 2. Create the `poporder` Dataframe

Here's the complete code to create colored labels:

```R
library(jsonlite)

# Load region mapping
region_map <- fromJSON("raw_data/region_mapping.json")

# Define colors for each region
region_colors <- c(
  "Subsaharan Africa" = "#E69F00",    # Orange
  "North Africa" = "#CC6600",         # Dark Orange
  "Europe" = "#0072B2",               # Blue
  "Asia" = "#009E73",                 # Green
  "South Asia" = "#117733",           # Dark Green
  "Central Asia" = "#44AA99",         # Teal
  "Oceania" = "#CC79A7",              # Pink
  "America" = "#D55E00",              # Red-Orange
  "Middle East" = "#882255"           # Purple
)

# Create population-to-color mapping
pops <- names(region_map)
regions <- unlist(region_map)
colors <- sapply(regions, function(r) {
  if (r %in% names(region_colors)) region_colors[[r]] else "black"
})

# Create poporder dataframe
poporder <- data.frame(
  V1 = pops,
  V2 = colors,
  stringsAsFactors = FALSE
)

# Now plot with colors
plot_tree("baseline", o = poporder)
```

---

## Complete Working Example

I've created **two new scripts** for you:

### Option 1: Quick Test (`test.R` - Updated)

**Location**: `src/treemix_tests/plot_scripts/test.R`

This creates TWO plots for comparison:
1. `baseline_simple.png` - Without colors (your current version)
2. `baseline_colored.png` - WITH colors (what you want)

**Run it**:
```bash
cd /home/inf-21-2024/projects/Treemix
Rscript src/treemix_tests/plot_scripts/test.R
```

**Output**: Creates plots in `experiments/baseline/plink_results/`

---

### Option 2: Publication Quality (`plot_baseline_with_colors.R` - New)

**Location**: `src/treemix_tests/plot_scripts/plot_baseline_with_colors.R`

This creates a **high-quality publication-ready plot** with:
- ✅ Colored population labels by region
- ✅ 4000×3500 pixels @ 600 DPI
- ✅ Legend showing region colors
- ✅ Professional formatting

**Run it**:
```bash
cd /home/inf-21-2024/projects/Treemix
Rscript src/treemix_tests/plot_scripts/plot_baseline_with_colors.R
```

**Output**: `experiments/baseline/plots/baseline_colored.png`

---

## Understanding the `o` Parameter Format

The `o` (poporder) parameter **MUST** be a dataframe with this exact structure:

```R
# Example of correct format:
poporder <- data.frame(
  V1 = c("French", "Yoruba", "Han", "Papuan"),
  V2 = c("#0072B2", "#E69F00", "#009E73", "#CC79A7")
)

# Column names MUST be V1 and V2
# V1 = population name (must match names in .treeout.gz file)
# V2 = color (hex code like "#0072B2" or name like "blue")
```

This tells TreeMix:
- "French" → plot in blue (#0072B2)
- "Yoruba" → plot in orange (#E69F00)
- "Han" → plot in green (#009E73)
- "Papuan" → plot in pink (#CC79A7)

---

## Step-by-Step: Fix Your Current Script

Here's how to modify your existing `test.R`:

### Current (No Colors):
```R
source("/home/inf-21-2024/miniconda3/envs/treemix_env/bin/plotting_funcs.R")
setwd("/home/inf-21-2024/projects/Treemix/experiments/baseline/plink_results")

plot_tree("baseline")
```

### Fixed (With Colors):
```R
library(jsonlite)
source("/home/inf-21-2024/miniconda3/envs/treemix_env/bin/plotting_funcs.R")
setwd("/home/inf-21-2024/projects/Treemix/experiments/baseline/plink_results")

# Load region mapping
region_map <- fromJSON("/home/inf-21-2024/projects/Treemix/raw_data/region_mapping.json")

# Define colors
region_colors <- c(
 "Africa" = "#e6550d",        # kräftiges orange
  "Europe" = "#3182bd",        # dunkleres blau
  "East Asia" = "#b8860b",     # dunkelgold statt gelb
  "Oceania" = "#e377c2",       # pink
  "America" = "#7f7f7f",       # grau
  "South Asia" = "#117733",    # dunkles grün
  "Middle East" = "#9467bd",   # violett
  "Central Asia" = "#20b2aa"   # türkis
)

# Create color mapping
poporder <- data.frame(
  V1 = names(region_map),
  V2 = sapply(unlist(region_map), function(r) {
    if (r %in% names(region_colors)) region_colors[[r]] else "black"
  }),
  stringsAsFactors = FALSE
)

# Plot with colors
png("baseline_colored.png", width = 4000, height = 3500, res = 600)
plot_tree("baseline", o = poporder, cex = 0.7)
dev.off()
```

---

## Tree Topology Issue

If your tree topology looks different from baseline_output.png, check:

### 1. Are you using the same TreeMix output file?
```bash
# Check what files exist
ls -lh experiments/baseline/plink_results/baseline.*

# You should have:
# - baseline.treeout.gz  ← This is what plot_tree() uses
# - baseline.vertices.gz
# - baseline.edges.gz
```

### 2. Did TreeMix run with the correct parameters?
```bash
# Check the TreeMix command that was used
# The baseline should be run with:
treemix -i baseline_treemix.gz \
        -o baseline \
        -m 0 \              # Number of migration edges (0 = no migration)
        -k 1000 \           # SNP block size
        -root San           # Root population
```

### 3. Is the input data correct?
The tree topology is determined by:
- Input data (`baseline_treemix.gz`)
- Root population (usually "San" for human data)
- Migration edges (`-m` parameter)

If you used different parameters, you'll get a different tree.

---

## Common Mistakes to Avoid

### ❌ Mistake 1: Wrong poporder format
```R
# WRONG - list instead of dataframe
poporder <- list(French = "blue", Yoruba = "orange")

# CORRECT
poporder <- data.frame(V1 = c("French", "Yoruba"), 
                      V2 = c("blue", "orange"))
```

### ❌ Mistake 2: Population names don't match
```R
# WRONG - if tree has "French" but you write "French_pop"
poporder <- data.frame(V1 = c("French_pop"), V2 = c("blue"))

# CORRECT - names must match exactly
poporder <- data.frame(V1 = c("French"), V2 = c("blue"))
```

### ❌ Mistake 3: Forgetting to load jsonlite
```R
# WRONG
region_map <- fromJSON("file.json")  # Error: function not found

# CORRECT
library(jsonlite)
region_map <- fromJSON("file.json")
```

---

## Quick Test Commands

### Test 1: Run the updated test.R
```bash
cd /home/inf-21-2024/projects/Treemix
Rscript src/treemix_tests/plot_scripts/test.R
```
**Expected output**: Two PNG files showing difference between colored and non-colored

### Test 2: Run the publication-quality script
```bash
cd /home/inf-21-2024/projects/Treemix
Rscript src/treemix_tests/plot_scripts/plot_baseline_with_colors.R
```
**Expected output**: High-resolution colored plot in `experiments/baseline/plots/`

---

## Modifying Your plotting_baseline.R Script

To add colors to your command-line plotting_baseline.R script, the key changes are:

**Around line 130-150**, modify the plotting function:

```R
# OLD (no colors):
plot_tree(
  stem,
  cex = TEXT_SIZE,
  arrow = ARROW_SIZE,
  plotmig = SHOW_MIGRATION,
  plotnames = SHOW_POP_NAMES
)

# NEW (with colors):
plot_tree(
  stem,
  o = poporder,           # ← ADD THIS LINE
  cex = TEXT_SIZE,
  arrow = ARROW_SIZE,
  plotmig = SHOW_MIGRATION,
  plotnames = SHOW_POP_NAMES
)
```

**Before the plot_tree() call**, add the color mapping code:

```R
# Load region mapping and create poporder
if (!is.null(CONTINENT_MAP)) {
  pop_colors <- data.frame(
    population = names(CONTINENT_MAP),
    region = unlist(CONTINENT_MAP),
    stringsAsFactors = FALSE
  )
  
  pop_colors$color <- sapply(pop_colors$region, function(r) {
    if (r %in% names(REGION_COLORS)) {
      return(REGION_COLORS[[r]])
    } else {
      return("black")
    }
  })
  
  poporder <- data.frame(
    V1 = pop_colors$population,
    V2 = pop_colors$color,
    stringsAsFactors = FALSE
  )
} else {
  poporder <- NA
}
```

---

## Summary: The One Critical Change

**The ONLY thing you're missing is the `o` parameter:**

```R
# Instead of:
plot_tree("baseline")

# Use:
plot_tree("baseline", o = poporder)
```

Where `poporder` is a dataframe mapping population names to colors.

That's it! Everything else (topology, layout, spacing) is handled automatically by TreeMix's `plot_tree()` function.

---

## Files Created for You

1. **`src/treemix_tests/plot_scripts/test.R`** (updated)
   - Simple comparison script
   - Shows both colored and non-colored versions

2. **`src/treemix_tests/plot_scripts/plot_baseline_with_colors.R`** (new)
   - Publication-quality script
   - High resolution with legend
   - Well-documented

Both scripts are ready to run immediately!
