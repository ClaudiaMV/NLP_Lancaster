library(quanteda)
library(tidyr)
library(dplyr)
library(janitor)
library(progress)

# Pre-processing ----------------------------------------------------------
# Subset and create a DTM for each participant
text <- read.csv("tokens.csv") # clean text

chunk_size <- 10 # Number of rows to select each time
total_rows <- nrow(text) # Get the total number of rows in the 'text' data frame
dtm_list <- list() # Create a list to store the DTMs

# Initialize progress bar for the main loop
pb1 <- progress_bar$new(
  total = ceiling(total_rows / chunk_size),
  format = "Processing text [:bar] :percent in :elapsed"
)

# Iterate through the 'text' data frame in chunks of 10 rows
for (i in seq(1, total_rows, by = chunk_size)) {
  subset_df <- text[i:min(i + chunk_size - 1, total_rows), ]   # Subset 10 rows at a time
  
  if (!inherits(subset_df$tokens, "tokens")) {
    tokens_data <- tokens(subset_df$tokens)
  } else {
    tokens_data <- subset_df$tokens
  }
  dtm <- dfm(tokens_data)  # Convert the tokenized text to a DTM
  dtm_list[[paste0("P", (i-1) %/% chunk_size + 1, "_dtm")]] <- dtm   # Store the DTM in the list with a unique name
  
  pb1$tick()  # Update progress bar
}

# Norms -------------------------------------------------------------------

## Cleaning for dictionary
lanc <- read.csv("Lancaster_norms.csv") # lancaster norms
lanc <- clean_names(lanc) # janitor
lanc$word <- tolower(lanc$word)

# Extract the words from lanc
lanc_words <- lanc$word

# Initialize an empty list to store individual data frames for each DTM (document)
dtm_frequencies <- list()

# Initialize progress bar for the second loop
pb2 <- progress_bar$new(
  total = length(dtm_list),
  format = "Calculating DTM frequencies [:bar] :percent in :elapsed"
)

# Iterate over each DTM (each participant DTM containing 10 documents) in dtm_list
for (dtm_name in names(dtm_list)) {
  
  # Extract the current DTM (containing up to 10 documents)
  dtm <- dtm_list[[dtm_name]]
  
  # Iterate over each document (row) in the current DTM
  for (doc_index in seq_len(ndoc(dtm))) {
    
    # Extract the document as a DTM with one row
    doc_dtm <- dtm[doc_index, ]
    
    # Convert the DTM (for a single document) to a data frame for easier manipulation
    dtm_df <- convert(doc_dtm, to = "data.frame")
    
    # Create an empty data frame to store frequencies of lanc words for the current document
    word_frequencies <- data.frame(word = lanc_words)
    
    # Check if each word in lanc$word appears in the document and get the frequency
    word_frequencies$frequency <- sapply(word_frequencies$word, function(w) {
      if (w %in% colnames(dtm_df)) {
        sum(dtm_df[, w])
      } else {
        0
      }
    })
    
    # Calculate the incidence: 1 if the word appears (frequency > 0), 0 otherwise
    word_frequencies$incidence <- ifelse(word_frequencies$frequency > 0, 1, 0)
    
    # Add the norms variables (auditory, gustatory, etc.) for the current document
    word_frequencies$olfactory <- lanc$olfactory_mean * word_frequencies$frequency
    word_frequencies$gustatory <- lanc$gustatory_mean * word_frequencies$frequency
    word_frequencies$haptic <- lanc$haptic_mean * word_frequencies$frequency
    word_frequencies$intereoceptive <- lanc$interoceptive_mean * word_frequencies$frequency
    word_frequencies$auditory <- lanc$auditory_mean * word_frequencies$frequency
    word_frequencies$visual <- lanc$visual_mean * word_frequencies$frequency 
    
    # Store the resulting data frame for the current document in the list
    dtm_frequencies[[paste0(dtm_name, "_doc", doc_index)]] <- word_frequencies
  }
  
  pb2$tick()  # Update progress bar for the second loop
}

# Totals ------------------------------------------------------------------

# Initialize a list to store the total scores for each document
document_totals_list <- list()

# Initialize progress bar for the third loop
pb3 <- progress_bar$new(
  total = length(dtm_frequencies),
  format = "Calculating document totals [:bar] :percent in :elapsed"
)

# Loop over each data frame in the dtm_frequencies list
for (doc_name in names(dtm_frequencies)) {
  
  # Access the individual data frame for each document
  df <- dtm_frequencies[[doc_name]]
  
  # Calculate the column-wise total (sum) for numeric columns (olfactory, gustatory, etc.)
  column_totals <- colSums(df[, sapply(df, is.numeric)], na.rm = TRUE)
  
  # Calculate the total incidence of Lancaster words (sum of incidence column)
  incidence_total <- sum(df$incidence, na.rm = TRUE)
  
  # Add the incidence total to the column totals
  column_totals["incidence"] <- incidence_total
  
  # Store the result in the list with the name of the document
  document_totals_list[[doc_name]] <- column_totals
  
  pb3$tick()  # Update progress bar for the third loop
}

# Combine all the column totals into a matrix (420 rows)
document_totals_matrix <- do.call(rbind, document_totals_list)

# View the resulting matrix
print(document_totals_matrix)

# Save the final matrix to a CSV file, including both frequencies and incidence
write.csv(document_totals_matrix, file = "lancaster_analysis.csv", row.names = TRUE)




