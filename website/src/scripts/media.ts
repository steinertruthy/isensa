/** The hero loop and the tour: muted autoplay only when motion is welcome, paused off screen. */
const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');

function setUpHero(): void {
  const video = document.querySelector<HTMLVideoElement>('[data-hero-video]');
  const toggle = document.querySelector<HTMLButtonElement>('[data-video-toggle]');
  if (!video || !toggle) return;
  toggle.hidden = false;
  // Paused by the visitor: stays paused, even when scrolled back into view.
  let pausedByVisitor = reducedMotion.matches;
  let visible = false;

  const reflect = () => {
    const playing = !video.paused;
    toggle.toggleAttribute('data-playing', playing);
    toggle.setAttribute('aria-label', (playing ? toggle.dataset.pause : toggle.dataset.play) ?? '');
  };
  const play = () => {
    video.play().catch(() => reflect());
  };
  video.addEventListener('play', reflect);
  video.addEventListener('pause', reflect);
  toggle.addEventListener('click', () => {
    if (video.paused) {
      pausedByVisitor = false;
      play();
    } else {
      pausedByVisitor = true;
      video.pause();
    }
  });
  new IntersectionObserver(
    ([entry]) => {
      visible = entry.isIntersecting;
      if (visible && !pausedByVisitor) play();
      else if (!visible) video.pause();
    },
    { threshold: 0.2 },
  ).observe(video);
  reducedMotion.addEventListener('change', () => {
    if (reducedMotion.matches) {
      pausedByVisitor = true;
      video.pause();
    }
  });
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) video.pause();
    else if (visible && !pausedByVisitor) play();
  });
  reflect();

  // A very small drift of the window against the page while scrolling.
  const window_ = video.closest<HTMLElement>('[data-parallax]');
  if (window_ && !reducedMotion.matches) {
    let frame = 0;
    const move = () => {
      frame = 0;
      const offset = Math.min(window.scrollY, 800) * -0.04;
      window_.style.translate = `0 ${offset.toFixed(1)}px`;
    };
    window.addEventListener('scroll', () => (frame ||= requestAnimationFrame(move)), { passive: true });
  }
}

function setUpTour(): void {
  const video = document.querySelector<HTMLVideoElement>('[data-tour-video]');
  const button = document.querySelector<HTMLButtonElement>('[data-tour-play]');
  if (!video || !button) return;
  button.addEventListener('click', () => {
    button.hidden = true;
    video.play().catch(() => (button.hidden = false));
    video.focus();
  });
  video.addEventListener('play', () => (button.hidden = true));
  new IntersectionObserver(([entry]) => {
    if (!entry.isIntersecting && !video.paused) video.pause();
  }).observe(video);
}

export function setUpMedia(): void {
  setUpHero();
  setUpTour();
}
