import pandas as pd


# def create_poplist_from_HGDP(path:str, path2:str, fam:str, output_path:str):
#     """
#         Converts HGDP sample metadata from the IGSR portal into a PLINK-compatible population list.
#
#         The function reads a tab-separated metadata file (downloaded from the IGSR HGDP data collection (downloaded 26.03.2025): https://www.internationalgenome.org/data-portal/data-collection/hgdp),
#         extracts the sample name and population name, assigns FID = IID, and outputs a tab-separated
#         file with the format required for PLINK's `--within` or `--keep` pr `--remove` option.
#
#         Output:
#             - pop_list_for_plink.txt: a 3-column file (FID, IID, Population) with no header.
#
#         Parameters:
#             :param input_path (str): Path to the HGDP metadata TSV file. The file should contain at least the
#                         columns "Sample name" and "Population name".
#             :param output_path (str): Path to the output PLINK-compatible population list.
#
#         """
#     # Load the sample metadata from IGSR (downloaded 26.03.2025)
#     #df = pd.read_csv(input_path, sep="\t")
#
#
#     df1 = pd.read_csv(path, sep="\t")
#     df2 = pd.read_csv(path2, sep="\t")
#     df = pd.concat([df1, df2], ignore_index=True)
#     df = df.drop_duplicates(["Sample name"])
#
#     df["Population name"] = (
#         df["Population name"]
#         .fillna("")
#         .apply(lambda x: x.split(",")[0].strip())
#         .str.replace(" ", "")
#     )
#     #df["Population name"] = df["Population name"].str.replace(" ", "")
#
#     df[df["Sample name"].notna()]
#     df = df[df['Sample name'].str.startswith('HGDP')]
#
#
#
#     # Create FID and IID columns for PLINK (HGDP uses Sample name as both)
#     df["FID"] = df["Sample name"]
#     df["IID"] = df["Sample name"]
#     df["Population"] = df["Population name"]
#
#     #New to clean the popfile
#     fam = pd.read_csv(fam, sep=" ", header=None, names=["FID", "IID", "PID", "MID", "Sex", "Pheno"])
#     df = df.merge(fam[["FID", "IID"]], on=["FID", "IID"])
#     missing_in_fam = df[~df["IID"].isin(fam["IID"])]
#
#     # Select the needed columns
#     pop_list = df[["FID", "IID", "Population"]]
#
#     # Save as tab-separated, no header
#     pop_list.to_csv(output_path, sep="\t", index=False, header=False)
#
#
# def create_population_to_superpopulation_map(path, path2, json_path):
#     """
#         Creates and saves a simplified population-to-superpopulation mapping
#         based on metadata from the Human Genome Diversity Project (HGDP) and
#         Simons Genome Diversity Project (SGDP).
#
#         This function:
#         1. Loads and concatenates sample metadata files from IGSR (downloaded from
#            https://www.internationalgenome.org/data-portal/data-collection/hgdp and
#            https://www.internationalgenome.org/data-portal/data-collection/sgdp).
#         2. Cleans the "Superpopulation name" field:
#            - Removes dataset annotations like "(HGDP)" and "(SGDP)"
#            - Keeps only the first superpopulation if multiple are listed
#         3. Creates a dictionary mapping each population (e.g. "French") to a cleaned superpopulation
#            (e.g. "Europe")
#         4. Applies a manual simplification map to reduce redundancy in superpopulation labels
#            (e.g. "West Eurasia" → "Europe", "African Ancestry" → "Africa")
#         5. Saves the result as a JSON dictionary: json_path
#
#         Parameters:
#             :param path (str): Path to the HGDP metadata `.tsv` file.
#             :param path2 (str): Path to the SGDP metadata `.tsv` file.
#             :param json_path (str): Path to the output JSON file.
#
#         Output:
#             - A file `pop_to_superpop.json` containing the simplified dictionary:
#               {Population name → Simplified Superpopulation name}
#
#         """
#     # Load your metadata file
#     df1 = pd.read_csv(path, sep="\t")
#     df2 = pd.read_csv(path2, sep="\t")
#     df = pd.concat([df1, df2], ignore_index=True)
#
#     # Clean and simplify the "Superpopulation name"
#     df["Superpopulation name"] = (
#         df["Superpopulation name"]
#         .fillna("")  # handle missing values
#         .apply(lambda x: x.split(",")[0])  # take only the first superpopulation
#         .str.replace(r"\s*\(SGDP\)", "", regex=True)  # remove ' (SGDP)'
#         .str.replace(r"\s*\(HGDP\)", "", regex=True)  # remove ' (HGDP)'
#         .str.strip()  # remove extra spaces
#     )
#     df["Population name"] = (
#         df["Population name"]
#         .fillna("")
#         .apply(lambda x: x.split(",")[0].strip())
#         .str.replace(" ", "")
#     )
#     df = df[df['Sample name'].str.startswith('HGDP')]
#
#     # Create dictionary: {Population name → Superpopulation name}
#     pop_to_superpop = df.dropna(subset=["Population name", "Superpopulation name"]) \
#                         .drop_duplicates(subset=["Population name"]) \
#                         .set_index("Population name")["Superpopulation name"] \
#                         .to_dict()
#
#     # Define simplification map
#     simplify_map = {
#         "Central South Asia": "South Asia",
#         "South Asia": "South Asia",
#         "Central Asia and Siberia": "Central Asia",
#         "West Eurasia": "Europe",
#         "European Ancestry": "Europe",
#         "Africa": "Africa",
#         "African Ancestry": "Africa",
#         "Europe": "Europe",
#         "East Asia": "East Asia",
#         "Middle East": "Middle East",
#         "America": "America",
#         "Oceania": "Oceania"
#     }
#
#     # Apply to the mapping dictionary
#     pop_to_superpop_simplified = {
#         pop: simplify_map.get(sup, sup)  # fall back to original if not in map
#         for pop, sup in pop_to_superpop.items()
#     }
#
#     # Preview unique simplified superpopulations
#     print(set(pop_to_superpop_simplified.values()))
#
#     with open(json_path, "w") as f:
#         json.dump(pop_to_superpop_simplified, f, indent=4)
#
#


def create_poplist_from_HGDP_new(hgdp_txt_path: str, output_path: str):
    """
    Converts HGDP sample metadata into a PLINK-compatible population list.

    Parameters:
        hgdp_txt_path (str): Path to the HGDP metadata .txt file (tab-separated).
        fam_path (str): Path to the PLINK .fam file.
        output_path (str): Path to save the output .txt file with FID, IID, Population.

    Output:
        A .txt file with 3 columns: FID, IID, Population (tab-separated, no header).
    """

    # Read the input population file (assumes no header, whitespace-separated)
    df = pd.read_csv(hgdp_txt_path, sep=r"\s+", header=None, names=["FID", "IID", "Population"])

    # Filter: keep only individuals whose IID starts with 'HGDP'
    df = df[df["IID"].str.startswith("HGDP")]

    # Filter: Remove the _discover populations
    df = df[~df["Population"].str.endswith("_discover")]

    # Output the filtered population list
    df[["FID", "IID", "Population"]].to_csv(output_path, sep="\t", index=False, header=False)


if __name__ == '__main__':
    hgdp_population = "../../raw_data/old/hgdp_pops.tsv"
    simon_population= "../../raw_data/old/SimonGenomeDiversity.tsv"
    hgdp_output_path = "../raw_data/old/hgdp_poplist.tsv"
    simon_output_path = "../../raw_data/simon_hgdp.tsv"
    json_path = "../raw_data/hgdp_popto_simplified.json"
    combined= "../../raw_data/hgdp_simon_poplist_cleaned.tsv"

    # first: awk '{print $1, $1, $3}' sample_all_snp.txt > plink_within.txt
   # create_poplist_from_HGDP(hgdp_population, simon_population, "../../raw_data/all_snp.fam", combined)
    #create_population_to_superpopulation_map(hgdp_population, simon_population, json_path)
    #create_poplist_from_HGDP_new("../raw_data/plink_within.txt", "../raw_data/2306_poplist.tsv")



