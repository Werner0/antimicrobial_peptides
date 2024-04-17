# Load necessary libraries
library(xgboost)
library(data.table)

# Function to parse command line arguments
parse_args <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 3) {
    stop("Three arguments must be supplied: <model_path> <new_data_path> <output_path>", call. = FALSE)
  }
  list(model_path = args[1], new_data_path = args[2], output_path = args[3])
}

# Main function to load the model, predict and save the predictions
predict_with_model <- function(model_path, new_data_path, output_path, threshold=0.05) {
  # Load the XGBoost model
  xgb_model <- xgb.load(model_path)
  
  # Load the new dataset
  new_dataset <- fread(new_data_path, header=TRUE)
  
  # Extract row names
  row_names <- new_dataset[[1]]
  new_dataset <- new_dataset[, .SD, .SDcols = -1]
  
  # Create a matrix from the new dataset
  new_data_matrix <- as.matrix(new_dataset)
  
  # Create DMatrix for xgboost
  dtest <- xgb.DMatrix(data = new_data_matrix)
  
  # Predict using the XGBoost model
  predictions <- predict(xgb_model, dtest)

  # Assign binary class based on the threshold
  binary_class <- ifelse(predictions > threshold, "not_AMP", "AMP")
    
  # Combine row names with predictions and binary class
  results <- data.frame(RowNames = row_names, Prediction = predictions, BinaryClass = binary_class)
  
  # Save the predictions to disk
  fwrite(results, output_path, quote = FALSE)
  
  # Print a message
  #cat("Predictions are complete and have been saved to", output_path, "\n")
}

# Run the script with arguments
args <- parse_args()
predict_with_model(args$model_path, args$new_data_path, args$output_path)
