/**
 * Opens any screenshot marked data-zoom in a full-screen viewer. The picture grows from where it sits
 * on the page and shrinks back there on close (a FLIP animation). Screens in the same data-zoom-group
 * can be browsed with the arrows, the keyboard or a swipe.
 */
const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
const easing = 'cubic-bezier(0.22, 1, 0.36, 1)';

function visiblePicture(trigger: HTMLElement): HTMLElement | null {
  return [...trigger.querySelectorAll<HTMLElement>('picture')].find((picture) => getComputedStyle(picture).display !== 'none') ?? null;
}

export function setUpZoom(): void {
  const found = document.querySelector<HTMLDialogElement>('[data-zoom-dialog]');
  if (!found) return;
  const dialog: HTMLDialogElement = found;
  const stage = dialog.querySelector<HTMLElement>('[data-zoom-stage]')!;
  const caption = dialog.querySelector<HTMLElement>('[data-zoom-caption]')!;
  const previous = dialog.querySelector<HTMLButtonElement>('[data-zoom-previous]')!;
  const next = dialog.querySelector<HTMLButtonElement>('[data-zoom-next]')!;
  let group: HTMLElement[] = [];
  let index = 0;
  let source: HTMLElement | null = null;
  let closing = false;

  const triggers = [...document.querySelectorAll<HTMLElement>('[data-zoom]')];
  for (const trigger of triggers) {
    if (trigger.tagName !== 'BUTTON') {
      trigger.setAttribute('role', 'button');
      trigger.tabIndex = 0;
    }
    trigger.addEventListener('click', () => open(trigger));
    trigger.addEventListener('keydown', (event) => {
      if (trigger.tagName !== 'BUTTON' && (event.key === 'Enter' || event.key === ' ')) {
        event.preventDefault();
        open(trigger);
      }
    });
  }

  /** The clone shown in the viewer, at full resolution. */
  function render(trigger: HTMLElement): HTMLImageElement | null {
    const picture = visiblePicture(trigger);
    stage.replaceChildren();
    if (!picture) return null;
    const copy = picture.cloneNode(true) as HTMLElement;
    // Without the page's classes: its theme rules would turn the copy into a full-width block and
    // push the image to the left.
    copy.removeAttribute('class');
    copy.querySelectorAll('source').forEach((element) => element.setAttribute('sizes', '100vw'));
    const image = copy.querySelector('img');
    if (image) {
      image.loading = 'eager';
      image.sizes = '100vw';
      image.removeAttribute('fetchpriority');
    }
    stage.append(copy);
    const alt = picture.querySelector('img')?.alt ?? '';
    caption.textContent = trigger.dataset.zoomCaption ?? alt;
    return image;
  }

  function animate(image: HTMLImageElement, from: DOMRect, reverse: boolean): Promise<void> {
    if (reducedMotion.matches || document.hidden) return Promise.resolve();
    const to = image.getBoundingClientRect();
    if (!to.width || !from.width) return Promise.resolve();
    const start = `translate(${from.left - to.left}px, ${from.top - to.top}px) scale(${from.width / to.width}, ${from.height / to.height})`;
    const frames = [{ transform: start, borderRadius: '14px' }, { transform: 'none', borderRadius: '' }];
    const animation = image.animate(reverse ? frames.reverse() : frames, {
      duration: reverse ? 380 : 560,
      easing,
      fill: reverse ? 'forwards' : 'none',
    });
    // Never wait longer than the animation: a paused (background) page would never finish it.
    const timeout = new Promise<void>((resolve) => setTimeout(resolve, (reverse ? 380 : 560) + 80));
    return Promise.race([animation.finished.then(() => undefined), timeout]);
  }

  function open(trigger: HTMLElement): void {
    source = trigger;
    const name = trigger.dataset.zoomGroup;
    group = name ? triggers.filter((item) => item.dataset.zoomGroup === name) : [trigger];
    index = Math.max(0, group.indexOf(trigger));
    previous.hidden = next.hidden = group.length < 2;
    const image = render(trigger);
    dialog.showModal();
    document.documentElement.style.overflow = 'hidden';
    requestAnimationFrame(() => dialog.setAttribute('data-shown', ''));
    if (!image) return;
    const from = (visiblePicture(trigger) ?? trigger).getBoundingClientRect();
    const run = () => void animate(image, from, false);
    if (image.complete) run();
    else image.addEventListener('load', run, { once: true });
  }

  function step(delta: number): void {
    if (group.length < 2) return;
    index = (index + delta + group.length) % group.length;
    source = group[index];
    const image = render(source);
    image?.animate(
      [
        { opacity: 0, transform: `translateX(${delta * 40}px)` },
        { opacity: 1, transform: 'none' },
      ],
      { duration: reducedMotion.matches ? 0 : 320, easing },
    );
    if (source.dataset.zoomGroup === 'gallery') source.closest('[data-gallery-slide]')?.scrollIntoView({ block: 'nearest', inline: 'center' });
  }

  async function close(): Promise<void> {
    if (closing || !dialog.open) return;
    closing = true;
    dialog.removeAttribute('data-shown');
    const image = stage.querySelector('img');
    const target = source ? (visiblePicture(source) ?? source) : null;
    const rect = target?.getBoundingClientRect();
    const onScreen = rect && rect.bottom > 0 && rect.top < window.innerHeight;
    if (image && rect && onScreen) await animate(image, rect, true);
    dialog.close();
    closing = false;
  }

  dialog.addEventListener('close', () => {
    document.documentElement.style.overflow = '';
    dialog.removeAttribute('data-shown');
    stage.replaceChildren();
    // After the browser's own focus restoration, return focus to the screenshot that was opened.
    const target = source;
    setTimeout(() => target?.focus({ preventScroll: true }), 0);
  });
  dialog.addEventListener('cancel', (event) => {
    event.preventDefault();
    void close();
  });
  dialog.querySelector('[data-zoom-close]')?.addEventListener('click', () => void close());
  previous.addEventListener('click', () => step(-1));
  next.addEventListener('click', () => step(1));
  dialog.addEventListener('keydown', (event) => {
    if (event.key === 'ArrowRight') step(1);
    if (event.key === 'ArrowLeft') step(-1);
  });
  // A click outside the picture closes the viewer.
  dialog.addEventListener('click', (event) => {
    if (!(event.target as HTMLElement).closest('img, button')) void close();
  });
  let startX = 0;
  dialog.addEventListener('touchstart', (event) => (startX = event.touches[0].clientX), { passive: true });
  dialog.addEventListener('touchend', (event) => {
    const delta = event.changedTouches[0].clientX - startX;
    if (Math.abs(delta) > 50) step(delta < 0 ? 1 : -1);
  });
}
