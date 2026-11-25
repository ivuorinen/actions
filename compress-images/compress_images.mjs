// Compresses the images under a directory with sharp, in place, and writes the compress-images
// outputs. A file is rewritten only when the result saves at least MIN_BYTES and MIN_PERCENT,
// the thresholds and per-format settings calibreapp/image-actions used before this replaced it.
//
// Environment:
//   TOOLS              the npm prefix this action's package-lock.json was installed into
//   WORKING_DIRECTORY  the directory to compress, relative to the current directory
//   IMAGE_QUALITY      JPEG quality, 1-100
//   PNG_QUALITY        PNG quality, 1-100
//   IGNORE_PATHS       comma-separated globs relative to WORKING_DIRECTORY, split as the
//                      validator splits them
//   GITHUB_OUTPUT      the step output file
//
// The walk enters only real directories and takes only regular files. Each file is then opened
// without following a symbolic link, checked to be the file the walk found, read through that
// descriptor, and replaced by renaming a new file over it: a link swapped in meanwhile, or a
// hard link to a file elsewhere, is never written through.

import { createRequire } from 'node:module';
import { randomBytes } from 'node:crypto';
import { appendFileSync, chmodSync, closeSync, constants, fstatSync, openSync, readdirSync, readFileSync, renameSync, rmSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

export const MIN_BYTES = 1024;
export const MIN_PERCENT = 5;

const FORMATS = new Map([
  ['.jpeg', 'jpeg'],
  ['.jpg', 'jpeg'],
  ['.png', 'png'],
  ['.webp', 'webp'],
  ['.avif', 'avif'],
]);

// Split a list as kit._split_items(globs=True) does: a comma inside braces belongs to the glob,
// an unclosed brace groups nothing, and spaces or tabs around an item are not part of it.
export function splitPatterns(value) {
  const split = globs => {
    const parts = [];
    let depth = 0;
    let start = 0;
    for (let index = 0; index < value.length; index += 1) {
      const char = value.charAt(index);
      if (globs && (char === '{' || char === '}')) {
        depth = char === '{' ? depth + 1 : Math.max(depth - 1, 0);
      } else if (depth === 0 && char === ',') {
        parts.push(value.slice(start, index));
        start = index + 1;
      }
    }
    if (depth) return null;
    parts.push(value.slice(start));
    return parts;
  };
  return (split(true) ?? split(false)).map(part => part.replace(/^[ \t]+|[ \t]+$/g, '')).filter(part => part !== '');
}

// Each image file under root, as a path relative to root with / separators.
export function findImages(root, ignore) {
  const found = [];
  const walk = relative => {
    // eslint-disable-next-line security/detect-non-literal-fs-filename -- a directory under root the walk listed
    for (const entry of readdirSync(path.join(root, relative), { withFileTypes: true })) {
      const child = relative ? `${relative}/${entry.name}` : entry.name;
      if (ignore.some(pattern => path.matchesGlob(child, pattern))) continue;
      if (entry.isDirectory()) {
        if (entry.name !== '.git') walk(child);
      } else if (entry.isFile() && FORMATS.has(path.extname(entry.name).toLowerCase())) {
        found.push(child);
      }
    }
  };
  walk('');
  return found.sort();
}

// The size of a file as the report shows it, in the units calibreapp/image-actions used.
export function formatSize(bytes) {
  if (bytes === 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  const unit = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), units.length - 1);
  const digits = unit === 0 ? 0 : 1;
  return `${(bytes / 1024 ** unit).toFixed(digits)} ${units.at(unit)}`;
}

// Text for a workflow command, escaped as @actions/core escapes it, so a file name cannot end
// the command or start another on a line of its own.
const escapeData = text => text.replace(/%/g, '%25').replace(/\r/g, '%0D').replace(/\n/g, '%0A');
const escapeProperty = text => escapeData(text).replace(/:/g, '%3A').replace(/,/g, '%2C');

// A file name as a Markdown code span: nothing in it renders as a link or as HTML. The report
// lists the names rather than putting them in a table, so a pipe needs no escape.
export function codeSpan(name) {
  const text = name.replace(/[\r\n]+/g, ' ');
  const longest = Math.max(0, ...(text.match(/`+/g) ?? []).map(run => run.length));
  const fence = '`'.repeat(longest + 1);
  const pad = text.startsWith('`') || text.endsWith('`') ? ' ' : '';
  return `${fence}${pad}${text}${pad}${fence}`;
}

const percent = (before, after) => (((before - after) / before) * 100).toFixed(1);

export function report(compressed, unchanged, unreadable, animated = 0) {
  if (compressed.length === 0) return '';
  const before = compressed.reduce((sum, image) => sum + image.before, 0);
  const after = compressed.reduce((sum, image) => sum + image.after, 0);
  const lines = [
    'Images compressed by compress-images.',
    '',
    `Compression reduced images by **${percent(before, after)}%**, saving **${formatSize(before - after)}**.`,
    '',
    ...compressed.map(image => `- ${codeSpan(image.name)}: ${formatSize(image.before)} to ${formatSize(image.after)}, ${percent(image.before, image.after)}% smaller`),
  ];
  if (unchanged > 0) {
    lines.push('', `${unchanged} ${unchanged === 1 ? 'image' : 'images'} did not require optimisation.`);
  }
  if (animated > 0) {
    lines.push('', `${animated} animated ${animated === 1 ? 'image was' : 'images were'} left as ${animated === 1 ? 'it is' : 'they are'}.`);
  }
  if (unreadable > 0) {
    lines.push('', `${unreadable} ${unreadable === 1 ? 'image' : 'images'} could not be read; see the step log.`);
  }
  return `${lines.join('\n')}\n`;
}

// Whether a PNG is an APNG animation: an acTL chunk comes before its first IDAT. libvips reads
// only the default image of one, so compressing it would drop the animation.
export function isAnimatedPng(data) {
  let offset = 8;
  while (offset + 8 <= data.length) {
    const type = data.toString('latin1', offset + 4, offset + 8);
    if (type === 'acTL') return true;
    if (type === 'IDAT') return false;
    offset += data.readUInt32BE(offset) + 12;
  }
  return false;
}

// Whether an AVIF is an image sequence: its ftyp box names the avis brand, as major or compatible
// brand. libvips counts only top-level image items as pages, so a sequence with a still primary
// image reads as one page. As in any ISO-BMFF box, a size of 1 means a 64-bit size follows the
// type, so the brands start 8 bytes later, and a size of 0 means the box runs to the file's end.
export function isAvifSequence(data) {
  if (data.length < 16 || data.toString('latin1', 4, 8) !== 'ftyp') return false;
  let size = data.readUInt32BE(0);
  let brands = 8;
  if (size === 1) {
    size = Number(data.readBigUInt64BE(8));
    brands = 16;
  } else if (size === 0) {
    size = data.length;
  }
  const end = Math.min(size, data.length);
  // The major brand, then the minor version, which is no brand, then the compatible brands.
  for (let offset = brands; offset + 4 <= end; offset += 4) {
    if (offset !== brands + 4 && data.toString('latin1', offset, offset + 4) === 'avis') return true;
  }
  return false;
}

// Whether an image has more than one frame. sharp reads only the first unless told otherwise, so
// the compressed file would be a still image; an animation is left as it is.
async function isAnimated(sharp, data, format) {
  if (format === 'png') return isAnimatedPng(data);
  if (format === 'avif' && isAvifSequence(data)) return true;
  const { pages = 1 } = await sharp(data).metadata();
  return pages > 1;
}

// The bytes and mode of the regular file at file, read through one descriptor, with no check of
// the path before it: null when the path is now a link (O_NOFOLLOW refuses it) or not a regular
// file. O_NONBLOCK keeps a FIFO swapped in from blocking the open.
function readFound(file) {
  let descriptor;
  try {
    // eslint-disable-next-line security/detect-non-literal-fs-filename -- an image the walk found under root
    descriptor = openSync(file, constants.O_RDONLY | constants.O_NOFOLLOW | constants.O_NONBLOCK);
  } catch (error) {
    if (error.code === 'ELOOP') return null;
    throw error;
  }
  try {
    const opened = fstatSync(descriptor);
    if (!opened.isFile()) return null;
    // eslint-disable-next-line security/detect-non-literal-fs-filename -- the descriptor opened above, not a path
    return { data: readFileSync(descriptor), mode: opened.mode & 0o7777 };
  } finally {
    closeSync(descriptor);
  }
}

// Put data at file by renaming a new file over it, so the path, and nothing it pointed to, changes.
function replace(file, data, mode) {
  const temporary = `${file}.compress-images-${randomBytes(6).toString('hex')}`;
  try {
    // eslint-disable-next-line security/detect-non-literal-fs-filename -- a new name beside an image the walk found
    writeFileSync(temporary, data, { flag: 'wx', mode: 0o600 });
    // eslint-disable-next-line security/detect-non-literal-fs-filename -- the file written just above
    chmodSync(temporary, mode);
    // eslint-disable-next-line security/detect-non-literal-fs-filename -- that file, over the image it replaces
    renameSync(temporary, file);
  } catch (error) {
    rmSync(temporary, { force: true });
    throw error;
  }
}

export async function compress({ sharp, root, label, ignore, imageQuality, pngQuality }) {
  const options = new Map([
    ['jpeg', { quality: imageQuality, progressive: false, chromaSubsampling: '4:4:4' }],
    ['png', { quality: pngQuality, compressionLevel: 9 }],
    ['webp', { quality: 85, smartSubsample: true }],
    ['avif', { quality: 75 }],
  ]);
  const compressed = [];
  let unchanged = 0;
  let unreadable = 0;
  let animated = 0;
  for (const relative of findImages(root, ignore)) {
    const file = path.join(root, relative);
    const name = path.posix.join(label, relative);
    const format = FORMATS.get(path.extname(relative).toLowerCase());
    let found;
    let result;
    try {
      found = readFound(file);
      if (found === null) continue;
      if (await isAnimated(sharp, found.data, format)) {
        console.log(escapeData(`Left ${name} as it is: an animation, which sharp would flatten to one frame`));
        animated += 1;
        continue;
      }
      // sharp drops the EXIF orientation from what it writes, so it rotates the pixels first.
      result = await sharp(found.data, { autoOrient: true }).toFormat(format, options.get(format)).toBuffer({ resolveWithObject: true });
    } catch (error) {
      console.log(`::warning file=${escapeProperty(name)}::${escapeData(`Could not compress ${name}: ${error.message}`)}`);
      unreadable += 1;
      continue;
    }
    const before = found.data.length;
    const after = result.info.size;
    const saved = before - after;
    if (saved >= MIN_BYTES && (saved / before) * 100 >= MIN_PERCENT) {
      replace(file, result.data, found.mode);
      compressed.push({ name, before, after });
      console.log(escapeData(`Compressed ${name}: ${formatSize(before)} -> ${formatSize(after)}`));
    } else {
      unchanged += 1;
    }
  }
  compressed.sort((a, b) => b.before - b.after - (a.before - a.after) || a.name.localeCompare(b.name));
  return { compressed, unchanged, unreadable, animated };
}

async function main() {
  const env = process.env;
  const sharp = createRequire(path.join(env.TOOLS, 'package.json'))('sharp');
  const label = path.posix.normalize(env.WORKING_DIRECTORY.split(path.sep).join('/'));
  const { compressed, unchanged, unreadable, animated } = await compress({
    sharp,
    root: path.resolve(env.WORKING_DIRECTORY),
    label: label === '.' ? '' : label,
    ignore: splitPatterns(env.IGNORE_PATHS ?? ''),
    imageQuality: Number(env.IMAGE_QUALITY),
    pngQuality: Number(env.PNG_QUALITY),
  });
  const delimiter = randomBytes(16).toString('hex');
  // eslint-disable-next-line security/detect-non-literal-fs-filename -- the step's output file, which the runner names
  appendFileSync(env.GITHUB_OUTPUT, `images_compressed=${compressed.length > 0}\n` + `compression_report<<${delimiter}\n${report(compressed, unchanged, unreadable, animated)}${delimiter}\n`);
  console.log(`${compressed.length} compressed, ${unchanged} unchanged, ${unreadable} unreadable, ${animated} animated`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  await main();
}
