/** Features on wide screens: the step nearest the middle of the viewport picks the window shown. */
export function setUpStory(): void {
  const story = document.querySelector<HTMLElement>('[data-story]');
  if (!story) return;
  const steps = [...story.querySelectorAll<HTMLElement>('[data-step]')];
  const slides = [...story.querySelectorAll<HTMLElement>('[data-slide]')];
  const activate = (index: number) => {
    steps.forEach((step, i) => step.toggleAttribute('data-active', i === index));
    slides.forEach((slide, i) => slide.toggleAttribute('data-active', i === index));
  };
  activate(0);
  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) activate(Number((entry.target as HTMLElement).dataset.step));
      }
    },
    { rootMargin: '-45% 0px -45% 0px' },
  );
  steps.forEach((step) => observer.observe(step));
}
