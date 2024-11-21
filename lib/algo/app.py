from flask import Flask, request, jsonify
import torch

# Load the trained model
model_path = 'solace_lstm_gb_model.pth'
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

class SolaceLSTM(torch.nn.Module):
    def __init__(self, input_size, hidden_size, output_size_outcome, num_layers=3, dropout_rate=0.5, bidirectional=True):
        super(SolaceLSTM, self).__init__()
        self.lstm = torch.nn.LSTM(input_size, hidden_size, num_layers=num_layers,
                                  batch_first=True, dropout=dropout_rate, bidirectional=bidirectional)
        direction_factor = 2 if bidirectional else 1
        self.fc_outcome = torch.nn.Linear(hidden_size * direction_factor, output_size_outcome)

    def forward(self, x):
        lstm_out, _ = self.lstm(x)
        last_output = lstm_out[:, -1, :]  # Use the last output for classification
        return self.fc_outcome(last_output)

input_size = 6  # Number of input features
hidden_size = 64
output_size_outcome = 2  # Binary classification
model = SolaceLSTM(input_size, hidden_size, output_size_outcome)
model.load_state_dict(torch.load(model_path, map_location=device))
model.to(device)
model.eval()

# Initialize Flask
app = Flask(__name__)

@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Get the input data
        input_data = request.json['data']
        input_tensor = torch.tensor(input_data, dtype=torch.float32).to(device)

        # Make predictions
        with torch.no_grad():
            output = model(input_tensor)
            _, predicted = torch.max(output, 1)
            prediction = predicted.cpu().numpy().tolist()

        return jsonify({'prediction': prediction})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
