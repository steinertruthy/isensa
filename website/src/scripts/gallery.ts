import { fill } from '../lib/releases';

/** The gallery: a coverflow track (touch swipes natively), buttons and arrow keys. Slides open the page-wide viewer (zoom.ts). */
export function setUpGallery(): void {
  const gallery = document.querySelector<HTMLElement>('[data-gallery]');
  if (!gallery) return;
  const track = gallery.querySelector<HTMLElement>('[data-gallery-track]')!;
  const slides = [...gallery.querySelectorAll<HTMLElement>('[data-gallery-slide]')];
  const counter = gallery.querySelector<HTMLElement>('[data-gallery-counter]')!;
  const template = gallery.dataset.counter ?? '{current} / {total}';
  let current = 0;

  const centre = (slide: HTMLElement) => slide.offsetLeft + slide.offsetWidth / 2 - track.clientWidth / 2;
  const show = (index: number) => {
    current = (index + slides.length) % slides.length;
    track.scrollTo({ left: centre(slides[current]), behavior: 'smooth' });
  };
  // Coverflow: each slide turns by its distance from the centre of the track.
  const sync = () => {
    let nearest = 0;
    let best = Infinity;
    slides.forEach((slide, index) => {
      const offset = (centre(slide) - track.scrollLeft) / slide.offsetWidth;
      const distance = Math.abs(offset);
      if (distance < best) {
        best = distance;
        nearest = index;
      }
      const clamped = Math.max(-1.5, Math.min(1.5, offset));
      slide.style.setProperty('--d', clamped.toFixed(3));
      slide.style.setProperty('--a', Math.min(1, Math.abs(clamped)).toFixed(3));
    });
    current = nearest;
    counter.textContent = fill(template, { current: current + 1, total: slides.length });
  };
  let pending = 0;
  track.addEventListener('scroll', () => (pending ||= requestAnimationFrame(() => ((pending = 0), sync()))), { passive: true });
  window.addEventListener('resize', sync);
  sync();
  gallery.querySelector('[data-gallery-previous]')?.addEventListener('click', () => show(current - 1));
  gallery.querySelector('[data-gallery-next]')?.addEventListener('click', () => show(current + 1));
  track.addEventListener('keydown', (event) => {
    if (event.key === 'ArrowRight') {
      event.preventDefault();
      show(current + 1);
    } else if (event.key === 'ArrowLeft') {
      event.preventDefault();
      show(current - 1);
    }
  });
}
