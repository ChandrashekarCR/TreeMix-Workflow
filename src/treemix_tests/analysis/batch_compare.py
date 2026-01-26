"""
Batch Tree Comparison Script

This script automates the comparison of TreeMix output files between experiments and baseline runs.
For each experimental tree, it finds the corresponding baseline tree (matching migration number)
and generates comparison results including:
- Populations with different sibling relationships
- Tree distance metrics
- Migration edge information

Output files for each comparison:
- {basename}_differences.txt: List of populations that changed
- {basename}_tree_comparison_results.json: Full comparison metrics
- {basename}_migration_edges.json: Migration edge details (if present)
"""

import glob
import re
from pathlib import Path

from find_differences import compare_two_trees


def compare_experiment_to_baseline(experiment_path: str, baseline_folder: str, pruned: bool = True) -> None:
    """
    Compare all TreeMix output files in an experiment folder to their corresponding baseline files.
    
    The comparison matches files based on migration number (e.g., m_6). If no migration number is found,
    it uses the default baseline file (baseline_seed1_output.treeout.gz).
    
    Args:
        experiment_path: Path to experiment folder containing treemix_output/
        baseline_folder: Path to folder containing baseline tree files
        pruned: If True, prune trees to common taxa before comparison (default: True)
        
    Output:
        Creates comparison_results/ folder in experiment_path with comparison files
    """
    # Setup paths
    treemix_output_dir = Path(experiment_path) / "treemix_output"
    comparison_output_dir = Path(experiment_path) / "comparison_results"
    comparison_output_dir.mkdir(parents=True, exist_ok=True)
    baseline_dir = Path(baseline_folder)

    # Process each tree file in the experiment
    for experiment_tree_file in treemix_output_dir.glob("*.treeout.gz"):
        # Extract migration number from filename (e.g., "m_6" from "exp_m_6_output.treeout.gz")
        migration_match = re.search(r"m_\d+", experiment_tree_file.name)
        
        if migration_match:
            migration_value = migration_match.group()  # e.g., "m_6"
            baseline_filename = f"baseline_{migration_value}_output.treeout.gz"
        else:
            # Default baseline if no migration number found
            baseline_filename = "baseline_seed1_output.treeout.gz"

        baseline_tree_file = baseline_dir / baseline_filename

        # Skip if baseline doesn't exist
        if not baseline_tree_file.exists():
            print(f"⚠️  Skipping {experiment_tree_file.name}: baseline not found ({baseline_filename})")
            continue

        # Create output basename (remove .treeout.gz extension)
        output_basename = experiment_tree_file.stem.replace(".treeout", "")

        print(f"📊 Comparing: {experiment_tree_file.name} vs {baseline_filename}")

        # Run comparison
        compare_two_trees(
            baseline_path=str(baseline_tree_file),
            experimental_path=str(experiment_tree_file),
            output_dir=str(comparison_output_dir),
            basename=output_basename,
            pruned=pruned
        )
        
    print(f"✅ All comparisons complete! Results in: {comparison_output_dir}")


if __name__ == "__main__":
    # Example usage: Compare specific experiment
    compare_experiment_to_baseline(
        experiment_path="../../23062025_results/experiments/experiment_61",
        baseline_folder="../../23062025_results/experiments/baseline/treemix_output/",
        pruned=True
    )
    

