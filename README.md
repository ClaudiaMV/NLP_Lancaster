# Lancaster Norms Text Processing Script

This script processes text data, calculating the frequency and incidence of words based on the Lancaster norms and generates a document-term matrix (DTM) for each participant. The script then summarizes sensory variables and word incidences for each document, saving the results to a CSV file.

## Table of Contents
- [Pre-requisites](#pre-requisites)
- [Input Files](#input-files)
- [Script Overview](#script-overview)
  - [First Loop: Creating DTMs](#first-loop-creating-dtms)
  - [Second Loop: Calculating Word Frequencies and Incidences](#second-loop-calculating-word-frequencies-and-incidences)
  - [Third Loop: Aggregating Document Totals](#third-loop-aggregating-document-totals)
- [Output](#output)

## Pre-requisites

Make sure the following R packages are installed:

- `quanteda`
- `tidyverse`
- `readtext`
- `dplyr`
- `janitor`
- `progress`

Install them using:

```r
install.packages(c("quanteda", "tidyverse", "readtext", "dplyr", "janitor", "progress"))
```

## Input Files

- `tokens.csv`: A CSV file containing tokenized text data. This file should include a `tokens` column where each row represents the tokens for a specific document.
- `Lancaster_norms.csv`: A CSV file containing Lancaster norms with columns representing different sensory variables (olfactory, gustatory, haptic, etc.) and their corresponding values for each word.

## Script Overview

### First Loop: Creating DTMs

**Purpose**: The first loop processes the `tokens.csv` file by chunking the text into groups of 10 rows and generating a Document-Term Matrix (DTM) for each participant. The `dfm()` function from the `quanteda` package is used to create DTMs from the tokenized data.

**Key Steps**:
1. The `text` dataset is divided into chunks of 10 rows.
2. A DTM is created for each chunk, storing it in `dtm_list`.
3. A progress bar (`pb1`) is used to track the processing of text data in chunks.

```r
for (i in seq(1, total_rows, by = chunk_size)) {
  subset_df <- text[i:min(i + chunk_size - 1, total_rows), ]   # Subset 10 rows at a time
  
  # Create tokens and DTM
  tokens_data <- tokens(subset_df$tokens)
  dtm <- dfm(tokens_data)  
  dtm_list[[paste0("P", (i-1) %/% chunk_size + 1, "_dtm")]] <- dtm
  
  pb1$tick()  # Update progress bar
}
```

### Second Loop: Calculating Word Frequencies and Incidences

**Purpose**: The second loop processes each DTM, calculating the frequency and incidence of words based on the Lancaster norms. The incidence counts whether a word from the Lancaster norms appears at least once in the document, while the frequency tracks how many times each word appears.

**Key Steps**:
1. For each DTM, the frequency of each word from the Lancaster norms is calculated.
2. Incidence is determined (set to `1` if the word appears, `0` otherwise).
3. Sensory variables (olfactory, gustatory, etc.) are calculated by multiplying word frequency by the corresponding mean sensory values from the Lancaster norms.

```r
for (dtm_name in names(dtm_list)) {
  dtm <- dtm_list[[dtm_name]]
  
  for (doc_index in seq_len(ndoc(dtm))) {
    # Extract DTM row, calculate frequency and incidence
    word_frequencies$frequency <- sapply(word_frequencies$word, function(w) { ... })
    word_frequencies$incidence <- ifelse(word_frequencies$frequency > 0, 1, 0)

    # Multiply frequencies with sensory variables
    word_frequencies$olfactory <- lanc$olfactory_mean * word_frequencies$frequency
    # (Repeat for other sensory variables)
    
    # Store the results
    dtm_frequencies[[paste0(dtm_name, "_doc", doc_index)]] <- word_frequencies
  }
  pb2$tick()  # Update progress bar
}
```

### Third Loop: Aggregating Document Totals

**Purpose**: The third loop aggregates the results for each document by calculating the total frequencies for each sensory variable and the total incidence of Lancaster words. The aggregated totals for each document are then stored in a matrix.

**Key Steps**:
1. For each document, the sum of sensory variable columns (olfactory, gustatory, etc.) is calculated.
2. The total incidence (number of unique words from the Lancaster norms that appear in the document) is added to the results.
3. The results are stored in `document_totals_list`, which is later converted into a matrix.

```r
for (doc_name in names(dtm_frequencies)) {
  df <- dtm_frequencies[[doc_name]]
  
  # Sum the columns for sensory variables
  column_totals <- colSums(df[, sapply(df, is.numeric)], na.rm = TRUE)
  
  # Calculate total incidence
  incidence_total <- sum(df$incidence, na.rm = TRUE)
  
  # Store results
  column_totals["incidence"] <- incidence_total
  document_totals_list[[doc_name]] <- column_totals
  
  pb3$tick()  # Update progress bar
}
```

## Output

- **CSV File**: `lancaster_analysis_with_incidence.csv`  
This file contains the final matrix with:
  - Sensory variable totals (olfactory, gustatory, etc.) for each document.
  - Frequency of Lancaster words
  - The total incidence of Lancaster words for each document.
