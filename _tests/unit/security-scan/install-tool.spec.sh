#!/usr/bin/env shellspec
# Tests for security-scan/install_tool.py, which installs a scanner binary from a release
# archive once the archive's SHA-256 matches the digest a sums file pins. The archives are
# fixtures built here, and nothing is downloaded: the download tests use URLs that fail
# before a connection, and record the waits between attempts instead of sleeping.

Describe "security-scan install_tool.py"
INSTALL_TOOL="${PROJECT_ROOT}/security-scan/install_tool.py"

before() {
  shellspec_setup_test_env "security-scan-install-tool-$$"
  mkdir dest
  # Every sums file starts with a comment and a blank line, which the parser skips.
  printf '# pins\n\n' >sums
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "security-scan-install-tool-$$"
}
AfterEach 'after'

install_tool() {
  python3 "$INSTALL_TOOL" "$@"
}

# make_archive NAME MEMBER [CONTENT] [TYPE]: build the .tar.gz or .zip archive NAME holding
# MEMBER. TYPE "symlink" makes MEMBER a tar symlink instead of a regular file.
make_archive() {
  python3 - "$1" "$2" "${3:-binary}" "${4:-file}" <<'PY'
import io
import sys
import tarfile
import zipfile

name, member, content, kind = sys.argv[1:5]
data = content.encode()
if name.endswith(".zip"):
    with zipfile.ZipFile(name, "w") as archive:
        archive.writestr(member, data)
else:
    with tarfile.open(name, "w:gz") as archive:
        info = tarfile.TarInfo(member)
        if kind == "symlink":
            info.type = tarfile.SYMTYPE
            info.linkname = "../outside"
            archive.addfile(info)
        else:
            info.size = len(data)
            archive.addfile(info, io.BytesIO(data))
PY
}

# pin FILE [NAME]: add FILE's SHA-256 to sums under NAME, FILE by default.
pin() {
  printf '%s  %s\n' "$(sha256sum "$1" | cut -d' ' -f1)" "${2:-$1}" >>sums
}

dest_is_empty() {
  [ -z "$(ls -A dest)" ]
}

# download_attempts URL: run the download of URL with each wait recorded instead of slept,
# and print how it exited, how many attempts it made and the waits between them.
download_attempts() {
  python3 - "${PROJECT_ROOT}/security-scan" "$1" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, sys.argv[1])
import install_tool

waits = []
attempts = []
fetch = install_tool.fetch
install_tool.time.sleep = waits.append


def counted(opener, url):
    attempts.append(url)
    return fetch(opener, url)


install_tool.fetch = counted
try:
    install_tool.download(sys.argv[2], Path("downloaded.tar.gz"))
except SystemExit as exit_status:
    print(f"exit={exit_status.code} attempts={len(attempts)} waits={waits}")
PY
}

# opener_error URL: print the error the download opener raises for URL.
opener_error() {
  python3 - "${PROJECT_ROOT}/security-scan" "$1" <<'PY'
import sys

sys.path.insert(0, sys.argv[1])
import install_tool

print(install_tool.fetch(install_tool.https_opener(), sys.argv[2]))
PY
}

Describe "install"
It "installs the binary from a pinned .tar.gz as an executable and prints its path"
make_archive tool_1.0_linux_x64.tar.gz tool "linux binary"
pin tool_1.0_linux_x64.tar.gz
When call install_tool install sums tool_1.0_linux_x64.tar.gz tool dest
The status should be success
The output should equal "dest/tool"
Assert test -x dest/tool
The contents of file dest/tool should equal "linux binary"
End

It "installs the binary from a pinned .zip"
make_archive tool_1.0_windows_x64.zip tool.exe "windows binary"
pin tool_1.0_windows_x64.zip
When call install_tool install sums tool_1.0_windows_x64.zip tool.exe dest
The status should be success
The output should equal "dest/tool.exe"
The contents of file dest/tool.exe should equal "windows binary"
End

It "refuses an archive whose SHA-256 is not the pinned one, and writes nothing"
make_archive tool.tar.gz tool "released"
pin tool.tar.gz
make_archive tool.tar.gz tool "replaced"
When call install_tool install sums tool.tar.gz tool dest
The status should be failure
The output should include "::error::tool.tar.gz has SHA-256"
The output should include "but sums pins"
Assert dest_is_empty
End

It "refuses an archive the sums file pins nothing for"
make_archive tool.tar.gz tool
When call install_tool install sums tool.tar.gz tool dest
The status should be failure
The output should include "::error::sums pins no SHA-256 for tool.tar.gz"
Assert dest_is_empty
End

It "takes a pin only for the exact archive name"
make_archive tool.tar.gz tool
pin tool.tar.gz other-tool.tar.gz
When call install_tool install sums tool.tar.gz tool dest
The status should be failure
The output should include "pins no SHA-256 for tool.tar.gz"
Assert dest_is_empty
End

It "takes no pin from a comment"
make_archive tool.tar.gz tool
printf '# %s  tool.tar.gz\n' "$(sha256sum tool.tar.gz | cut -d' ' -f1)" >>sums
When call install_tool install sums tool.tar.gz tool dest
The status should be failure
The output should include "pins no SHA-256 for tool.tar.gz"
Assert dest_is_empty
End

It "refuses a tar member that is not a regular file"
make_archive tool.tar.gz tool "" symlink
pin tool.tar.gz
When call install_tool install sums tool.tar.gz tool dest
The status should be failure
The output should include "::error::tool in tool.tar.gz is not a regular file"
Assert dest_is_empty
End

It "fails when the archive holds no such member"
make_archive tool.tar.gz other
pin tool.tar.gz
When call install_tool install sums tool.tar.gz tool dest
The status should be failure
The output should include "::error::tool.tar.gz holds no tool"
Assert dest_is_empty
End

It "fails on a pinned file that is not a readable archive"
printf 'not an archive' >tool.tar.gz
pin tool.tar.gz
When call install_tool install sums tool.tar.gz tool dest
The status should be failure
The output should include "::error::tool.tar.gz is not a readable archive"
Assert dest_is_empty
End

It "refuses an archive that is neither a .tar.gz nor a .zip"
printf 'bzip2 data' >tool.tar.bz2
pin tool.tar.bz2
When call install_tool install sums tool.tar.bz2 tool dest
The status should be failure
The output should include "::error::tool.tar.bz2 is neither a .tar.gz nor a .zip archive"
Assert dest_is_empty
End

Describe "member names"
Parameters
"../tool"
"sub/tool"
'sub\tool'
"."
".."
End

It "refuses the member name $1, which is not a plain file name"
make_archive tool.tar.gz tool
pin tool.tar.gz
When call install_tool install sums tool.tar.gz "$1" dest
The status should be failure
The output should include "::error::the member name must be a plain file name"
Assert dest_is_empty
End
End
End

Describe "download"
It "refuses a URL that is not HTTPS"
When call install_tool download http://example.invalid/tool.tar.gz tool.tar.gz
The status should be failure
The output should include "::error::refusing to download over anything but HTTPS"
Assert test ! -e tool.tar.gz
End

It "has no handler for plain HTTP, so a redirect cannot leave HTTPS"
When call opener_error http://127.0.0.1:9/tool.tar.gz
The status should be success
The output should include "unknown url type: http"
End

It "tries three times, waiting longer before each retry, then fails with the last error"
When call download_attempts https://127.0.0.1:9/tool.tar.gz
The status should be success
The output should include "::error::could not download https://127.0.0.1:9/tool.tar.gz"
The output should include "exit=1 attempts=3 waits=[5, 10]"
Assert test ! -e downloaded.tar.gz
End
End

It "prints its usage on unknown arguments"
When call install_tool frobnicate
The status should be failure
The output should include "::error::usage: install_tool.py download URL ARCHIVE"
End
End
