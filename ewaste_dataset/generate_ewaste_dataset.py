import csv, random
from datetime import datetime, timedelta

random.seed(42)

CATEGORIES = ["Phone", "Laptop", "Tablet", "TV", "Printer", "Monitor", "Router", "Camera"]
BRANDS = ["Samsung", "Apple", "Xiaomi", "Dell", "HP", "Lenovo", "Acer", "Sony", "LG", "Asus"]
MODELS = ["A1", "S10", "X200", "Pro15", "G14", "VivoX", "Note9", "ThinkPad", "Inspiron", "Pavilion"]
CONDITIONS = ["Working", "Damaged", "Broken", "Battery issue", "Screen cracked"]
OWNERS = ["CollectorA", "CollectorB", "CollectorC", "RecyclerX", "RecyclerY"]
LOCATIONS = ["Kuala Lumpur", "Selangor", "Penang", "Johor", "Perak", "Melaka"]

def iso(t):
    return t.strftime("%Y-%m-%dT%H:%M:%SZ")

N_DEVICES = 200

start_time = datetime.utcnow() - timedelta(days=10)

devices = []
events = []

for i in range(1, N_DEVICES + 1):
    device_id = f"EW-{i:04d}"
    category = random.choice(CATEGORIES)
    brand = random.choice(BRANDS)
    model = random.choice(MODELS)
    weight = round(random.uniform(0.05, 15.0), 2)
    condition = random.choice(CONDITIONS)
    owner = random.choice(["CollectorA", "CollectorB", "CollectorC"])
    location = random.choice(LOCATIONS)

    devices.append([device_id, category, brand, model, weight, condition, owner, location])

    # Events: Registered -> Collected -> (Recycled or Disposed)
    t1 = start_time + timedelta(minutes=random.randint(0, 5000))
    t2 = t1 + timedelta(hours=random.randint(1, 48))
    t3 = t2 + timedelta(hours=random.randint(6, 72))

    events.append([device_id, "Registered", owner, location, "Initial registration", iso(t1)])
    events.append([device_id, "Collected", owner, location, "Collected from user", iso(t2)])

    final_status = random.choice(["Recycled", "Disposed"])
    final_owner = random.choice(["RecyclerX", "RecyclerY"])
    final_loc = random.choice(LOCATIONS)

    events.append([device_id, final_status, final_owner, final_loc, f"Final stage: {final_status.lower()}", iso(t3)])

with open("ewaste_devices.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["deviceId","category","brand","model","weightKg","condition","owner","location"])
    w.writerows(devices)

with open("ewaste_events.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["deviceId","status","owner","location","note","timestamp"])
    w.writerows(events)

print("Generated: ewaste_devices.csv (200 rows) and ewaste_events.csv (~600 rows)")
