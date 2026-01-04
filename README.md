# README

## Project

Pipeline for processing genetic raw data with **PLINK** and subsequent analysis using **TreeMix**.

## Structure

- **raw_data/**  
  Contains all raw data (e.g. VCF, .bed/.bim/.fam, metadata).

- **plink_script.sh**  
  Runs all required PLINK steps and automatically creates a results folder.  
  ```bash
  bash plink_script.sh
  ```

- **Treemix/**  
  Scripts for TreeMix analyses based on the PLINK-processed files.

- **Scripts/**  
  Additional helper and processing scripts.