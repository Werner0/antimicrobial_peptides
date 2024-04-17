import pandas as pd
from mlxtend.frequent_patterns import apriori, association_rules
import argparse

# Define a function to categorize the values
def categorize(val, mean):
    return val > mean

# Function to check if a transaction meets the high confidence rules
def is_transaction_compliant(transaction, rules):
    for index, rule in rules.iterrows():
        antecedents = set(rule['antecedents'])
        if antecedents.issubset(transaction.index[transaction == True]):
            return True
    return False

def main(input_file, new_input_file, output_path):
    # Load the datasets
    df = pd.read_csv(input_file)
    new_df = pd.read_csv(new_input_file)

    # Convert numeric data into boolean values based on the mean
    for col in df.columns[1:]:
        mean_val = df[col].mean()
        df[f'{col}_high'] = df[col].apply(categorize, args=(mean_val,))

    for col in new_df.columns[1:]:
        mean_val = new_df[col].mean()
        new_df[f'{col}_high'] = new_df[col].apply(categorize, args=(mean_val,))

    # Drop the non-boolean columns
    df_reduced = df.drop(df.columns[0:9], axis=1)
    new_df_reduced = new_df.drop(new_df.columns[0:9], axis=1)

    # Find frequent itemsets with the Apriori algorithm
    frequent_itemsets = apriori(df_reduced, min_support=0.1, use_colnames=True)

    # Generate association rules
    rules = association_rules(frequent_itemsets, metric="confidence", min_threshold=0.8)

    # Apply the function to filter the transactions in the new DataFrame
    compliant_transactions = new_df_reduced.apply(is_transaction_compliant, axis=1, args=(rules,))

    # Filter the DataFrame to only include compliant transactions
    filtered_new_df = new_df[compliant_transactions]

    # Save the filtered 'File' column to the specified output path
    filtered_new_df['File'].str.replace('.dssp', '').to_csv(output_path, index=False, header=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process and filter data based on association rules.')
    parser.add_argument('input_file', type=str, help='Path to the input CSV file')
    parser.add_argument('new_input_file', type=str, help='Path to the new input CSV file')
    parser.add_argument('output_path', type=str, help='Path to the output text file')

    args = parser.parse_args()

    main(args.input_file, args.new_input_file, args.output_path)
