"""Check the app target and actual linked-code minimum OS requirements."""
import pathlib
import plistlib
import re
import subprocess
import sys


def version(value):
    return tuple((list(map(int, value.split('.'))) + [0, 0, 0])[:3])


def minimum_versions(binary):
    commands = subprocess.check_output(
        ['xcrun', 'otool', '-arch', 'all', '-l', str(binary)], text=True
    )
    values = re.findall(r'\bminos\s+([0-9.]+)', commands)
    values += re.findall(
        r'cmd LC_VERSION_MIN_IPHONEOS\s+cmdsize \d+\s+version ([0-9.]+)', commands
    )
    assert values, f'No minimum OS load command: {binary}'
    return values


root = pathlib.Path('build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app')
app = plistlib.loads((root / 'Info.plist').read_bytes())
target = version(app['MinimumOSVersion'])
assert target == version('15.0'), 'Unexpected app deployment target'
assert app['CFBundleIdentifier'] == sys.argv[1] and app['CFBundleVersion'] == sys.argv[2]

binaries = [root / app['CFBundleExecutable']]
for path in root.glob('Frameworks/*.framework/Info.plist'):
    metadata = plistlib.loads(path.read_bytes())
    executable = path.parent / metadata.get('CFBundleExecutable', path.parent.stem)
    if executable.exists():
        binaries.append(executable)
linked_libraries = subprocess.check_output(
    ['xcrun', 'otool', '-L', *map(str, binaries)], text=True
)

for info_path in root.glob('Frameworks/*.framework/Info.plist'):
    info = plistlib.loads(info_path.read_bytes())
    binary = info_path.parent / info.get('CFBundleExecutable', info_path.parent.stem)
    if not binary.exists():
        print(f'Resource-only framework: {info_path.parent.name}')
        continue
    with binary.open('rb') as stream:
        is_static = stream.read(8) == b'!<arch>\n'
    minimums = minimum_versions(binary)
    if (info.get('CFBundleIdentifier') == 'com.google.UserMessagingPlatform'
            and set(map(version, minimums)) == {version('100.0')}):
        # Xcode creates an unloaded resource stub from Google's static SDK.
        # Google deliberately sets its plist to 100.0 (upstream issue #62).
        # Require BOTH no dynamic references and compatible original objects;
        # never ignore a genuine linked framework's higher OS requirement.
        assert not re.search(
            r'^\s+\S*/UserMessagingPlatform\.framework/UserMessagingPlatform\s+\(',
            linked_libraries, re.MULTILINE
        ), 'Unexpected dynamic dependency on UMP resource stub'
        originals = list(pathlib.Path('build/ios').rglob(
            'UserMessagingPlatform.xcframework/ios-arm64/UserMessagingPlatform.framework/UserMessagingPlatform'
        ))
        assert originals, 'Original UMP static SDK unavailable for compatibility validation'
        for original in originals:
            assert original.read_bytes()[:8] == b'!<arch>\n', 'UMP SDK is no longer static'
            actual = minimum_versions(original)
            assert all(version(value) <= target for value in actual), f'Incompatible UMP objects: {actual}'
        print(f'Compatible UMP static SDK: {sorted(set(actual))}; resource stub is not linked')
        continue
    assert all(version(value) <= target for value in minimums), (
        f'Framework requires a newer target: {binary}: {sorted(set(minimums))}'
    )
    print(f'Compatible {info_path.parent.name} (static={is_static}): {sorted(set(minimums))}')

print('Verified iOS 15.0 deployment target and actual embedded code compatibility.')
