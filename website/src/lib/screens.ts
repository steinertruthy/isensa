import type { ImageMetadata } from 'astro';

/** Screenshots captured from the app by UITests/ProductCaptureTests.swift (dark and light). */
const files = import.meta.glob<{ default: ImageMetadata }>('../assets/screens/*.png', { eager: true });

export function screen(name: string): ImageMetadata {
  const file = files[`../assets/screens/${name}.png`];
  if (!file) throw new Error(`Missing screenshot: ${name}`);
  return file.default;
}

export function hasScreen(name: string): boolean {
  return `../assets/screens/${name}.png` in files;
}
