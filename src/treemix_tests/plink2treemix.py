import sys
#Translated https://bitbucket.org/nygcresearch/treemix/downloads/plink2treemix.py in python 3

# Ensure correct number of arguments
if len(sys.argv) != 3:
    print("ERROR: Incorrect number of arguments.")
    sys.exit(1)

print()
print("Starting plink2treemix.py...")
# Read input and output file paths from command-line arguments
input_file = sys.argv[1]
output_file = sys.argv[2]

print("input file:", input_file)
print("output file:", output_file)

# Data structures
pop2rs = {}  # Stores allele counts per SNP per population
snps = []  # List of SNPs in order
populations = set()  # Track populations

# Read the PLINK allele frequency file
with open(input_file, "r") as infile:
    next(infile)  # Skip header line
    for line in infile:
        cols = line.strip().split()
        snp = cols[1]   # SNP ID
        pop = cols[2]   # Population ID
        ref_count = int(float(cols[6]))  # MAC (minor allele count)
        alt_count = int(float(cols[7]) - ref_count)  # REF count = total - MAC

        populations.add(pop)
        if snp not in pop2rs:
            pop2rs[snp] = {}
            snps.append(snp)  # Keep SNP order
        pop2rs[snp][pop] = f"{ref_count},{alt_count}"

# Sort populations for consistent ordering
populations = sorted(list(populations))

# Write TreeMix-formatted file
with open(output_file, "w") as outfile:
    outfile.write(" ".join(populations) + "\n")  # Header row
    for snp in snps:
        row = [pop2rs[snp].get(pop, "0,0") for pop in populations]
        outfile.write(" ".join(row) + "\n")

print("TreeMix input file created:", output_file)
