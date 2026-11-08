"""Select an available large store-screenshot simulator from simctl JSON."""
import json
import sys

form = sys.argv[1]
for runtime, devices in json.load(sys.stdin)["devices"].items():
    if "iOS" not in runtime:
        continue
    for device in devices:
        name = device["name"]
        matches = (
            name.startswith("iPhone") and "Pro" in name and "Max" not in name
            if form == "iphone"
            else "iPad Pro" in name and ("13-inch" in name or "12.9" in name)
        )
        if matches and device.get("isAvailable", True):
            print(f"Store capture: {name}", file=sys.stderr)
            print(device["udid"])
            sys.exit(0)
sys.exit(f"No large {form} simulator is available")
