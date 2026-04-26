import pytest
import os
import json
import gzip
from unittest.mock import patch, MagicMock
from io import StringIO

# Import the modules we want to test
import sys

sys.path.insert(
    0, os.path.join(os.path.dirname(__file__), "..", "src", "treemix_tests", "analysis")
)
from find_differences import TreeComparator, load_trees, extract_migration_edges_from_treeout, main


class TestTreeComparator:
    """Test suite for TreeComparator class."""

    def test_tree_comparator_initialization(self, sample_tree_files, temp_dir):
        """Test that TreeComparator initializes correctly."""
        tree1_path, tree2_path = sample_tree_files
        tree1, tree2, migration_edges = load_trees(tree1_path, tree2_path)

        comparator = TreeComparator(tree1, tree2, temp_dir, migration_edges, "test")

        assert comparator.tree1 is not None
        assert comparator.tree2 is not None
        assert comparator.output_dir == temp_dir
        assert comparator.basename == "test"
        assert isinstance(comparator.results, dict)

    def test_calculate_distances(self, sample_tree_files, temp_dir):
        """Test distance calculations between trees."""
        tree1_path, tree2_path = sample_tree_files
        tree1, tree2, migration_edges = load_trees(tree1_path, tree2_path)

        comparator = TreeComparator(tree1, tree2, temp_dir, migration_edges, "test")
        distances = comparator._calculate_distances()

        assert "jaccard_index" in distances
        assert "rf_distance" in distances
        assert "bsd" in distances
        assert "taxa_info" in distances
        assert distances["taxa_info"]["common_taxa_count"] > 0

    def test_compare_trees_full_workflow(self, sample_tree_files, temp_dir):
        """Test the complete tree comparison workflow."""
        tree1_path, tree2_path = sample_tree_files
        tree1, tree2, migration_edges = load_trees(tree1_path, tree2_path)

        comparator = TreeComparator(tree1, tree2, temp_dir, migration_edges, "test")
        results = comparator.compare_trees(pruned=True)

        # Check that all expected result sections are present
        assert "global_distances" in results
        assert "global_distances_pruned" in results
        assert "sibling_comparisons" in results
        assert "root_distances" in results
        assert "pairwise_distances" in results

    def test_normalized_rf_calculation(self, sample_tree_files, temp_dir):
        """Test normalized RF distance calculation."""
        tree1_path, tree2_path = sample_tree_files
        tree1, tree2, migration_edges = load_trees(tree1_path, tree2_path)

        comparator = TreeComparator(tree1, tree2, temp_dir, migration_edges, "test")

        # Test with known values
        normalized_rf = comparator._normalized_rf(pruned_rf=4, shared_taxa=5, rooted=True)
        expected_max_rf = 2 * (5 - 2)  # 6 for rooted trees
        expected_normalized = 4 / 6

        assert abs(normalized_rf - expected_normalized) < 1e-10

    def test_get_sibling_taxa(self, sample_tree_files, temp_dir):
        """Test sibling taxa extraction."""
        tree1_path, tree2_path = sample_tree_files
        tree1, tree2, migration_edges = load_trees(tree1_path, tree2_path)

        comparator = TreeComparator(tree1, tree2, temp_dir, migration_edges, "test")

        # Test with Pop1 - should have Pop2 as sibling based on our sample tree
        siblings = comparator._get_sibling_taxa(tree1, "Pop1")
        assert isinstance(siblings, set)
        assert "Pop2" in siblings


class TestLoadTrees:
    """Test suite for tree loading functionality."""

    def test_load_trees_basic(self, sample_tree_files):
        """Test basic tree loading from gzipped files."""
        tree1_path, tree2_path = sample_tree_files
        tree1, tree2, migration_edges = load_trees(tree1_path, tree2_path)

        assert tree1 is not None
        assert tree2 is not None
        assert isinstance(migration_edges, dict)

    def test_load_trees_with_migration_data(self, temp_dir, sample_tree1):
        """Test loading trees with migration edge data."""
        # Create a tree file with migration data
        tree_with_migration = sample_tree1 + "\n0.5 0.1 0.2 0.3 (Pop1,Pop2) (Pop3,Pop4)"

        migration_path = os.path.join(temp_dir, "tree_with_migration.treeout.gz")
        baseline_path = os.path.join(temp_dir, "baseline.treeout.gz")

        with gzip.open(migration_path, "wt", encoding="utf-8") as f:
            f.write(tree_with_migration)

        with gzip.open(baseline_path, "wt", encoding="utf-8") as f:
            f.write(sample_tree1)

        tree1, tree2, migration_edges = load_trees(baseline_path, migration_path)

        assert tree1 is not None
        assert tree2 is not None
        assert len(migration_edges) > 0


class TestMigrationEdgeExtraction:
    """Test suite for migration edge extraction."""

    def test_extract_migration_edges_valid_data(self):
        """Test extraction of migration edges from valid data."""
        sample_data = """(Pop1:0.1,Pop2:0.1);
0.5 0.1 0.2 0.3 (Pop1,Pop2) (Pop3,Pop4)
0.3 0.05 0.15 0.25 (Pop3) (Pop5)"""

        edges = extract_migration_edges_from_treeout(sample_data)

        assert len(edges) == 2
        assert edges[0]["weight"] == 0.5
        assert "Pop1" in edges[0]["source"] or "Pop2" in edges[0]["source"]

    def test_extract_migration_edges_malformed_data(self):
        """Test handling of malformed migration data."""
        malformed_data = """(Pop1:0.1,Pop2:0.1);
incomplete line
0.3 incomplete"""

        edges = extract_migration_edges_from_treeout(malformed_data)

        # Should handle malformed lines gracefully
        assert isinstance(edges, list)


class TestMainFunction:
    """Test suite for main function."""

    @patch(
        "sys.argv",
        [
            "find_differences.py",
            "-i",
            "baseline.gz",
            "-c",
            "comparison.gz",
            "-o",
            "output",
            "-b",
            "test",
        ],
    )
    def test_main_with_mocked_args(self, sample_tree_files, temp_dir):
        """Test main function with mocked command line arguments."""
        tree1_path, tree2_path = sample_tree_files

        # Test that main can be called without crashing
        main(tree1_path, tree2_path, temp_dir, "test", pruned=True)

        # Check that output files are created
        json_file = os.path.join(temp_dir, "test_tree_comparison_results.json")
        txt_file = os.path.join(temp_dir, "test_differences.txt")

        assert os.path.exists(json_file)
        assert os.path.exists(txt_file)


class TestEdgeCases:
    """Test suite for edge cases and error handling."""

    def test_empty_migration_edges(self, sample_tree_files, temp_dir):
        """Test handling when no migration edges are present."""
        tree1_path, tree2_path = sample_tree_files
        tree1, tree2, migration_edges = load_trees(tree1_path, tree2_path)

        comparator = TreeComparator(tree1, tree2, temp_dir, {}, "test")
        results = comparator.compare_trees()

        assert "migration_edges" not in results

    def test_trees_with_no_common_taxa(self, temp_dir):
        """Test behavior when trees have no common taxa."""
        # Create trees with completely different taxa
        tree1_str = "(Pop1:0.1,Pop2:0.1);"
        tree2_str = "(Pop3:0.1,Pop4:0.1);"

        tree1_path = os.path.join(temp_dir, "tree1.treeout.gz")
        tree2_path = os.path.join(temp_dir, "tree2.treeout.gz")

        with gzip.open(tree1_path, "wt", encoding="utf-8") as f:
            f.write(tree1_str)

        with gzip.open(tree2_path, "wt", encoding="utf-8") as f:
            f.write(tree2_str)

        tree1, tree2, migration_edges = load_trees(tree1_path, tree2_path)
        comparator = TreeComparator(tree1, tree2, temp_dir, migration_edges, "test")
        results = comparator.compare_trees()

        # Should handle this gracefully
        assert results["global_distances"]["taxa_info"]["common_taxa_count"] == 0
