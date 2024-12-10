import torch

# Load the saved model state dictionary
model_path = 'solace_lstm_model.pth'
state_dict = torch.load(model_path, map_location=torch.device('cpu'))

# Print the saved weights' shapes
for key, value in state_dict.items():
    print(f"{key}: {value.shape}")
