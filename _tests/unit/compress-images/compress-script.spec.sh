#!/usr/bin/env shellspec
# Tests for compress-images/compress_images.mjs, which compresses the images under
# working-directory with sharp and writes the action's outputs. They run the script as the
# Compress Images step does, from a scratch workspace, with a stand-in sharp in TOOLS. The
# script hands sharp the bytes it read, and each test image begins with its own name, so the
# stand-in knows which file it has: it logs each encode, with the options sharp was made with,
# to STUB_LOG, gives each file the output size STUB_SIZES maps its name to (its own size
# otherwise) and the frame count STUB_PAGES maps it to (one otherwise), and cannot read the
# file STUB_FAIL names.

Describe "compress-images compress_images.mjs"
SCRIPT="${PROJECT_ROOT}/compress-images/compress_images.mjs"

before() {
  shellspec_setup_test_env "compress-images-script-$$"
  TOOLS="${SHELLSPEC_TEST_TEMP_DIR}/tools"
  mkdir -p "${TOOLS}/node_modules/sharp"
  printf '%s\n' '{"name": "tools", "private": true}' >"${TOOLS}/package.json"
  cat >"${TOOLS}/node_modules/sharp/index.js" <<'JS'
const fs = require('node:fs');
module.exports = (input, made = {}) => {
  const name = input.toString('utf8').split('\0')[0];
  return {
    async metadata() {
      return { pages: JSON.parse(process.env.STUB_PAGES || '{}')[name] ?? 1 };
    },
    toFormat(format, options) {
      return {
        async toBuffer() {
          fs.appendFileSync(process.env.STUB_LOG, `${JSON.stringify({ name, format, options, made })}\n`);
          if (process.env.STUB_FAIL && name === process.env.STUB_FAIL) {
            throw new Error('Input file contains unsupported image format');
          }
          const size = JSON.parse(process.env.STUB_SIZES || '{}')[name] ?? input.length;
          return { data: Buffer.alloc(size, 7), info: { size } };
        },
      };
    },
  };
};
JS
  export TOOLS STUB_LOG="${SHELLSPEC_TEST_TEMP_DIR}/sharp.log" STUB_SIZES='{}' STUB_PAGES='{}' STUB_FAIL=""
  : >"$STUB_LOG"
  export WORKING_DIRECTORY="." IMAGE_QUALITY="85" PNG_QUALITY="95" IGNORE_PATHS="node_modules/**,dist/**,build/**"
}
BeforeEach 'before'

after() {
  unset TOOLS STUB_LOG STUB_SIZES STUB_PAGES STUB_FAIL WORKING_DIRECTORY IMAGE_QUALITY PNG_QUALITY IGNORE_PATHS
  shellspec_cleanup_test_env "compress-images-script-$$"
}
AfterEach 'after'

# image PATH BYTES: a file of BYTES bytes at PATH: its name, then zero bytes.
image() {
  local name
  name=$(basename "$1")
  mkdir -p "$(dirname "$1")"
  printf '%s' "$name" >"$1"
  head -c "$(($2 - ${#name}))" /dev/zero >>"$1"
}

size_of() {
  wc -c <"$1" | tr -d ' '
}

run_script() {
  node "$SCRIPT"
}

# output NAME: the value the script wrote for NAME, a single line or a delimited block.
output() {
  awk -v name="$1" '
    !block && index($0, name "=") == 1 { print substr($0, length(name) + 2); exit }
    !block && index($0, name "<<") == 1 { block = substr($0, length(name) + 3); next }
    block && $0 == block { exit }
    block { print }
  ' "$GITHUB_OUTPUT"
}

output_compressed() {
  output images_compressed
}

report_text() {
  output compression_report
}

# The runner fails the step unless a line equal to the delimiter closes the value.
report_is_closed() {
  delimiter=$(sed -n 's/^compression_report<<//p' "$GITHUB_OUTPUT")
  [ -n "$delimiter" ] && grep -Fxq "$delimiter" "$GITHUB_OUTPUT"
}

It "rewrites an image that gets at least 1 KiB and 5% smaller, and reports it"
image big.png 20000
export STUB_SIZES='{"big.png": 10000}'
When call run_script
The status should be success
The stdout should include "1 compressed, 0 unchanged, 0 unreadable"
The result of function output_compressed should equal "true"
The result of function report_text should include '- `big.png`: 19.5 KB to 9.8 KB, 50.0% smaller'
The result of function report_text should include "Compression reduced images by **50.0%**, saving **9.8 KB**."
Assert test "$(size_of big.png)" -eq 10000
End

It "keeps an image that saves less than 1 KiB, however large the share"
image small.png 1500
export STUB_SIZES='{"small.png": 600}'
When call run_script
The status should be success
The stdout should include "0 compressed, 1 unchanged, 0 unreadable"
Assert test "$(size_of small.png)" -eq 1500
End

It "keeps an image that saves less than 5%, however many bytes"
image large.png 100000
export STUB_SIZES='{"large.png": 96000}'
When call run_script
The status should be success
The stdout should include "0 compressed, 1 unchanged, 0 unreadable"
Assert test "$(size_of large.png)" -eq 100000
End

It "reports no compression, with an empty report, when nothing got smaller"
image same.jpg 5000
When call run_script
The status should be success
The result of function output_compressed should equal "false"
The result of function report_text should equal ""
End

# The validator splits the list the same way: a comma inside braces belongs to the glob.
It "skips the ignored paths, with a comma inside braces belonging to the glob"
image node_modules/a.png 20000
image dist/b.png 20000
image build/c.png 20000
image keep/d.png 20000
export IGNORE_PATHS="node_modules/**, {dist,build}/**"
export STUB_SIZES='{"a.png": 1, "b.png": 1, "c.png": 1, "d.png": 1}'
When call run_script
The status should be success
The stdout should include "1 compressed, 0 unchanged, 0 unreadable"
Assert test "$(size_of node_modules/a.png)" -eq 20000
Assert test "$(size_of dist/b.png)" -eq 20000
Assert test "$(size_of build/c.png)" -eq 20000
Assert test "$(size_of keep/d.png)" -eq 1
End

It "compresses only under working-directory, naming each file from the workspace"
image site/img/a.png 20000
image other/b.png 20000
export WORKING_DIRECTORY="site" STUB_SIZES='{"a.png": 1, "b.png": 1}'
When call run_script
The status should be success
The result of function report_text should include '`site/img/a.png`'
Assert test "$(size_of other/b.png)" -eq 20000
End

# A link could point outside the workspace, and writing through it would change that file.
It "never reads through a symbolic link, to a file or a directory"
image "${SHELLSPEC_TEST_TEMP_DIR}/outside/victim.png" 20000
mkdir -p img
ln -s "${SHELLSPEC_TEST_TEMP_DIR}/outside/victim.png" img/link.png
ln -s "${SHELLSPEC_TEST_TEMP_DIR}/outside" img/linkdir
export STUB_SIZES='{"victim.png": 1, "link.png": 1}'
When call run_script
The status should be success
The stdout should include "0 compressed, 0 unchanged, 0 unreadable"
Assert test "$(size_of "${SHELLSPEC_TEST_TEMP_DIR}/outside/victim.png")" -eq 20000
End

It "compresses images in dot directories, but nothing under .git"
image .github/social.png 20000
image .git/objects/x.png 20000
export STUB_SIZES='{"social.png": 1, "x.png": 1}'
When call run_script
The status should be success
The result of function report_text should include '`.github/social.png`'
Assert test "$(size_of .git/objects/x.png)" -eq 20000
End

It "gives sharp the JPEG and PNG quality, and the settings for each format"
image a.jpg 100
image b.png 100
image c.webp 100
image d.avif 100
export IMAGE_QUALITY="70" PNG_QUALITY="60"
When call run_script
The status should be success
The stdout should include "0 compressed, 4 unchanged, 0 unreadable"
The contents of file "$STUB_LOG" should include '"name":"a.jpg","format":"jpeg","options":{"quality":70,"progressive":false,"chromaSubsampling":"4:4:4"}'
The contents of file "$STUB_LOG" should include '"name":"b.png","format":"png","options":{"quality":60,"compressionLevel":9}'
The contents of file "$STUB_LOG" should include '"name":"c.webp","format":"webp","options":{"quality":85,"smartSubsample":true}'
The contents of file "$STUB_LOG" should include '"name":"d.avif","format":"avif","options":{"quality":75}'
End

# sharp drops the EXIF orientation from what it writes, so a rotated photo would turn sideways
# unless its pixels are rotated first.
It "makes sharp rotate each image by its EXIF orientation before encoding it"
image photo.jpg 100
When call run_script
The status should be success
The stdout should include "1 unchanged"
The contents of file "$STUB_LOG" should include '"name":"photo.jpg","format":"jpeg"'
The contents of file "$STUB_LOG" should include '"made":{"autoOrient":true}'
End

It "compresses an image whose extension is in capitals"
image PHOTO.JPG 20000
image icon.PNG 20000
export STUB_SIZES='{"PHOTO.JPG": 1, "icon.PNG": 1}'
When call run_script
The status should be success
The stdout should include "2 compressed"
The contents of file "$STUB_LOG" should include '"name":"PHOTO.JPG","format":"jpeg"'
The contents of file "$STUB_LOG" should include '"name":"icon.PNG","format":"png"'
End

# sharp reads one frame unless told otherwise, so the smaller file would be a still image.
It "leaves an animated WebP or AVIF as it is"
image anim.webp 20000
image seq.avif 20000
export STUB_PAGES='{"anim.webp": 3, "seq.avif": 2}' STUB_SIZES='{"anim.webp": 1, "seq.avif": 1}'
When call run_script
The status should be success
The stdout should include "0 compressed, 0 unchanged, 0 unreadable, 2 animated"
Assert test "$(size_of anim.webp)" -eq 20000
Assert test "$(size_of seq.avif)" -eq 20000
End

# libvips counts only top-level image items, so a sequence with a still primary image reads as
# one page; the avis brand in its ftyp box marks it.
It "leaves an AVIF image sequence as it is, and still compresses a still AVIF"
printf '\0\0\0\030ftypavif\0\0\0\0mif1avis' >seq.avif
head -c 20000 /dev/zero >>seq.avif
printf '\0\0\0\030ftypavif\0\0\0\0mif1miaf' >still.avif
head -c 20000 /dev/zero >>still.avif
When call run_script
The status should be success
The stdout should include "0 compressed, 1 unchanged, 0 unreadable, 1 animated"
The stdout should include "Left seq.avif as it is: an animation"
Assert test "$(size_of seq.avif)" -eq 20024
End

# libvips reads only the default image of an APNG: an acTL chunk before the image data marks one.
It "leaves an animated PNG as it is, and reports it"
printf 'anim.png\0\0\0\0acTL' >anim.png
head -c 20000 /dev/zero >>anim.png
image still.png 20000
export STUB_SIZES='{"anim.png": 1, "still.png": 1}'
When call run_script
The status should be success
The stdout should include "1 compressed, 0 unchanged, 0 unreadable, 1 animated"
The stdout should include "Left anim.png as it is: an animation"
The result of function report_text should include "1 animated image was left as it is."
Assert test "$(size_of anim.png)" -eq 20016
End

It "skips an image it cannot read, with a warning, and compresses the rest"
image broken.webp 20000
image fine.png 20000
export STUB_FAIL="broken.webp" STUB_SIZES='{"fine.png": 1}'
When call run_script
The status should be success
The stdout should include "::warning file=broken.webp::Could not compress broken.webp"
The stdout should include "1 compressed, 0 unchanged, 1 unreadable"
The result of function report_text should include "1 image could not be read; see the step log."
End

# A code span shows the name as text: HTML or a link does not render, and in a list a pipe or
# backslash needs no escape.
It "keeps a file name from adding HTML or a link to the report"
image 'a|<b>\c.png' 20000
image '[x](https:evil.example).png' 20000
export STUB_SIZES='{"a|<b>\\c.png": 1, "[x](https:evil.example).png": 1}'
When call run_script
The status should be success
The stdout should include "2 compressed"
The result of function report_text should include '- `a|<b>\c.png`: '
The result of function report_text should include '- `[x](https:evil.example).png`: '
End

It "fences a file name holding a backtick with a longer run of them"
image 'a`b.png' 20000
export STUB_SIZES='{"a`b.png": 1}'
When call run_script
The status should be success
The stdout should include "1 compressed"
The result of function report_text should include '``a`b.png``'
End

# A name with a line break would otherwise put a workflow command on a line of its own.
It "escapes a file name in the workflow commands it logs"
image "$(printf 'x\n::error::forged.png')" 20000
export STUB_FAIL="$(printf 'x\n::error::forged.png')"
When call run_script
The status should be success
The stdout should include "::warning file=x%0A%3A%3Aerror%3A%3Aforged.png::"
The stdout should not include "$(printf '\n::error::forged')"
End

# Renaming a new file over the old one changes the path only, not a file it shares an inode with.
It "never writes through a hard link to a file elsewhere"
image "${SHELLSPEC_TEST_TEMP_DIR}/outside/original.png" 20000
mkdir -p img
ln "${SHELLSPEC_TEST_TEMP_DIR}/outside/original.png" img/original.png
export STUB_SIZES='{"original.png": 1}'
When call run_script
The status should be success
The stdout should include "1 compressed"
Assert test "$(size_of img/original.png)" -eq 1
Assert test "$(size_of "${SHELLSPEC_TEST_TEMP_DIR}/outside/original.png")" -eq 20000
End

big_png_mode() {
  stat -c '%a' big.png
}

It "keeps the mode of a file it rewrites, and leaves no temporary file"
image big.png 20000
chmod 640 big.png
export STUB_SIZES='{"big.png": 1}'
When call run_script
The status should be success
The stdout should include "1 compressed"
The result of function big_png_mode should equal "640"
Assert test -z "$(find . -name '*.compress-images-*' -print)"
End

# As the validator splits it: an unclosed brace groups nothing, so the list holds {a and b.
It "splits the ignore list as the validator does, an unclosed brace grouping nothing"
image b/x.png 20000
export IGNORE_PATHS="{a,b" STUB_SIZES='{"x.png": 1}'
When call run_script
The status should be success
The stdout should include "0 compressed, 0 unchanged, 0 unreadable"
Assert test "$(size_of b/x.png)" -eq 20000
End

# The runner fails the step unless a line equal to the delimiter closes the value.
It "closes the report output on a line of its own"
image big.png 20000
export STUB_SIZES='{"big.png": 1}'
When call run_script
The status should be success
The stdout should include "Compressed big.png: 19.5 KB -> 1 B"
Assert report_is_closed
End

It "ignores image files of other kinds and directories named like images"
image notes.txt 20000
image photo.gif 20000
mkdir -p folder.png
export STUB_SIZES='{"notes.txt": 1, "photo.gif": 1}'
When call run_script
The status should be success
The stdout should include "0 compressed, 0 unchanged, 0 unreadable"
End

End
