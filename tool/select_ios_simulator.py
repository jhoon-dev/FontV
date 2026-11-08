"""Select an available simulator matching Apple's required screenshot sizes."""
import json
import sys

form = sys.argv[1]
available = [
    device
    for runtime, devices in json.load(sys.stdin)["devices"].items()
    if "iOS" in runtime
    for device in devices
    if device.get("isAvailable", True)
]
# Air 13-inch produces Apple's accepted 2048x2732 size without the newer
# Pro M5 simulator's heavier startup on shared CI hosts.
matchers = (
    [lambda name: name.startswith("iPhone") and "Pro" in name and "Max" not in name]
    if form == "iphone"
    else [
        lambda name: "iPad Air 13-inch" in name,
        lambda name: "iPad Pro" in name and ("13-inch" in name or "12.9" in name),
    ]
)
for matches in matchers:
    for device in available:
        if matches(device["name"]):
            print(f"Store capture: {device['name']}", file=sys.stderr)
            print(device["udid"])
            sys.exit(0)
sys.exit(f"No required {form} simulator is available")
