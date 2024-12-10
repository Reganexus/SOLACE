import pandas as pd
import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import KFold
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.ensemble import GradientBoostingClassifier
from imblearn.over_sampling import SMOTE
import joblib

# Load and preprocess the data
data = pd.read_csv('Processed_Scaled_Disease_Symptom_Data.csv')

# Map categorical values to numeric
symptom_columns = ['Fever', 'Cough', 'Fatigue', 'Difficulty Breathing']
for col in symptom_columns:
    data[col] = data[col].map({'Yes': 1, 'No': 0})

data['Gender'] = data['Gender'].map({'Female': 0, 'Male': 1})
data['Outcome Variable'] = data['Outcome Variable'].map({'Positive': 1, 'Negative': 0})

# Standardize health indicators
scaler = StandardScaler()
data[['Blood Pressure', 'Cholesterol Level']] = scaler.fit_transform(data[['Blood Pressure', 'Cholesterol Level']])

# Increase sequence length to capture more symptom history
sequence_length = 10

def create_sequences(data, seq_length):
    sequences = []
    labels_outcome = []
    for i in range(len(data) - seq_length):
        seq = data.iloc[i:i + seq_length][
            ['Fever', 'Cough', 'Fatigue', 'Difficulty Breathing', 'Blood Pressure', 'Cholesterol Level']].values
        sequences.append(seq)
        labels_outcome.append(data.iloc[i + seq_length]['Outcome Variable'])
    return np.array(sequences), np.array(labels_outcome)

X_sequences, y_outcome_sequences = create_sequences(data, sequence_length)

# Apply SMOTE for class balance
smote = SMOTE(random_state=42)
X_sequences_res, y_outcome_sequences_res = smote.fit_resample(
    X_sequences.reshape(X_sequences.shape[0], -1), y_outcome_sequences)
X_sequences_res = X_sequences_res.reshape(-1, sequence_length, X_sequences.shape[2])

# Define the LSTM Model
class SolaceLSTM(nn.Module):
    def __init__(self, input_size, hidden_size, output_size_outcome, num_layers=3, dropout_rate=0.5, bidirectional=True):
        super(SolaceLSTM, self).__init__()
        self.lstm = nn.LSTM(input_size, hidden_size, num_layers=num_layers,
                            batch_first=True, dropout=dropout_rate, bidirectional=bidirectional)
        direction_factor = 2 if bidirectional else 1
        self.fc_outcome = nn.Linear(hidden_size * direction_factor, output_size_outcome)

    def forward(self, x):
        lstm_out, _ = self.lstm(x)
        last_output = lstm_out[:, -1, :]  # Use the last output for classification
        return self.fc_outcome(last_output)

# Model training parameters
input_size = X_sequences.shape[2]
hidden_size = 64
output_size_outcome = 2  # Binary classification
num_epochs = 30
batch_size = 64
learning_rate = 0.001

# Split data using K-Fold cross-validation
kf = KFold(n_splits=5, shuffle=True, random_state=42)
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
best_model = None
highest_accuracy = 0

for fold, (train_index, test_index) in enumerate(kf.split(X_sequences_res)):
    print(f'Fold {fold + 1}/{kf.n_splits}')

    X_train, X_test = X_sequences_res[train_index], X_sequences_res[test_index]
    y_train, y_test = y_outcome_sequences_res[train_index], y_outcome_sequences_res[test_index]

    train_dataset = TensorDataset(torch.tensor(X_train, dtype=torch.float32), torch.tensor(y_train, dtype=torch.long))
    test_dataset = TensorDataset(torch.tensor(X_test, dtype=torch.float32), torch.tensor(y_test, dtype=torch.long))

    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    test_loader = DataLoader(test_dataset, batch_size=batch_size, shuffle=False)

    model = SolaceLSTM(input_size, hidden_size, output_size_outcome).to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=learning_rate)

    # Training loop
    for epoch in range(num_epochs):
        model.train()
        running_loss = 0.0
        for inputs, labels in train_loader:
            inputs, labels = inputs.to(device), labels.to(device)
            optimizer.zero_grad()
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
            running_loss += loss.item()

        print(f'Epoch [{epoch + 1}/{num_epochs}], Loss: {running_loss / len(train_loader):.4f}')

    # Evaluation
    model.eval()
    y_pred = []
    y_true = []
    with torch.no_grad():
        for inputs, labels in test_loader:
            inputs = inputs.to(device)
            outputs = model(inputs)
            _, predicted = torch.max(outputs, 1)
            y_pred.extend(predicted.cpu().numpy())
            y_true.extend(labels.numpy())

    acc = accuracy_score(y_true, y_pred)
    print(f'Fold {fold + 1} Accuracy: {acc:.4f}')

    if acc > highest_accuracy:
        highest_accuracy = acc
        best_model = model

    print(classification_report(y_true, y_pred))

# Save the best model
model_path = 'solace_lstm_gb_model.pth'
torch.save(best_model.state_dict(), model_path)
print(f'Best model saved with accuracy: {highest_accuracy:.4f}')

# Display overall accuracy
print('Final Accuracy Report:')
print(classification_report(y_true, y_pred))

# Export trained model as joblib file for easier loading later
joblib.dump(best_model, 'solace_lstm_gb_model.joblib')
print('Model exported as joblib file.')
