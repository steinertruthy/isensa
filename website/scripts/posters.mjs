// Turns the poster frames edit.py extracts (JPEG) into WebP for the page: node scripts/posters.mjs <folder>
import sharp from 'sharp';
import { join } from 'node:path';

const folder = process.argv[2] ?? 'public/media';
for (const name of ['hero', 'tour']) {
  await sharp(join(folder, `${name}.jpg`)).webp({ quality: 80 }).toFile(join(folder, `${name}.webp`));
}
