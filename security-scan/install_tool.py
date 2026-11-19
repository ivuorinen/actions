"""Install one of security-scan's scanner binaries from its pinned release archive.

Usage:

    install_tool.py download URL ARCHIVE
    install_tool.py install SUMS ARCHIVE MEMBER DEST_DIR

``download`` fetches URL over HTTPS into ARCHIVE. ``install`` checks ARCHIVE's SHA-256
against the line for its file name in SUMS, a sha256sum-format list in which lines starting
with ``#`` are comments, then writes the archive member MEMBER, the binary, to DEST_DIR as
an executable and prints its path. The digest pinned in SUMS is what makes the archive
trusted: a release asset can be replaced under the same name, and a checksums file from
the same release would be replaced with it. Each failure prints an ``::error::`` line and
exits 1 before anything is written to DEST_DIR. Standard library only, like validate.py.

This is Python rather than shell because the action runs on macOS and Windows as well, where
.claude/rules/posix-shell.md allows no reliance on GNU tools such as sha256sum, and a shell
step would need a different hashing and unpacking tool on each. python3 is already required
for validate.py.
"""

from __future__ import annotations

import hashlib
import http.client
import io
from pathlib import Path
import stat
import sys
import tarfile
import time
import urllib.request
import zipfile

ATTEMPTS = 3
TIMEOUT_SECONDS = 60


def fail(message: str) -> None:
    """Print MESSAGE as an error annotation and exit 1."""
    print(f"::error::{message}")
    sys.exit(1)


def https_opener() -> urllib.request.OpenerDirector:
    """Return an opener that has no handler for plain HTTP, so no redirect can leave HTTPS.

    UnknownHandler turns a URL no other handler takes into a URLError, which is an OSError.
    """
    opener = urllib.request.OpenerDirector()
    for handler in (
        urllib.request.ProxyHandler(),
        urllib.request.UnknownHandler(),
        urllib.request.HTTPSHandler(),
        urllib.request.HTTPRedirectHandler(),
        urllib.request.HTTPErrorProcessor(),
        urllib.request.HTTPDefaultErrorHandler(),
    ):
        opener.add_handler(handler)
    return opener


def fetch(opener: urllib.request.OpenerDirector, url: str) -> tuple[bytes | None, str]:
    """Return URL's body and no error, or no body and the reason this attempt failed.

    A connection that drops mid-body raises an HTTPException such as IncompleteRead, which
    is not an OSError.
    """
    try:
        with opener.open(url, timeout=TIMEOUT_SECONDS) as response:
            return response.read(), ""
    except (OSError, http.client.HTTPException) as error:
        return None, str(error)


def download(url: str, archive: Path) -> None:
    """Fetch URL over HTTPS into ARCHIVE, retrying a failed fetch."""
    if not url.startswith("https://"):
        fail(f"refusing to download over anything but HTTPS: {url}")
    opener = https_opener()
    error = ""
    for attempt in range(1, ATTEMPTS + 1):
        data, error = fetch(opener, url)
        if data is not None:
            archive.write_bytes(data)
            return
        if attempt < ATTEMPTS:
            time.sleep(attempt * 5)
    fail(f"could not download {url}: {error}")


def pinned_digest(sums: Path, name: str) -> str:
    """Return the SHA-256 that SUMS pins for the archive file NAME."""
    for line in sums.read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        digest, _, listed = line.partition("  ")
        if listed == name:
            return digest
    fail(f"{sums.name} pins no SHA-256 for {name}; add it from the release's checksums file")
    return ""


def member_bytes(data: bytes, archive_name: str, member: str) -> bytes:
    """Return the regular file MEMBER from the .tar.gz or .zip archive DATA."""
    try:
        if archive_name.endswith(".tar.gz"):
            with tarfile.open(fileobj=io.BytesIO(data), mode="r:gz") as archive:
                info = archive.getmember(member)
                extracted = archive.extractfile(info) if info.isfile() else None
                if extracted is None:
                    fail(f"{member} in {archive_name} is not a regular file")
                    return b""
                return extracted.read()
        if archive_name.endswith(".zip"):
            with zipfile.ZipFile(io.BytesIO(data)) as archive:
                return archive.read(member)
    except KeyError:
        fail(f"{archive_name} holds no {member}")
    except (tarfile.TarError, zipfile.BadZipFile) as error:
        fail(f"{archive_name} is not a readable archive: {error}")
    fail(f"{archive_name} is neither a .tar.gz nor a .zip archive")
    return b""


def install(sums: Path, archive: Path, member: str, dest_dir: Path) -> Path:
    """Verify ARCHIVE against SUMS and write its MEMBER to DEST_DIR as an executable."""
    if "/" in member or "\\" in member or member in ("", ".", ".."):
        fail(f"the member name must be a plain file name: {member!r}")
    data = archive.read_bytes()
    expected = pinned_digest(sums, archive.name)
    actual = hashlib.sha256(data).hexdigest()
    if actual != expected:
        fail(f"{archive.name} has SHA-256 {actual}, but {sums.name} pins {expected}")
    target = dest_dir / member
    target.write_bytes(member_bytes(data, archive.name, member))
    target.chmod(target.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    return target


def main(argv: list[str]) -> None:
    """Run the subcommand ARGV names."""
    if len(argv) == 3 and argv[0] == "download":
        download(argv[1], Path(argv[2]))
    elif len(argv) == 5 and argv[0] == "install":
        print(install(Path(argv[1]), Path(argv[2]), argv[3], Path(argv[4])))
    else:
        fail("usage: install_tool.py download URL ARCHIVE | install SUMS ARCHIVE MEMBER DEST_DIR")


if __name__ == "__main__":
    main(sys.argv[1:])
