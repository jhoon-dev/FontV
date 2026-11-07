"""Check the app target and actual linked-code minimum OS requirements."""
import pathlib
import plistlib
import re
import subprocess
import sys


def version(value):
    return tuple((list(map(int, value.split('.'))) + [0, 0, 0])[:3])


root = pathlib.Path('build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app')
app = plistlib.loads((root / 'Info.plist').read_bytes())
target = version(app['MinimumOSVersion'])
assert target == version('15.0'), 'Unexpected app deployment target'
assert app['CFBundleIdentifier'] == sys.argv[1] and app['CFBundleVersion'] == sys.argv[2]

for info_path in root.glob('Frameworks/*.framework/Info.plist'):
    info = plistlib.loads(info_path.read_bytes())
    binary = info_path.parent / info.get('CFBundleExecutable', info_path.parent.stem)
    if not binary.exists():
        print(f'Resource-only framework: {info_path.parent.name}')
        continue
    with binary.open('rb') as stream:
        is_static = stream.read(8) == b'!<arch>\n'
    # Google's static UMP XCFramework uses a placeholder 100.0 in its plist.
    # Inspect every Mach-O object instead; its actual minimum is encoded in
    # LC_BUILD_VERSION / LC_VERSION_MIN_IPHONEOS, as with dynamic frameworks.
    load_commands = subprocess.check_output(
        ['xcrun', 'otool', '-arch', 'all', '-l', str(binary)], text=True
    )
    minimums = re.findall(r'\bminos\s+([0-9.]+)', load_commands)
    minimums += re.findall(
        r'cmd LC_VERSION_MIN_IPHONEOS\s+cmdsize \d+\s+version ([0-9.]+)', load_commands
    )
    assert minimums, f'No minimum OS load command: {binary}'
    assert all(version(value) <= target for value in minimums), (
        f'Framework requires a newer target: {binary}: {sorted(set(minimums))}'
    )
    print(f'Compatible {info_path.parent.name} (static={is_static}): {sorted(set(minimums))}')

print('Verified iOS 15.0 deployment target and actual embedded code compatibility.')
