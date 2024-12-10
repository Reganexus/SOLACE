import pandas as pd
from sklearn.preprocessing import StandardScaler

# Load the data
data = pd.read_csv('Processed_Disease_Symptom_Data.csv')

# Print the specified columns before processing
print("Before Scaling:")
print(data[['Age', 'Blood Pressure', 'Cholesterol Level']].head())

# Map categorical values to numeric values
bp_mapping = {'Low': 0, 'Normal': 1, 'High': 2}
chol_mapping = {'Low': 0, 'Normal': 1, 'High': 2}

data['Blood Pressure'] = data['Blood Pressure'].map(bp_mapping)
data['Cholesterol Level'] = data['Cholesterol Level'].map(chol_mapping)

# Convert 'Age' to numeric if it's not already
data['Age'] = pd.to_numeric(data['Age'], errors='coerce')

# Apply StandardScaler
scaler = StandardScaler()
data[['Age', 'Blood Pressure', 'Cholesterol Level']] = scaler.fit_transform(data[['Age', 'Blood Pressure', 'Cholesterol Level']])

# Print the specified columns after scaling
print("After Scaling:")
print(data[['Age', 'Blood Pressure', 'Cholesterol Level']].head())
