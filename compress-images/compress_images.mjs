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
import { appendFileSync, chmodSync, closeSync, constants, fstatSync, lstatSync, openSync, readdirSync, readFileSync, renameSync, rmSync, writeFileSync } from 'node:fs';
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
      const char = value[index];
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
    for (const entry of readdirSync(path.join(root, relative), { withFileTypes: true })) {
      const child = relative ? `${relative}/${entry.name}` : entry.name;
      if (ignore.some(pattern => path.matchesGlob(child, pattern))) continue;
      if (entry.isDirectory()) {
        if (entry.name !== '.git') walk(child);
      } else if (entry.isFile() && FORMATS.has(path.extname(entry.name))) {
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

// A file name as a Markdown code span for a table cell: nothing in it renders as a link or as
// HTML, and an escaped pipe cannot end the cell.
export function codeSpan(name) {
  const text = name.replace(/[\r\n]+/g, ' ').replace(/\|/g, '\\|');
  const longest = Math.max(0, ...(text.match(/`+/g) ?? []).map(run => run.length));
  const fence = '`'.repeat(longest + 1);
  const pad = text.startsWith('`') || text.endsWith('`') ? ' ' : '';
  return `${fence}${pad}${text}${pad}${fence}`;
}

const percent = (before, after) => (((before - after) / before) * 100).toFixed(1);

export function report(compressed, unchanged, unreadable) {
  if (compressed.length === 0) return '';
  const before = compressed.reduce((sum, image) => sum + image.before, 0);
  const after = compressed.reduce((sum, image) => sum + image.after, 0);
  const lines = [
    'Images compressed by compress-images.',
    '',
    `Compression reduced images by **${percent(before, after)}%**, saving **${formatSize(before - after)}**.`,
    '',
    '| Filename | Before | After | Improvement |',
    '| -------- | ------ | ----- | ----------- |',
    ...compressed.map(image => `| ${codeSpan(image.name)} | ${formatSize(image.before)} | ${formatSize(image.after)} | ${percent(image.before, image.after)}% |`),
  ];
  if (unchanged > 0) {
    lines.push('', `${unchanged} ${unchanged === 1 ? 'image' : 'images'} did not require optimisation.`);
  }
  if (unreadable > 0) {
    lines.push('', `${unreadable} ${unreadable === 1 ? 'image' : 'images'} could not be read; see the step log.`);
  }
  return `${lines.join('\n')}\n`;
}

// The bytes of the regular file the walk found at file, read without following a link, with
// its mode; null when the path is now something else.
function readFound(file) {
  const seen = lstatSync(file);
  if (!seen.isFile()) return null;
  const descriptor = openSync(file, constants.O_RDONLY | constants.O_NOFOLLOW);
  try {
    const opened = fstatSync(descriptor);
    if (!opened.isFile() || opened.dev !== seen.dev || opened.ino !== seen.ino) return null;
    return { data: readFileSync(descriptor), mode: opened.mode & 0o7777 };
  } finally {
    closeSync(descriptor);
  }
}

// Put data at file by renaming a new file over it, so the path, and nothing it pointed to, changes.
function replace(file, data, mode) {
  const temporary = `${file}.compress-images-${randomBytes(6).toString('hex')}`;
  try {
    writeFileSync(temporary, data, { flag: 'wx', mode: 0o600 });
    chmodSync(temporary, mode);
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
  for (const relative of findImages(root, ignore)) {
    const file = path.join(root, relative);
    const name = path.posix.join(label, relative);
    const format = FORMATS.get(path.extname(relative));
    let found;
    let result;
    try {
      found = readFound(file);
      if (found === null) continue;
      result = await sharp(found.data).toFormat(format, options.get(format)).toBuffer({ resolveWithObject: true });
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
  return { compressed, unchanged, unreadable };
}

async function main() {
  const env = process.env;
  const sharp = createRequire(path.join(env.TOOLS, 'package.json'))('sharp');
  const label = path.posix.normalize(env.WORKING_DIRECTORY.split(path.sep).join('/'));
  const { compressed, unchanged, unreadable } = await compress({
    sharp,
    root: path.resolve(env.WORKING_DIRECTORY),
    label: label === '.' ? '' : label,
    ignore: splitPatterns(env.IGNORE_PATHS ?? ''),
    imageQuality: Number(env.IMAGE_QUALITY),
    pngQuality: Number(env.PNG_QUALITY),
  });
  const delimiter = randomBytes(16).toString('hex');
  appendFileSync(env.GITHUB_OUTPUT, `images_compressed=${compressed.length > 0}\n` + `compression_report<<${delimiter}\n${report(compressed, unchanged, unreadable)}${delimiter}\n`);
  console.log(`${compressed.length} compressed, ${unchanged} unchanged, ${unreadable} unreadable`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  await main();
}
