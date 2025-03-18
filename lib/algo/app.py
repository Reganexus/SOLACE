from flask import Flask, request, jsonify
import torch
import joblib
import numpy as np

# Load the trained model
model_path = 'solace_lstm_model.pth'
scaler_path = 'scaler.pkl'  # Pre-fitted scaler saved during training
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

class SolaceLSTM(torch.nn.Module):
    def __init__(self, input_size, hidden_size, output_size_outcome, num_layers=3, dropout_rate=0.5, bidirectional=True):
        super(SolaceLSTM, self).__init__()
        self.lstm = torch.nn.LSTM(
            input_size=input_size,
            hidden_size=hidden_size,
            num_layers=num_layers,
            batch_first=True,
            dropout=dropout_rate,
            bidirectional=bidirectional
        )
        # Fully connected layer maps hidden_size * direction_factor to output_size_outcome
        direction_factor = 2 if bidirectional else 1
        self.fc_outcome = torch.nn.Linear(hidden_size * direction_factor, output_size_outcome)

    def forward(self, x):
        # Forward through LSTM
        lstm_out, _ = self.lstm(x)
        print("LSTM output shape:", lstm_out.shape)

        # Handle different LSTM output shapes
        if lstm_out.dim() == 3:  # Batch of sequences
            last_output = lstm_out[:, -1, :]  # Use last output for classification
        elif lstm_out.dim() == 2:  # Single sequence output
            last_output = lstm_out
        else:
            raise ValueError(f"Unexpected LSTM output dimensions: {lstm_out.dim()}")

        print("Last output shape:", last_output.shape)
        return self.fc_outcome(last_output)

# Match hyperparameters
input_size = 8  # Number of input features
hidden_size = 512  # Matches the saved model
output_size_outcome = 1  # Single output for binary classification
num_layers = 3  # Matches the saved model
bidirectional = True  # Matches the saved model

model = SolaceLSTM(input_size, hidden_size, output_size_outcome, num_layers, bidirectional=bidirectional)
model.load_state_dict(torch.load(model_path, map_location=device))
model.to(device)
model.eval()

# Load the pre-fitted scaler
scaler = joblib.load(scaler_path)

# Initialize Flask
app = Flask(__name__)

@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Log received input data
        print("Received input data (raw):", request.json)

        # Get the input data
        input_data = request.json.get('data')
        if not input_data:
            return jsonify({'error': 'No input data provided.'}), 400

        # Ensure input is a list of lists (batch of inputs)
        if not isinstance(input_data, list) or not all(isinstance(i, list) for i in input_data):
            return jsonify({'error': 'Input data must be a list of lists.'}), 400

        print("Validated input data:", input_data)

        # Convert to numpy array for processing
        input_array = np.array(input_data, dtype=np.float32)
        print("Input array shape:", input_array.shape)

        # Validate the input shape
        if input_array.shape[1] != 8:
            return jsonify({'error': f'Each input must have 8 features, but received {input_array.shape[1]}.'}), 400

        # Extract Age, Blood Pressure, Cholesterol Level for scaling (columns 4, 6, 7)
        print("Before scaling (Age, BP, Cholesterol):", input_array[:, [4, 6, 7]])
        input_array[:, [4, 6, 7]] = scaler.transform(input_array[:, [4, 6, 7]])
        print("After scaling (Age, BP, Cholesterol):", input_array[:, [4, 6, 7]])

        # Convert to PyTorch tensor and move to the appropriate device
        input_tensor = torch.tensor(input_array, dtype=torch.float32).to(device)
        print("Input tensor shape:", input_tensor.shape)
        print("Input tensor device:", input_tensor.device)

        # Make predictions
        with torch.no_grad():
            raw_output = model(input_tensor)
            print("Raw output (logits):", raw_output)

            probabilities = torch.sigmoid(raw_output)
            print("Probabilities:", probabilities)

            predicted = (probabilities > 0.5).long()
            print("Predicted class indices (after thresholding):", predicted)

            # Convert predictions to a list for JSON response
            prediction = predicted.cpu().numpy().tolist()
            print("Final prediction:", prediction)

        return jsonify({'prediction': prediction})
    except Exception as e:
        import traceback
        error_message = f"Exception occurred: {str(e)}\n{traceback.format_exc()}"
        print(error_message)
        return jsonify({'error': error_message}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
