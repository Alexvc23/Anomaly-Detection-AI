import pandas as pd

# Example dataset
data = {
    'date': pd.date_range(start='2023-01-01', end='2023-03-01', freq='D'),
    'value': range(60)  # Some arbitrary data
}
df = pd.DataFrame(data)

# Example list of cutoff dates
cutoff_dates = [
    pd.Timestamp('2023-01-10'),
    pd.Timestamp('2023-01-20'),
    pd.Timestamp('2023-01-30'),
    pd.Timestamp('2023-02-10'),
    pd.Timestamp('2023-02-20')
]

# Moving window split
dfs = []
for i in range(len(cutoff_dates) - 1):
    train_start = cutoff_dates[max(0, i - 1)]  # Start of the training window
    train_end = cutoff_dates[i]               # End of the training window
    val_start = cutoff_dates[i]               # Start of the validation window
    val_end = cutoff_dates[i + 1]             # End of the validation window
    
    # Training data includes only data between train_start and train_end
    df_train = df[(df['date'] > train_start) & (df['date'] <= train_end)]
    
    # Validation data includes only data between val_start and val_end
    df_val = df[(df['date'] > val_start) & (df['date'] <= val_end)]
    
    dfs.append((df_train, df_val))

# Output example
for i, (train, val) in enumerate(dfs):
    print(f"Split {i + 1}")
    print("Train:")
    print(train)
    print("Validation:")
    print(val)
    print("-" * 40)
