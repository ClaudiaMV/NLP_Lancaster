#Lancaster no iteration by 10

library(quanteda)
library(quanteda.textplots)
library(quanteda.textstats)
library(quanteda.textmodels)
library(tidyverse)
library(tidyr)
library(readtext)
library(dplyr)
library(MASS)
library(tidytext)
library(janitor)

# Pre-processing ----------------------------------------------------------
# Subset and create a DTM for each participant
text <- read.csv("tokens.csv") # clean text

total_rows <- nrow(text) # Get the total number of rows in the 'text' data frame
dtm_list <- list() # Create a list to store the DTMs

# Iterate over each row of the dataset to ensure individual processing
for (i in 1:total_rows) {
  row_df <- text[i, ]
  
  # Check if the tokens column is available and tokenize
  if (!is.list(row_df$tokens)) {
    tokens_data <- tokens(row_df$tokens)
  } else {
    tokens_data <- row_df$tokens
  }
  
  # Create the DTM (document-feature matrix)
  dtm <- dfm(tokens_data)  # Convert the tokenized text to a DTM
  
  # Create a unique name for each DTM
  doc_name <- paste0("P", i, "_dtm")
  dtm_list[[doc_name]] <- dtm   # Store the DTM for each individual row
}

# Norms -------------------------------------------------------------------

# Load and clean the Lancaster norms
lanc <- read.csv("Lancaster.csv") # lancaster norms
lanc <- clean_names(lanc) # Clean the column names using janitor
lanc$word <- tolower(lanc$word) # Ensure words are in lowercase

# Extract the words from lancaster norms
lanc_words <- lanc$word

# Initialize an empty list to store individual data frames for each DTM (document)
dtm_frequencies <- list()

# Iterate over each DTM (each document in dtm_list)
for (dtm_name in names(dtm_list)) {
  
  # Extract the current DTM (document)
  dtm <- dtm_list[[dtm_name]]
  
  # Convert DTM to data frame for easier manipulation
  dtm_df <- convert(dtm, to = "data.frame")
  
  # Create an empty data frame to store frequencies and first match for lanc words for the current document
  word_frequencies <- data.frame(word = lanc_words)
  
  # Add a column to track if it's the first match
  word_frequencies$first_match <- 0
  
  # Loop through each word and calculate frequency and first match
  for (k in 1:nrow(word_frequencies)) {
    word <- word_frequencies$word[k]
    
    # Check if the word is present in the DTM
    if (word %in% colnames(dtm_df)) {
      word_freq <- sum(dtm_df[, word], na.rm = TRUE)
      
      # If the word appears and it's the first occurrence, set first_match to 1
      if (word_freq > 0) {
        word_frequencies$frequency[k] <- word_freq
        if (word_frequencies$first_match[k] == 0) {
          word_frequencies$first_match[k] <- 1
        }
      } else {
        word_frequencies$frequency[k] <- 0
      }
    } else {
      word_frequencies$frequency[k] <- 0
    }
  }
  
  # Store the resulting data frame for the current DTM in the list
  dtm_frequencies[[dtm_name]] <- word_frequencies
}

# Add the variables (auditory, gustatory, etc.) for each DTM
for (dtm_name in names(dtm_frequencies)) {
  
  # Access the individual data frame
  df <- dtm_frequencies[[dtm_name]]
  
  # Add the new columns with specified values based on the Lancaster norms
  df$olfactory <- lanc$olfactory_mean * df$frequency
  df$gustatory <- lanc$gustatory_mean * df$frequency
  df$haptic <- lanc$haptic_mean * df$frequency
  df$intereoceptive <- lanc$interoceptive_mean * df$frequency
  df$auditory <- lanc$auditory_mean * df$frequency
  df$visual <- lanc$visual_mean * df$frequency 
  
  # Update the data frame in the list
  dtm_frequencies[[dtm_name]] <- df
}

# Totals ------------------------------------------------------------------

# Initialize a list to store the total scores of each data frame
column_totals_list <- list()

# Loop over each data frame in the dtm_frequencies list
for (dtm_name in names(dtm_frequencies)) {
  
  # Access the individual data frame
  df <- dtm_frequencies[[dtm_name]]
  
  # Calculate the column-wise total (sum) for numeric columns
  column_totals <- colSums(df[, sapply(df, is.numeric)], na.rm = TRUE)
  
  # Add a new column for the document identifier
  column_totals <- c(document = dtm_name, column_totals)
  
  # Store the result in the list with the name of the document (dtm)
  column_totals_list[[dtm_name]] <- column_totals
}

# Combine all the column totals into a matrix
# Use 'do.call' with 'rbind' to bind the results row-wise
column_totals_matrix <- do.call(rbind, column_totals_list)

# View the resulting matrix
print(column_totals_matrix)

column_totals_matrix <- as.data.frame(column_totals_matrix)

# Export the matrix as a CSV file
write.csv(column_totals_matrix, "lancaster_analysis_doc.csv", row.names = TRUE)
