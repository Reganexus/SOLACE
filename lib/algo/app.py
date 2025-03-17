from flask import Flask, request, jsonify
import joblib
import numpy as np
import pandas as pd

app = Flask(__name__)

# Load the trained model
model_path = "rf_xgboost_model.pkl"
print("Loading model...")
model = joblib.load(model_path)
print("Model loaded successfully!")

@app.route("/")
def home():
    return "Ensemble Model API is running!"

@app.route("/predict", methods=["POST"])
def predict():
    try:
        # Debugging: Print request data
        data = request.get_json()
        print("Received data:", data)

        if not data or "data" not in data:
            return jsonify({"error": "Missing 'data' field in request"}), 400

        input_data = data["data"]
        print("Processed input data:", input_data)

        # Convert to NumPy array
        input_array = np.array(input_data)

        # Debugging: Print shape
        print("Input shape:", input_array.shape)

        # Ensure correct shape
        if input_array.shape[1] != 8:
            return jsonify({"error": "Invalid input shape, expected (N, 8)"}), 400

        # Make predictions
        predictions = model.predict(input_array).tolist()
        print("Predictions:", predictions)

        # Return JSON response
        return jsonify({"predictions": predictions})

    except Exception as e:
        print("Error:", str(e))
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)


import traceback

@app.errorhandler(Exception)
def handle_exception(e):
    print("Fatal Error:", str(e))
    traceback.print_exc()
    return jsonify({"error": str(e)}), 500
