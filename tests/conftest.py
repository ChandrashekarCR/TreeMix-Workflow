import pytest
import tempfile
import os
import gzip
from pathlib import Path

@pytest.fixture(scope='session')
def sample_tree1():
    """Fixture providing sample tree 1 Newick format string."""
    return "(((Pop1:0.1,Pop2:0.1):0.05,Pop3:0.15):0.1,(Pop4:0.2,Pop5:0.2):0.05);"

@pytest.fixture(scope='session')
def sample_tree2():
    """Fixture providing sample tree 2 Newick format string."""
    return "(((Pop1:0.12,Pop2:0.08):0.06,Pop3:0.14):0.11,(Pop4:0.18,Pop5:0.22):0.04);"

@pytest.fixture(scope='session')
def sample_migration_data():
    """Fixture providing sample migration data."""
    return "0.5 0.1 0.2 0.3 (Pop1,Pop2) (Pop3,Pop4)\n0.3 0.05 0.15 0.25 (Pop3) (Pop5)"

@pytest.fixture
def temp_dir():
    """Fixture providing a temporary directory for test outputs."""
    with tempfile.TemporaryDirectory() as tmpdir:
        yield tmpdir

@pytest.fixture
def sample_tree_files(temp_dir, sample_tree1, sample_tree2):
    """Fixture providing temporary tree files for testing."""
    tree1_path = os.path.join(temp_dir, "tree1.treeout.gz")
    tree2_path = os.path.join(temp_dir, "tree2.treeout.gz")
    
    with gzip.open(tree1_path, "wt", encoding='utf-8') as f:
        f.write(sample_tree1)
    
    with gzip.open(tree2_path, "wt", encoding='utf-8') as f:
        f.write(sample_tree2)
    
    return tree1_path, tree2_path