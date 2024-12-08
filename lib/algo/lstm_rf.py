import pandas as pd
# import numpy as np
# import torch
# import torch.nn as nn
import joblib
# from torch.utils.data import DataLoader, TensorDataset
from sklearn.preprocessing import StandardScaler
# from sklearn.model_selection import KFold
# from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
# from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier, StackingClassifier
# from sklearn.linear_model import LogisticRegression
# from imblearn.over_sampling import SMOTE

# Load and preprocess the data
data = pd.read_csv('Processed_Disease_Symptom_Data.csv')

# Map categorical values to numeric, including Gender
symptom_columns = ['Fever', 'Cough', 'Fatigue', 'Difficulty Breathing']
for col in symptom_columns:
    data[col] = data[col].map({'Yes': 1, 'No': 0})

# Map 'Gender' before applying SMOTE
data['Gender'] = data['Gender'].map({'Female': 0, 'Male': 1})
data['Outcome Variable'] = data['Outcome Variable'].map({'Positive': 1, 'Negative': 0})

# Map categorical values to numeric, including Gender
vital_columns = ['Blood Pressure', 'Cholesterol Level']
for col in vital_columns:
    data[col] = data[col].map({'Low': 0, 'Normal': 1, 'High': 2})

# Standardize health indicators
scaler = StandardScaler()
data[['Age', 'Blood Pressure', 'Cholesterol Level']] = scaler.fit_transform(data[['Age', 'Blood Pressure', 'Cholesterol Level']])

# Save the scaler
scaler_path = "scaler.pkl"
joblib.dump(scaler, scaler_path)
print(f"Scaler saved at {scaler_path}")

# # Increase sequence length to capture more symptom history, including 'Age' and 'Gender'
# sequence_length = 10

# def create_sequences(data, seq_length):
#     sequences = []
#     labels_outcome = []
#     for i in range(len(data) - seq_length):
#         seq = data.iloc[i:i + seq_length][
#             ['Fever', 'Cough', 'Fatigue', 'Difficulty Breathing', 'Blood Pressure', 'Cholesterol Level', 'Age', 'Gender']].values
#         sequences.append(seq)
#         labels_outcome.append(data.iloc[i + seq_length]['Outcome Variable'])
#     return np.array(sequences), np.array(labels_outcome)

# X_sequences, y_outcome_sequences = create_sequences(data, sequence_length)

# # Apply SMOTE for class balance
# smote = SMOTE(random_state=42)
# X_sequences_res, y_outcome_sequences_res = smote.fit_resample(X_sequences.reshape(X_sequences.shape[0], -1),
#                                                             y_outcome_sequences)
# X_sequences_res = X_sequences_res.reshape(-1, sequence_length, X_sequences.shape[2])

# # Define the LSTM Model with enhanced architecture (Stacked LSTM)
# class SolaceLSTM(nn.Module):
#     def __init__(self, input_size, hidden_size, output_size_outcome, num_layers=3, dropout_rate=0.5,
#                  bidirectional=True):
#         super(SolaceLSTM, self).__init__()
#         self.bidirectional = bidirectional
#         self.lstm = nn.LSTM(input_size, hidden_size, num_layers=num_layers,
#                             batch_first=True, dropout=dropout_rate, bidirectional=bidirectional)
#         direction_factor = 2 if bidirectional else 1
#         self.fc_outcome = nn.Linear(hidden_size * direction_factor, output_size_outcome)
#         self.dropout = nn.Dropout(dropout_rate)

#     def forward(self, x):
#         lstm_out, (hn, _) = self.lstm(x)
#         if self.bidirectional:
#             hn = torch.cat((hn[-2], hn[-1]), dim=1)
#         else:
#             hn = hn[-1]
#         hn = self.dropout(hn)
#         outcome_output = self.fc_outcome(hn)
#         return outcome_output.view(-1)

# # Model parameters
# input_size = X_sequences.shape[2]
# hidden_size = 512
# output_size_outcome = 1

# # Initialize k-Fold cross-validation
# k_folds = 5
# kfold = KFold(n_splits=k_folds, shuffle=True, random_state=42)
# fold_accuracies = []

# # Store predictions for stacking
# stacked_predictions = []
# true_labels = []

# # Cross-validation loop
# for fold, (train_ids, test_ids) in enumerate(kfold.split(X_sequences_res)):
#     # Split data into train and test sets for the current fold
#     X_train, X_test = X_sequences_res[train_ids], X_sequences_res[test_ids]
#     y_train_outcome, y_test_outcome = y_outcome_sequences_res[train_ids], y_outcome_sequences_res[test_ids]

#     # Convert to tensors and handle NaN values
#     X_train = np.nan_to_num(np.array(X_train, dtype=np.float32))
#     X_test = np.nan_to_num(np.array(X_test, dtype=np.float32))

#     X_train_tensor = torch.tensor(X_train, dtype=torch.float32)
#     y_train_outcome_tensor = torch.tensor(y_train_outcome, dtype=torch.float32)

#     train_data = TensorDataset(X_train_tensor, y_train_outcome_tensor)
#     train_loader = DataLoader(train_data, batch_size=32, shuffle=True)

#     # Initialize model for each fold
#     model = SolaceLSTM(input_size, hidden_size, output_size_outcome, num_layers=3, dropout_rate=0.5)

#     # Adjust class weights for imbalance handling
#     pos_weight = (y_train_outcome == 0).sum() / (y_train_outcome == 1).sum()
#     criterion_outcome = nn.BCEWithLogitsLoss(pos_weight=torch.tensor(pos_weight, dtype=torch.float32))

#     # Optimizer and scheduler for improved convergence
#     optimizer = torch.optim.AdamW(model.parameters(), lr=0.001)
#     scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='min', factor=0.5, patience=5, verbose=True)

#     # Training loop
#     epochs = 100
#     for epoch in range(epochs):
#         model.train()
#         total_loss = 0
#         for X_batch, y_outcome_batch in train_loader:
#             optimizer.zero_grad()
#             pred_outcome = model(X_batch)
#             loss_outcome = criterion_outcome(pred_outcome.squeeze(), y_outcome_batch)
#             loss_outcome.backward()
#             optimizer.step()
#             total_loss += loss_outcome.item()

#         # Step scheduler based on validation loss
#         scheduler.step(total_loss / len(train_loader))
#         print(f'Fold {fold + 1}, Epoch {epoch + 1}/{epochs}, Loss: {total_loss / len(train_loader)}')

#     # Model evaluation for the current fold
#     model.eval()
#     with torch.no_grad():
#         X_test_tensor = torch.tensor(X_test, dtype=torch.float32)
#         y_pred_outcome = model(X_test_tensor)
#         outcome_preds = torch.round(torch.sigmoid(y_pred_outcome.squeeze()))
#         outcome_accuracy = accuracy_score(y_test_outcome, outcome_preds.numpy())
#         fold_accuracies.append(outcome_accuracy)

#         # Concatenate predictions and true labels for stacking
#         stacked_predictions.extend(outcome_preds.numpy())
#         true_labels.extend(y_test_outcome)

#         # Print classification report and confusion matrix
#         print(f'Fold {fold + 1} Accuracy: {outcome_accuracy * 100:.2f}%')
#         print("Classification Report:\n", classification_report(y_test_outcome, outcome_preds.numpy()))
#         print("Confusion Matrix:\n", confusion_matrix(y_test_outcome, outcome_preds.numpy()))

# # Convert to consistent shape for stacking
# stacked_predictions = np.array(stacked_predictions).reshape(-1, 1)
# true_labels = np.array(true_labels)

# # Prepare data for ensemble methods
# X_stacked = np.hstack((stacked_predictions, X_sequences_res.reshape(X_sequences_res.shape[0], -1)))
# y_stacked = true_labels

# # Initialize and fit Random Forest and Gradient Boosting classifiers
# rf_model = RandomForestClassifier(random_state=42)
# gb_model = GradientBoostingClassifier(random_state=42)

# # Create a stacking classifier with Logistic Regression as a meta-classifier
# stacking_model = StackingClassifier(
#     estimators=[('rf', rf_model), ('gb', gb_model)],
#     final_estimator=LogisticRegression(),
#     cv=5
# )

# stacking_model.fit(X_stacked, y_stacked)

# # Prepare data for ensemble methods after all folds are processed
# for fold, (train_ids, test_ids) in enumerate(kfold.split(X_sequences_res)):
#     # Generate predictions and check shape consistency
#     X_test_tensor = torch.tensor(X_sequences_res[test_ids], dtype=torch.float32)
#     with torch.no_grad():
#         outcome_preds = torch.round(torch.sigmoid(model(X_test_tensor).squeeze())).numpy()

#     # Check if lengths match; if not, skip or adjust
#     if outcome_preds.shape[0] != len(test_ids):
#         print(f"Skipping fold {fold + 1} due to shape mismatch: "
#               f"outcome_preds ({outcome_preds.shape[0]}) vs test_ids ({len(test_ids)})")
#         continue

#     # Proceed with stacking since shapes match
#     X_test_stacked = np.hstack((
#         outcome_preds.reshape(len(test_ids), 1),
#         X_sequences_res[test_ids].reshape(len(test_ids), -1)
#     ))
#     y_test_stacked = y_outcome_sequences_res[test_ids]

#     y_pred_stacking = stacking_model.predict(X_test_stacked)
#     stacking_accuracy = accuracy_score(y_test_stacked, y_pred_stacking)
#     print(f'Fold {fold + 1} Stacking Model Accuracy: {stacking_accuracy * 100:.2f}%')

# # Specify the path to save the model
# model_path = "solace_lstm_model.pth"

# # Save the model's state dictionary
# torch.save(model.state_dict(), model_path)
# print(f"Model saved at {model_path}")