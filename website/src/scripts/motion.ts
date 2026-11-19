import { isMacOS } from '../lib/releases';

const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
const finePointer = window.matchMedia('(hover: hover) and (pointer: fine)');

/** Sections arrive as they scroll into view. */
function setUpReveal(): void {
  const items = document.querySelectorAll<HTMLElement>('[data-reveal]');
  if (!('IntersectionObserver' in window) || reducedMotion.matches) {
    items.forEach((item) => item.classList.add('is-visible'));
    return;
  }
  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        entry.target.classList.add('is-visible');
        observer.unobserve(entry.target);
      }
    },
    { rootMargin: '0px 0px -12% 0px' },
  );
  items.forEach((item) => observer.observe(item));
}

/** The hero window starts tilted back and stands up as the page scrolls; the pointer turns it slightly. */
function setUpHero(): void {
  const stage = document.querySelector<HTMLElement>('[data-hero-3d]');
  if (!stage || reducedMotion.matches) return;
  let frame = 0;
  const update = () => {
    frame = 0;
    const rect = stage.getBoundingClientRect();
    const progress = Math.min(1, Math.max(0, 1 - (rect.top - window.innerHeight * 0.15) / (window.innerHeight * 0.7)));
    stage.style.setProperty('--tilt', (24 * (1 - progress)).toFixed(2));
  };
  const schedule = () => (frame ||= requestAnimationFrame(update));
  update();
  window.addEventListener('scroll', schedule, { passive: true });
  window.addEventListener('resize', schedule);
  if (finePointer.matches) {
    const hero = stage.closest<HTMLElement>('.hero') ?? stage;
    hero.addEventListener('pointermove', (event) => {
      const x = event.clientX / window.innerWidth - 0.5;
      const y = event.clientY / window.innerHeight - 0.5;
      stage.style.setProperty('--ry', (x * 8).toFixed(2));
      stage.style.setProperty('--rx', (y * -5).toFixed(2));
    });
    hero.addEventListener('pointerleave', () => {
      stage.style.setProperty('--ry', '0');
      stage.style.setProperty('--rx', '0');
    });
  }
}

/** Screens and cards turn toward the pointer, like objects on a desk. */
function setUpTilt(): void {
  if (reducedMotion.matches || !finePointer.matches) return;
  document.querySelectorAll<HTMLElement>('[data-tilt]').forEach((card) => {
    const strength = card.classList.contains('pillar') ? 6 : 8;
    card.addEventListener('pointerenter', () => card.setAttribute('data-active', ''));
    card.addEventListener('pointermove', (event) => {
      const rect = card.getBoundingClientRect();
      const x = (event.clientX - rect.left) / rect.width - 0.5;
      const y = (event.clientY - rect.top) / rect.height - 0.5;
      card.style.setProperty('--ry', (x * strength).toFixed(2));
      card.style.setProperty('--rx', (y * -strength).toFixed(2));
      if (card.classList.contains('pillar')) {
        card.style.transform = `rotateX(${(y * -strength).toFixed(2)}deg) rotateY(${(x * strength).toFixed(2)}deg)`;
      }
    });
    card.addEventListener('pointerleave', () => {
      card.removeAttribute('data-active');
      card.style.setProperty('--ry', '0');
      card.style.setProperty('--rx', '0');
      card.style.transform = '';
    });
  });
}

/** Cards with data-spotlight light up under the pointer. */
function setUpSpotlight(): void {
  if (!finePointer.matches) return;
  document.querySelectorAll<HTMLElement>('[data-spotlight]').forEach((card) => {
    card.addEventListener('pointermove', (event) => {
      const rect = card.getBoundingClientRect();
      card.style.setProperty('--mx', `${event.clientX - rect.left}px`);
      card.style.setProperty('--my', `${event.clientY - rect.top}px`);
    });
  });
}

/** “Detected system: macOS”, as the reference page shows it. */
function setUpDetectedSystem(): void {
  const item = document.querySelector<HTMLElement>('[data-detected-os]');
  if (!item) return;
  const platform =
    (navigator as Navigator & { userAgentData?: { platform?: string } }).userAgentData?.platform ?? navigator.platform;
  const userAgent = navigator.userAgent;
  let name: string | null = null;
  if (isMacOS(platform, userAgent, navigator.maxTouchPoints)) name = 'macOS';
  else if (/iPhone|iPad|iPod/.test(userAgent) || (/Mac/.test(platform) && navigator.maxTouchPoints > 1)) name = 'iOS / iPadOS';
  else if (/Win/i.test(platform) || /Windows/.test(userAgent)) name = 'Windows';
  else if (/Android/.test(userAgent)) name = 'Android';
  else if (/Linux/i.test(platform)) name = 'Linux';
  if (!name) return;
  item.textContent = (item.dataset.template ?? '{os}').replace('{os}', name);
  item.hidden = false;
}

export function setUpMotion(): void {
  setUpReveal();
  setUpHero();
  setUpTilt();
  setUpSpotlight();
  setUpDetectedSystem();
}
