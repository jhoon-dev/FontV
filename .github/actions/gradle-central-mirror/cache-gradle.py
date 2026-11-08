"""Seed the wrapper cache through Gradle's official GitHub release API.

The usual distribution URL redirects to github.com, which repeatedly returned
HTTP 504 on runners. gh downloads the same release asset through the API.
The wrapper's committed SHA-256 is checked before Gradle can use the ZIP.
"""

import argparse
import hashlib
import os
from pathlib import Path
import re
import subprocess
import time


def base36(number):
    result = ""
    while number:
        number, remainder = divmod(number, 36)
        result = "0123456789abcdefghijklmnopqrstuvwxyz"[remainder] + result
    return result or "0"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--gradle-home", type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[3]
    properties = dict(
        line.split("=", 1)
        for line in (root / "android/gradle/wrapper/gradle-wrapper.properties")
        .read_text(encoding="utf-8").splitlines()
        if "=" in line and not line.lstrip().startswith("#")
    )
    url = properties["distributionUrl"].replace("\\:", ":")
    match = re.fullmatch(
        r"https://(?:services|downloads)\.gradle\.org/distributions/"
        r"(gradle-(\d+\.\d+(?:\.\d+)?)-(?:all|bin)\.zip)", url
    )
    checksum = properties.get("distributionSha256Sum", "")
    if not match or not re.fullmatch(r"[a-f0-9]{64}", checksum):
        raise ValueError("Require an official Gradle distribution and pinned SHA-256")
    filename, version = match.groups()
    home = args.gradle_home or Path(os.environ.get("GRADLE_USER_HOME", Path.home() / ".gradle"))
    # This is Gradle PathAssembler's URL-to-cache-key algorithm (not a checksum).
    cache_key = base36(int.from_bytes(hashlib.md5(url.encode()).digest(), "big"))
    cache = home / "wrapper/dists" / filename.removesuffix(".zip") / cache_key
    archive = cache / filename
    if (cache / (filename + ".ok")).exists() and (cache / f"gradle-{version}/bin/gradle").exists():
        print(f"Gradle {version} wrapper distribution is already installed")
        return
    cache.mkdir(parents=True, exist_ok=True)
    for attempt in range(3):
        if archive.exists():
            with archive.open("rb") as stream:
                actual = hashlib.file_digest(stream, "sha256").hexdigest()
            if actual == checksum:
                print(f"Verified Gradle {version} wrapper cache ZIP: {actual}")
                return
        result = subprocess.run([
            "gh", "release", "download", f"v{version}", "--repo", "gradle/gradle-distributions",
            "--pattern", filename, "--dir", str(cache), "--clobber",
        ], check=False)
        if result.returncode == 0:
            with archive.open("rb") as stream:
                actual = hashlib.file_digest(stream, "sha256").hexdigest()
            if actual != checksum:
                raise ValueError("Gradle release asset SHA-256 does not match the pinned value")
            print(f"Verified Gradle {version} official release asset: {actual}")
            return
        if attempt < 2:
            time.sleep(3 * (attempt + 1))
    raise RuntimeError("Could not download the official Gradle release asset")


if __name__ == "__main__":
    main()
