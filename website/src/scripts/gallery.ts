import { fill } from '../lib/releases';

/** The gallery: a scroll-snapping track (touch swipes natively), buttons, arrow keys and a viewer. */
export function setUpGallery(): void {
  const gallery = document.querySelector<HTMLElement>('[data-gallery]');
  if (!gallery) return;
  const track = gallery.querySelector<HTMLElement>('[data-gallery-track]')!;
  const slides = [...gallery.querySelectorAll<HTMLElement>('[data-gallery-slide]')];
  const counter = gallery.querySelector<HTMLElement>('[data-gallery-counter]')!;
  const template = gallery.dataset.counter ?? '{current} / {total}';
  let current = 0;

  const show = (index: number) => {
    current = (index + slides.length) % slides.length;
    track.scrollTo({ left: slides[current].offsetLeft - (slides[0].offsetLeft || 0), behavior: 'smooth' });
  };
  const sync = () => {
    const left = track.scrollLeft;
    let nearest = 0;
    slides.forEach((slide, index) => {
      const distance = Math.abs(slide.offsetLeft - slides[0].offsetLeft - left);
      const best = Math.abs(slides[nearest].offsetLeft - slides[0].offsetLeft - left);
      if (distance < best) nearest = index;
    });
    current = nearest;
    counter.textContent = fill(template, { current: current + 1, total: slides.length });
  };
  let pending = 0;
  track.addEventListener('scroll', () => (pending ||= requestAnimationFrame(() => ((pending = 0), sync()))), { passive: true });
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

  // Viewer: a modal dialog with the visible picture of the chosen slide.
  const dialog = gallery.querySelector<HTMLDialogElement>('[data-lightbox]')!;
  const holder = dialog.querySelector<HTMLElement>('[data-lightbox-image]')!;
  const caption = dialog.querySelector<HTMLElement>('[data-lightbox-caption]')!;
  let open = 0;
  const visiblePicture = (slide: HTMLElement) =>
    [...slide.querySelectorAll<HTMLElement>('picture')].find((picture) => getComputedStyle(picture).display !== 'none');
  const render = (index: number) => {
    open = (index + slides.length) % slides.length;
    const picture = visiblePicture(slides[open]);
    holder.replaceChildren();
    if (picture) {
      const copy = picture.cloneNode(true) as HTMLElement;
      const image = copy.querySelector('img');
      if (image) {
        image.loading = 'eager';
        image.sizes = '100vw';
      }
      holder.append(copy);
    }
    caption.textContent = slides[open].querySelector('figcaption')?.textContent ?? '';
  };
  let returnFocus: HTMLElement | null = null;
  gallery.querySelectorAll<HTMLButtonElement>('[data-gallery-open]').forEach((button) => {
    button.addEventListener('click', () => {
      returnFocus = button;
      render(Number(button.dataset.galleryOpen));
      dialog.showModal();
    });
  });
  dialog.querySelector('[data-lightbox-close]')?.addEventListener('click', () => dialog.close());
  dialog.querySelector('[data-lightbox-previous]')?.addEventListener('click', () => render(open - 1));
  dialog.querySelector('[data-lightbox-next]')?.addEventListener('click', () => render(open + 1));
  dialog.addEventListener('keydown', (event) => {
    if (event.key === 'ArrowRight') render(open + 1);
    if (event.key === 'ArrowLeft') render(open - 1);
  });
  dialog.addEventListener('click', (event) => {
    if (event.target === dialog || event.target === holder) dialog.close();
  });
  dialog.addEventListener('close', () => {
    show(open);
    returnFocus?.focus();
  });
  // Swipe in the viewer.
  let startX = 0;
  dialog.addEventListener('touchstart', (event) => (startX = event.touches[0].clientX), { passive: true });
  dialog.addEventListener('touchend', (event) => {
    const delta = event.changedTouches[0].clientX - startX;
    if (Math.abs(delta) > 50) render(open + (delta < 0 ? 1 : -1));
  });
}
