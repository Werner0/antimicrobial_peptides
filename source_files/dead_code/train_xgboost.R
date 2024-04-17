# Load necessary libraries
library(xgboost)
library(data.table)

# Load the dataset from a CSV file
dataset <- fread('APD/training_APD_metagenome.csv')

# Assuming the label column contains character strings
factor_labels <- factor(dataset$label)
label_vector <- as.numeric(factor_labels) - 1  # Convert factor to numeric (0 and 1)
cat("Label conversion mapping:\n")
levels(factor_labels) <- as.character(levels(factor_labels)) # Ensure levels are character for printing
for (i in seq_along(levels(factor_labels))) {
cat(sprintf("%s converted to %d\n", levels(factor_labels)[i], i - 1))
}

# Remove the label column from the dataset to create the data matrix
data_matrix <- as.matrix(dataset[, .SD, .SDcols = !'label'])

# Create DMatrix for xgboost
dtrain <- xgb.DMatrix(data = data_matrix, label = label_vector)

# Set up parameters for xgboost
params <- list(
  objective = "binary:logistic",
  eval_metric = "logloss",
  eta = 0.3,
  max_depth = 6,
  nthread = 2
)

# Number of rounds for boosting
nrounds <- 100

# Train the model
xgb_model <- xgb.train(
  params = params,
  data = dtrain,
  nrounds = nrounds,
  verbose = 1
)

# Save the model to disk
xgb.save(xgb_model, 'xgb_model.bin')

# Print a message
cat("Model training is complete and the model has been saved to disk.")
