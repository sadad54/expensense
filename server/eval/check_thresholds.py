"""Fail CI if extraction accuracy on the held-out SROIE split drops below the floor."""
import json
import sys

FLOORS = {"total_accuracy": 0.95, "date_accuracy": 0.95, "merchant_accuracy": 0.70}

result = json.load(open(sys.argv[1]))
failed = {k: (result[k], floor) for k, floor in FLOORS.items() if result[k] < floor}
for key, (got, floor) in failed.items():
    print(f"::error::{key} {got:.3f} is below the {floor:.2f} floor")
print(json.dumps({k: result[k] for k in FLOORS}, indent=2))
sys.exit(1 if failed else 0)
