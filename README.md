# NLP_Lancaster
Norm-based analysis using NLP (Lancaster sensorimotor norms)
# README: Lancaster Norms Analysis Script

## Overview
This script processes text data to compute word frequencies based on the Lancaster norms and calculates sensory scores (olfactory, gustatory, auditory, etc.) for each document. A Document-Term Matrix (DTM) is generated for each participant, and the resulting sensory analysis is saved in a CSV file.

## Prerequisites

### Libraries
The following R libraries are required:
- **quanteda**: For tokenization and DTM creation.
- **tidyverse, tidyr, dplyr, readtext**: For data manipulation.
- **janitor**: For cleaning column names.
- **MASS**: For miscellaneous statistical functions.
- **tidytext**: For text processing.

To install the required packages, run the following command:
```R
install.packages(c("quanteda", "tidyverse", "tidyr", "dplyr", "readtext", "janitor", "MASS", "tidytext"))
```

### Data Files
- **tokens.csv**: A CSV file containing preprocessed text data with tokenized text.
- **Lancaster.csv**: A CSV file containing Lancaster norms with sensory dimensions (e.g., olfactory, gustatory).

## Workflow

### 1. Pre-processing
- The script reads the `tokens.csv` file containing the text data.
- Each row in the dataset represents a document (participant's response).
- For each document, a Document-Term Matrix (DTM) is created using `quanteda`.
- The DTM for each document is stored in `dtm_list`, where each document has a unique identifier (e.g., `P1_dtm`, `P2_dtm`).

### 2. Applying Lancaster Norms
- The script reads and cleans the Lancaster norms from `Lancaster.csv`.
- Words from the Lancaster norms are matched with the DTM of each document to calculate word frequencies.
- For each document, the frequency of each word from the Lancaster norms is calculated and stored in a list named `dtm_frequencies`.

### 3. Calculating Sensory Scores
- For each document, the sensory dimensions (olfactory, gustatory, auditory, visual, etc.) are calculated by multiplying word frequencies by their corresponding sensory means from the Lancaster norms.
- These sensory scores are added as new columns to the document-specific data frames in `dtm_frequencies`.

### 4. Aggregating Results
- For each document, the script calculates the total sensory scores for each dimension.
- The total scores for all documents are combined into a matrix (`column_totals_matrix`).
- This matrix includes a row for each document and columns for the sensory dimensions, allowing for easy document comparison.

### 5. Exporting Results
- The resulting matrix is exported to a CSV file named `lancaster_analysis_doc.csv`.
- The CSV file contains the document identifiers and the corresponding sensory scores for each document.

### 6. Output
The output CSV file, `lancaster_analysis_doc.csv`, includes:
- **Document ID**: A unique identifier for each document (e.g., `P1_dtm`, `P2_dtm`).
- **Sensory Scores**: Columns representing the scores for each sensory dimension (e.g., olfactory, gustatory, haptic, interoceptive, auditory, visual).
- **Word Frequencies**: The frequency of words from the Lancaster norms used in the text.

## How to Run the Script
1. Ensure that `tokens.csv` and `Lancaster.csv` are available in your working directory.
2. Install all required libraries.
3. Run the script in an R environment.
4. After running, the output CSV file `lancaster_analysis_doc.csv` will be generated in your working directory.

## Notes
- The script processes the text data document by document, creating a DTM for each document and applying the Lancaster norms.
- The final output provides sensory analysis for each document, which can be used for further study or modelling.
- Ensure that `Lancaster.csv` contains lowercase words and appropriate columns for each sensory dimension (olfactory, gustatory, etc.).

