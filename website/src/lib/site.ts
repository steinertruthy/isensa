/** Facts about the project that every page shares. */
export const repository = {
  owner: 'steinertruthy',
  name: 'isensa',
  url: 'https://github.com/steinertruthy/isensa',
  api: 'https://api.github.com/repos/steinertruthy/isensa',
} as const;

export const repoLinks = {
  releases: `${repository.url}/releases`,
  issues: `${repository.url}/issues`,
  pulls: `${repository.url}/pulls`,
  docs: `${repository.url}/tree/main/docs`,
  contributing: `${repository.url}/blob/main/CONTRIBUTING.md`,
  security: `${repository.url}/blob/main/SECURITY.md`,
  license: `${repository.url}/blob/main/LICENSE`,
} as const;
