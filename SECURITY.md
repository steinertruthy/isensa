# Security policy

iSensa installs, on request, a helper that runs as root to control the fans. Reports about it, or
about anything else that could harm a Mac or its data, are taken seriously.

## Reporting a vulnerability

Please **do not open a public issue**. Use GitHub's private vulnerability reporting instead:
**Security › Report a vulnerability** in this repository
(<https://github.com/steinertruthy/isensa/security/advisories/new>).

Include the iSensa version, the Mac model and macOS version, and the steps to reproduce. You will get
an answer as soon as possible; fixes are released with a note crediting the reporter, unless you prefer
otherwise.

## Supported versions

Only the latest release receives security fixes.

## What the helper does

- It accepts connections only from the iSensa build whose code-signature hash is pinned in its launchd job.
- It accepts only fan commands, validates them again and clamps speeds to the hardware's limits.
- It returns the fans to automatic control when the app's lease expires, when a reading fails, when it
  starts and when it stops.
- It is removed from **Settings › Fans** or with the commands in the README.
