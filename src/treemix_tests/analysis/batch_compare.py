import os
import glob
import re
from pathlib import Path
from typing import List, Tuple, Dict

from find_differences import main as compare_trees

def automate_tree_comparisons(experiment_path, baseline_folder, pruned=True):
    """
    Compares all treeout files in an experiment's treemix_output folder with the corresponding baseline,
    based on the migration value (e.g., m_6). Baseline files must follow the pattern: baseline_m_X_output.treeout.gz
    """
    treemix_dir = Path(experiment_path) / "treemix_output"
    comparison_dir = Path(experiment_path) / "comparision_results"
    comparison_dir.mkdir(parents=True, exist_ok=True)

    for tree_file in treemix_dir.glob("*.treeout.gz"):
        baseline_filename = f"baseline_seed1_output.treeout.gz"
        migration = re.search(r"m_\d+", tree_file.name)
        if  migration:
            print(f"Migration found")
            m_value = migration.group()  # e.g., 'm_6
            baseline_filename = f"baseline_{m_value}_output.treeout.gz"
            print(f"Baseline filename: {baseline_filename}")

        baseline_path = Path(baseline_folder) / baseline_filename

        if not baseline_path.exists():
            #print(f"⚠️ Baseline file not found for {m_value}: {baseline_path}")
            continue

        # Build basename and output directory
        basename = tree_file.stem.replace(".treeout", "")  # Removes .treeout.gz
        output_dir = comparison_dir

        print(f"✅ Comparing {tree_file.name} with {baseline_filename}...")
        print(f"Output directory: {output_dir} with basename: {basename}...")

        compare_trees(
            baseline_path=str(baseline_path),
            tree_path=str(tree_file),
            output_dir=str(output_dir),
            pruned=pruned,
            basename=basename
        )
if __name__ == "__main__":
   for dir in glob.glob("../../23062025_results/experiments/experiment_*"):
        print(dir)
        #automate_tree_comparisons(dir,"../../23062025_results/experiments/baseline/treemix_output/", pruned=True )
   automate_tree_comparisons("../../23062025_results/experiments/experiment_61", "../../23062025_results/experiments/baseline/treemix_output/", pruned=True)


