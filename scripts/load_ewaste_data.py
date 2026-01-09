#!/usr/bin/env python3
import json
import csv
from pathlib import Path

def load_devices_from_csv():
    devices = []
    csv_path = Path(__file__).parent.parent / 'ewaste_dataset' / 'ewaste_devices.csv'
    
    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader: 
            device = {
                "deviceId": row['deviceId'],
                "category": row['category'],
                "brand": row['brand'],
                "model": row['model'],
                "weight": float(row['weightKg']),
                "condition": row['condition'],
                "currentOwner": "Org1MSP",
                "location": row['location'],
                "status": "REGISTERED",
                "createdAt": "2026-01-01T00:00:00Z"
            }
            devices.append(device)
    
    return devices

if __name__ == "__main__": 
    print("🚀 Loading E-Waste Dataset\n")
    
    devices = load_devices_from_csv()
    
    output_dir = Path(__file__).parent.parent / 'data' / 'processed'
    output_dir.mkdir(parents=True, exist_ok=True)
    
    with open(output_dir / 'devices.json', 'w') as f:
        json.dump(devices, f, indent=2)
    
    print(f"✅ Loaded {len(devices)} devices")
    print(f"📁 Saved to:  {output_dir / 'devices.json'}")
