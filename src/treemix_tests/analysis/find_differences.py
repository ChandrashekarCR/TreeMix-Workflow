# Importing Libraries
import gzip
import json
import os
import argparse
import sys
from collections import Counter, defaultdict
from io import StringIO
from pathlib import Path
from typing import Dict, List, Set, Tuple, Any, Optional

import numpy as np
import pandas as pd
from dendropy import Tree, TaxonNamespace
from dendropy.calculate.treecompare import symmetric_difference, euclidean_distance

class TreeComparator:
    """
    A class to compare two phylogenetic trees and analyze their differences.
    """
    def __init__(self, tree1: Tree, tree2: Tree, output_dir: str, migration_edges: Dict[str, List[Dict[str, Any]]], basename: str = ""):
        """
        Initialize the TreeComparator with two trees and an output directory.
        
        Args:
            tree1: First phylogenetic tree
            tree2: Second phylogenetic tree
            output_dir: Directory to write results to
            migration_edges: Dictionary mapping file paths to their migration edges
        """
        self.tree1 = tree1
        self.tree2 = tree2
        self.output_dir = output_dir
        self.results = {}
        self.migration_edges = migration_edges
        self.basename = basename
        
    def compare_trees(self, pruned: bool = False) -> Dict[str, Any]:
        """
        Perform a comprehensive comparison of the two trees.
        
        Args:
            pruned: Whether to prune trees to common taxa
            
        Returns:
            Dictionary containing all comparison results
        """
        # Get common taxa
        labels1 = set(leaf.taxon.label for leaf in self.tree1.leaf_nodes())
        labels2 = set(leaf.taxon.label for leaf in self.tree2.leaf_nodes())
        common_taxa = labels1 & labels2

        # Calculate global distances
        self.results["global_distances"] = self._calculate_distances()
        
        if pruned:
            self.tree1 = self.tree1.extract_tree_with_taxa_labels(common_taxa)
            self.tree2 = self.tree2.extract_tree_with_taxa_labels(common_taxa)
            
            # Calculate global distances
            self.results["global_distances_pruned"] = self._calculate_distances()

        
        # Compare siblings
        self.results["sibling_comparisons"] = self._compare_siblings(common_taxa)
        
        # Calculate root-to-tip distances
        self.results["root_distances"] = self._compare_root_distances()
        
        # Calculate pairwise distances
        self.results["pairwise_distances"] = self._compare_pairwise_distances(common_taxa)
        
        # Add migration edges to results if present
        if self.migration_edges:
            self.results["migration_edges"] = self.migration_edges
        
        # Write results
        self._write_results()
        
        return self.results

    def _normalized_rf(self, pruned_rf: int, shared_taxa: int, rooted: bool = True) -> float:
        """
        Compute normalized Robinson-Foulds (RF) distance.

        Parameters:
        - pruned_rf (int): The RF distance between the two pruned trees.
        - shared_taxa (int): Number of taxa shared between the two trees.
        - rooted (bool): Set to True if trees are rooted, False if unrooted.

        Returns:
        - float: Normalized RF distance (0 to 1).
        """
        if shared_taxa < 3:
            raise ValueError("At least 3 shared taxa are required for a valid tree comparison.")

        if rooted:
            max_rf = 2 * (shared_taxa - 2)
        else:
            max_rf = 2 * (shared_taxa - 3)

        if max_rf <= 0:
            return 0.0  # avoid division by zero or invalid negative RF
        return pruned_rf / max_rf

    def _normalize_bsd(self, bsd: float, shared_taxa: int, rooted: bool = True) -> float:
        """
        Normalize BSD by the squared total branch length of the pruned baseline tree.
        """
        if shared_taxa < 3:
            return 0.0  # Prevent division by zero
        branches = 2 * shared_taxa - 2 if rooted else 2 * shared_taxa - 3
        return bsd / branches

    def _calculate_distances(self) -> Dict[str, Any]:
        """Calculate global distance metrics between trees."""
        labels1 = set(leaf.taxon.label for leaf in self.tree1.leaf_nodes())
        labels2 = set(leaf.taxon.label for leaf in self.tree2.leaf_nodes())
        
        intersection = labels1 & labels2
        union = labels1 | labels2
        rf_distance = symmetric_difference(self.tree1, self.tree2)
        bsd = euclidean_distance(self.tree1, self.tree2)
        return {
            "jaccard_index": len(intersection) / len(union),
            "same_taxa": labels1 == labels2,
            "rf_distance": rf_distance,
            "normalized_rf": self._normalized_rf(rf_distance, len(intersection)),
            "bsd": bsd,
            "normalized_bsd": self._normalize_bsd(bsd, len(intersection) ),
            "taxa_info": {
                "tree1_taxa_count": len(labels1),
                "tree2_taxa_count": len(labels2),
                "common_taxa_count": len(intersection),
                "total_unique_taxa": len(union)
            }
        }
        
    def _compare_siblings(self, common_taxa: Set[str]) -> Dict[str, Any]:
        """Compare sibling relationships for all common taxa."""
        different_pops = []
        sibling_comparisons = {}
        
        for pop in common_taxa:
            result = self._compare_single_taxon(pop)
            if result:
                different_pops.append(pop)
                sibling_comparisons[pop] = result
                
        return {
            "different_populations": different_pops,
            "comparisons": sibling_comparisons
        }
        
    def _compare_single_taxon(self, pop: str) -> Optional[Dict[str, Any]]:
        """Compare sibling relationships for a single taxon."""
        siblings1 = self._get_sibling_taxa(self.tree1, pop)
        siblings2 = self._get_sibling_taxa(self.tree2, pop)
        
        intersection = siblings1 & siblings2
        union = siblings1 | siblings2
        
        jaccard_index = len(intersection) / len(union) if union else 0
        
        if jaccard_index == 1:
            return None
            
        return {
            "siblings1": list(siblings1),
            "siblings2": list(siblings2),
            "jaccard_index": jaccard_index,
            "differences": {
                "only_in_tree1": list(siblings1 - siblings2),
                "only_in_tree2": list(siblings2 - siblings1)
            }
        }
        
    def _compare_root_distances(self) -> Tuple[Dict, Dict, Dict[str, Any]]:
        """Compare root-to-tip distances between trees."""
        dist1 = self._taxon_distances(self.tree1)
        dist2 = self._taxon_distances(self.tree2)
        
        return self._compute_z_score(dist1, dist2)
        
    def _compare_pairwise_distances(self, common_taxa: List[str]) -> Dict[str, Any]:
        """Compare pairwise distances between trees."""
        pd1 = self._pairwise_distances(self.tree1, common_taxa)
        pd2 = self._pairwise_distances(self.tree2, common_taxa)
        
        return self._compute_z_score(pd1, pd2)
        
    def _write_results(self) -> None:
        """Write all results to files."""
        # Write JSON results
        json_path = os.path.join(self.output_dir, f"{self.basename}_tree_comparison_results.json")
        with open(json_path, "w") as f:
            json.dump(self.results, f, indent=2)
            
        # Write differences.txt
        txt_path = os.path.join(self.output_dir,  f"{self.basename}_differences.txt")
        with open(txt_path, "w") as f:
            for pop in self.results["sibling_comparisons"]["different_populations"]:
                f.write(f"{pop}\n")
                
        # Write migration edges if present
        if self.migration_edges:
            migration_path = os.path.join(self.output_dir,  f"{self.basename}_migration_edges.json")
            with open(migration_path, "w") as f:
                json.dump(self.migration_edges, f, indent=2)
        
    @staticmethod
    def _get_sibling_taxa(tree: Tree, taxon_label: str) -> Set[str]:
        """Get sibling taxa for a given taxon."""
        node = tree.find_node_with_taxon_label(taxon_label)
        if node is None or node.parent_node is None:
            return set()
        return {leaf.taxon.label for leaf in node.parent_node.leaf_nodes() if leaf.taxon.label != taxon_label}
        
    @staticmethod
    def _taxon_distances(tree: Tree) -> Dict[str, float]:
        """Calculate distances from root to each taxon."""
        distances = {}
        for leaf in tree.leaf_node_iter():
            if not leaf.taxon or not leaf.taxon.label:
                continue
            distances[leaf.taxon.label] = leaf.distance_from_root()
        return distances
        
    @staticmethod
    def _pairwise_distances(tree: Tree, taxa: Set[str]) -> Dict[Tuple[str, str], float]:
        """
        Calculate pairwise distances between taxa.
        
        Args:
            tree: Phylogenetic tree to calculate distances in
            taxa: Set of taxon labels to calculate pairwise distances for
            
        Returns:
            Dictionary mapping taxon pairs to their distances
        """
        distances = {}
        # Convert set to sorted list for consistent ordering
        taxa_list = sorted(list(taxa))
        
        for i in range(len(taxa_list)):
            for j in range(i + 1, len(taxa_list)):
                a, b = taxa_list[i], taxa_list[j]
                node1 = tree.find_node_with_taxon_label(a)
                node2 = tree.find_node_with_taxon_label(b)
                mrca = tree.mrca(taxon_labels=[a, b])

                if all([node1, node2, mrca]):
                    d = (
                        node1.distance_from_root()
                        + node2.distance_from_root()
                        - 2 * mrca.distance_from_root()
                    )
                    distances[(a, b)] = d
        return distances
        
    @staticmethod
    def _compute_z_score(
        dist1: Dict[str, float],
        dist2: Dict[str, float]
    ) -> Dict[str, Any]:
        """Compute Z-scores for differences between two distance distributions."""
        common_keys = set(dist1.keys()) & set(dist2.keys())
        deltas = [dist1[k] - dist2[k] for k in common_keys]
        
        mean_delta = np.mean(deltas)
        std_delta = np.std(deltas)
        
        differences = []
        for k, delta in zip(common_keys, deltas):
            z = (delta - mean_delta) / std_delta if std_delta != 0 else 0
            differences.append((k, delta, z))
                
        return {
            "mean_delta": mean_delta,
            "std_delta": std_delta,
            "differences": differences
        }

def load_trees(baseline_path: str, tree_path: str) -> Tuple[Tree, Tree, Dict[str, List[Dict[str, Any]]]]:
    """
    Load two trees from gzipped files.
    
    Args:
        baseline_path: Path to the baseline tree file
        tree_path: Path to the comparison tree file
        
    Returns:
        Tuple of (baseline_tree, comparison_tree, migration_edges)
        migration_edges is a dictionary mapping file paths to their migration edges
    """
    taxa = TaxonNamespace()
    migration_edges = {}
    
    def load_single_tree(path: str) -> Tree:
        with gzip.open(path, "rt", encoding='utf-8') as f:
            tree_str = f.read().strip()
        try:
            return Tree.get(file=StringIO(tree_str), schema="newick", taxon_namespace=taxa, rooting="force-rooted")
        except Exception:
            # Handle a migration case 
            if ";" in tree_str:
                nonlocal migration_edges
                migration_edges[path] = extract_migration_edges_from_treeout(tree_str)
                tree_str = tree_str.split(";")[0] + ";"
            return Tree.get(file=StringIO(tree_str), schema="newick", taxon_namespace=taxa, rooting="force-rooted")
            
    return load_single_tree(baseline_path), load_single_tree(tree_path), migration_edges

def extract_migration_edges_from_treeout(file: str) -> List[Dict[str, Any]]:
    """
    Extract migration edges from a treeout file.
    
    Args:
        file: Content of the treeout file as a string
        
    Returns:
        List of dictionaries containing migration edge information:
        - weight: Migration weight
        - source: List of source taxa
        - target: List of target taxa
    """
    lines = file.split(";")[1].split("\n")
    migration_edges = []
    
    for line in lines:
        if not line.strip():
            continue  # skip empty lines
            
        parts = line.strip().split()
        if len(parts) != 6:
            continue  # skip malformed lines
            
        try:
            weight = float(parts[0])
            source_newick = parts[4]
            target_newick = parts[5]
            
            # Parse source/target Newick strings with dendropy
            source_tree = Tree.get(data=source_newick + ";", schema="newick")
            target_tree = Tree.get(data=target_newick + ";", schema="newick")
            
            # Get leaf names (taxa) from trees
            source_taxa = [leaf.taxon.label for leaf in source_tree.leaf_nodes()]
            target_taxa = [leaf.taxon.label for leaf in target_tree.leaf_nodes()]
            
            migration_edges.append({
                "weight": weight,
                "source": source_taxa,
                "target": target_taxa
            })
        except Exception as e:
            print(f"Error parsing line: {line}\n{e}")
            
    return migration_edges

def main(baseline_path: str, tree_path: str, output_dir: str, basename: str,  pruned: bool = False) -> None:
    """
    Main function to compare two trees and write results.
    
    Args:
        baseline_path: Path to the baseline tree file
        tree_path: Path to the comparison tree file
        output_dir: Directory to write results to
        pruned: Whether to prune trees to common taxa
    """
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    # Load trees
    tree1, tree2, migration_edges = load_trees(baseline_path, tree_path)
    
    # Compare trees
    print(f"Comparing trees: {baseline_path} vs. {tree_path}")

    comparator = TreeComparator(tree1, tree2, output_dir, migration_edges, basename)
    comparator.compare_trees(pruned=pruned)

    print("Done!")
    print("Results written to:", output_dir)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog=f"{os.path.basename(sys.argv[0])}",
                                     usage="python3 find_differences.py -i <baseline_tree_path> -c <comparison_tree_path>," \
                                     "-o <output_directory> -b <basename>",description="A program to compare the experiments tree generated to the baseline trees.")
    parser.add_argument('-i',dest='--input_file',help='Enter the path of the baseline treemix output file.')
    parser.add_argument('-c',dest='--comparison_tree',help='Enter the path of the tree you wich to compare.')
    parser.add_argument('-o',dest='--output_dir',help='Enter the output directory to store the results.')
    parser.add_argument('-b',dest='--basename',help='Enter the basename of the output file.')
    args = parser.parse_args()


    main(
        baseline_path= args.input_file,#"/home/inf-21-2024/projects/treemix_project/plots/appendix/m_test/baseline_m_1_output.treeout.gz",
        tree_path= args.comparison_tree,#"/home/inf-21-2024/projects/treemix_project/plots/appendix/m_test/baseline_m_6_output.treeout.gz",
        output_dir= args.output_dir,#"comparision_results",
        basename=args.basename,#"test_comparison",
        pruned=True
    )
