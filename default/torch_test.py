import torch

print("[Python Test]\n")
print("Hello World!")

a = 3
b = 5
c = a + b
print(f"a = {a}, b = {b}, c = a + b = {c}")

print("\n[Torch Test]\n")

cuda_available = torch.cuda.is_available()
print(f"Cuda available: {cuda_available}")

device = torch.device("cuda") if cuda_available else torch.device("cpu")

data = torch.randn(500, 1024)
print(f"Data shape: {data.shape}")
data = data.to(device)

while True:
    pass