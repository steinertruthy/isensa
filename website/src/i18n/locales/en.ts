/**
 * English is the reference dictionary: every other language must have exactly the same keys
 * (enforced by the type below and by tests/i18n.test.ts). `{name}` marks a value filled in at runtime.
 */
const en = {
  meta: {
    title: 'iSensa — Hardware monitor for macOS',
    description:
      'iSensa is a free, open-source Mac app that shows live CPU, GPU, memory, temperature, battery, fan and storage readings, explains what they mean and labels where each number comes from.',
    ogAlt: 'The iSensa window showing the Overview of a MacBook Pro, with live CPU and GPU graphs.',
  },
  nav: {
    skip: 'Skip to content',
    overview: 'Overview',
    features: 'Features',
    gallery: 'Gallery',
    download: 'Download',
    openSource: 'Open source',
    github: 'iSensa on GitHub',
    menu: 'Menu',
    closeMenu: 'Close menu',
    language: 'Language',
    theme: 'Appearance',
    themeSystem: 'Automatic',
    themeLight: 'Light',
    themeDark: 'Dark',
    home: 'iSensa home',
  },
  hero: {
    title: 'Know your Mac.\nIn every detail.',
    subtitle:
      'See what your Mac is doing and understand it in plain words. A free app, made for macOS.',
    download: 'Download for macOS',
    github: 'View on GitHub',
    openSource: 'Free and open source, under the MIT License.',
    eyebrow: 'Monitoring · Sensors · Control',
    howItWorks: 'See how it works',
    detected: 'Detected system: {os}',
    platform: 'For Macs with Apple silicon and macOS 14 or later',
    screenAlt: 'iSensa’s Overview on a MacBook Pro with M3 Pro: a summary of the Mac’s state, live CPU and GPU graphs and tiles for every component.',
  },
  overview: {
    eyebrow: 'Overview',
    title: 'One window for everything inside your Mac.',
    text: 'Processor, graphics, memory, temperature, battery, fans, storage and network: everything in one place, explained simply, in a window or right from the menu bar.',
    pillars: {
      native: { title: 'Feels like part of your Mac', text: 'It looks and behaves like the apps that came with your Mac, in light and dark.' },
      honest: { title: 'Plain words, not jargon', text: 'Every number comes with a short sentence, so you know when something deserves attention.' },
      safe: { title: 'Light on your Mac', text: 'It uses very little energy and slows down when you are not looking at it.' },
    },
  },
  spectrum: {
    cpu: 'CPU',
    gpu: 'GPU',
    memory: 'Memory',
    thermal: 'Temperature',
    power: 'Power',
    battery: 'Battery',
    fans: 'Fans',
    network: 'Network',
    storage: 'Storage',
  },
  status: {
    available: 'Available',
    experimental: 'Experimental',
    varies: 'Depends on the Mac',
  },
  features: {
    eyebrow: 'Features',
    whyLabel: 'Why it helps',
    title: 'Everything your Mac is doing, explained.',
    intro: 'Each part of your Mac keeps its own color, and every number tells you whether it is normal.',
    items: {
      realtime: {
        title: 'Live, without the noise',
        text: 'See at a glance how hard your Mac is working right now, and what is keeping it busy.',
        alt: 'The Overview: a summary sentence, live CPU and GPU waveform, and tiles for CPU, GPU, memory, temperature, power and fans.',
        label: 'Real time',
        why: 'Spot what is slowing the Mac down in seconds, without opening Activity Monitor.',
      },
      thermals: {
        title: 'Temperatures you can trust',
        text: 'Know how warm the processor, graphics, SSD and battery are. iSensa only names a sensor when it knows exactly what it measures. What you see depends on your Mac.',
        alt: 'The Temperatures screen with CPU, GPU, SSD and battery readings and a temperature chart.',
        label: 'Temperatures',
        why: 'Know whether the Mac is just warm or really hot before it starts throttling.',
      },
      battery: {
        title: 'Battery health, in plain words',
        text: 'Charge, health, how many cycles the battery has been through, and how much power your charger really delivers.',
        alt: 'The Battery screen with charge level, health, cycle count and charging details.',
        label: 'Battery',
        why: 'Understand how the battery is ageing and what the charger is really delivering.',
      },
      fans: {
        title: 'Fans: watch them, or take the wheel',
        text: 'See how fast each fan spins. On Macs with fans you can also choose quieter or cooler settings. It is optional and experimental, and hands control back to macOS if anything looks wrong.',
        alt: 'The Fans screen with two fans spinning under automatic control and the option to install the fan helper.',
        label: 'Fans',
        why: 'Keep a quiet Mac during calls, or cooler during long renders, with automatic safeguards.',
      },
      storage: {
        title: 'Find out what fills your disk',
        text: 'See how much space is used and free, check your SSD’s health, and find the biggest folders, files and apps. Only what you choose goes to the Trash.',
        alt: 'The Storage screen with disk usage, purgeable space, local snapshots and the Free Up Space entry.',
        label: 'Storage',
        why: 'Get gigabytes back without guessing which files are safe to remove.',
      },
      history: {
        title: 'History that finds patterns',
        text: 'Look back over the last hour or the last month. iSensa points out what changed together, like the temperature rising when the Mac works hard.',
        alt: 'The History screen with 24 hours of CPU, GPU, memory pressure, temperature and fan charts.',
        label: 'History',
        why: 'See whether yesterday’s slowdown was heat, memory or the disk.',
      },
      settings: {
        title: 'Make it yours',
        text: 'Choose what appears in the menu bar and on the overview, get an alert when something stays too high for too long, and pick the look and language.',
        alt: 'The Settings window on the General pane.',
        label: 'Settings',
        why: 'Keep only the numbers you care about, where you want them.',
      },
      native: {
        title: 'Made for the Mac',
        text: 'Light and dark, ten languages, VoiceOver and the keyboard all work as you expect. When you are not looking, iSensa slows down to save battery.',
        alt: 'The Memory screen with memory pressure, usage by type and a memory chart.',
        label: 'Native',
        why: 'It feels like part of macOS and stays out of the way of your work.',
      },
    },
  },
  menubar: {
    eyebrow: 'Menu bar',
    title: 'Your Mac, from the menu bar',
    text: 'Keep the numbers you care about next to the clock. One click shows everything else, without opening a window.',
    points: [
      'Choose which numbers to show and in what order, as text or tiny graphs.',
      'Short on space? Stack two numbers in one spot.',
      'When only the menu bar is visible, iSensa updates less often to save energy.',
    ],
    statusAlt: 'iSensa in the menu bar showing CPU usage and temperature.',
    popoverAlt: 'The iSensa popover with CPU, GPU, temperature, memory, battery, power, fan and network readings.',
  },
  gallery: {
    eyebrow: 'Gallery',
    title: 'Gallery',
    intro: 'Screens captured from iSensa running on a MacBook Pro with M3 Pro.',
    previous: 'Previous screenshot',
    next: 'Next screenshot',
    open: 'Enlarge screenshot',
    close: 'Close',
    counter: '{current} of {total}',
    items: {
      overview: 'Overview',
      cpu: 'CPU',
      gpu: 'GPU',
      memory: 'Memory',
      battery: 'Battery',
      thermals: 'Temperatures',
      sensors: 'Sensors',
      fans: 'Fans',
      storage: 'Storage',
      history: 'History',
      popover: 'Menu bar popover',
      settings: 'Settings',
    },
  },
  download: {
    eyebrow: 'Download',
    title: 'Download iSensa',
    intro: 'Published on GitHub Releases, with the source code for every version.',
    loading: 'Checking the latest release on GitHub…',
    version: 'Version {version}',
    stable: 'Stable',
    beta: 'Beta',
    released: 'Released',
    size: 'Size',
    architecture: 'Architecture',
    checksum: 'SHA-256',
    copy: 'Copy',
    copied: 'Copied',
    notes: 'Release notes',
    allReleases: 'All releases',
    source: 'Source code',
    buttonMac: 'Download for macOS',
    buttonOther: 'See downloads for macOS',
    noReleaseTitle: 'The first public release is on its way',
    noReleaseText: 'There is no downloadable version yet. Follow the repository to know when it arrives, or build iSensa from the source code.',
    errorText: 'GitHub could not be reached just now. The releases page has every version.',
    notMac: 'iSensa is made for macOS. You can still browse its releases or read its source code.',
    archUnknown: 'See the release notes',
    installTitle: 'Installing',
    install: [
      'Open the downloaded disk image.',
      'Drag iSensa to the Applications folder.',
      'Open iSensa. Builds are not yet signed with an Apple Developer ID, so the first time macOS asks for confirmation: open System Settings › Privacy & Security and choose Open Anyway.',
    ],
    license: 'MIT License',
  },
  requirements: {
    title: 'Requirements',
    items: {
      macos: { label: 'System', value: 'macOS 14 Sonoma or later' },
      chip: { label: 'Processor', value: 'Macs with Apple silicon. Tested on an M3 Pro; on other Macs a few sensors may appear without a friendly name.' },
      intel: { label: 'Intel Macs', value: 'Not supported by current builds.' },
      space: { label: 'Disk space', value: 'Less than 20 MB' },
      permissions: {
        label: 'Permissions',
        value: 'None to see your Mac’s readings. Optional: notifications for alerts, access to folders to find what fills your disk, and your password to turn on fan control.',
      },
    },
    limitations: 'What iSensa can show depends on your Mac. Fan control is experimental and only on Macs with fans. Some values are estimates, and they are marked as such.',
  },
  openSource: {
    eyebrow: 'Open source',
    title: 'Open source, and honest about its data',
    text: 'iSensa is free and open source. Anyone can see how it works, suggest changes and help make it better on GitHub.',
    principles: {
      honest: { title: 'Nothing made up', text: 'A sensor gets a name only when iSensa is sure what it is. Estimates are marked as estimates.' },
      local: { title: 'Nothing leaves your Mac', text: 'Your readings and history stay on your Mac. Online, iSensa only checks whether a new version exists.' },
      safe: { title: 'Careful with hardware', text: 'Fan control is optional and gives control back to macOS the moment anything looks wrong.' },
    },
    links: {
      issues: 'Issues',
      pulls: 'Pull requests',
      releases: 'Releases',
      docs: 'Documentation',
      contributing: 'Contributing guide',
      security: 'Security policy',
      license: 'License',
    },
  },
  footer: {
    tagline: 'A native hardware monitor for macOS, honest about what it measures.',
    product: 'Product',
    project: 'Project',
    legal: 'Legal',
    terms: 'Terms of Use',
    privacy: 'Privacy Policy',
    latest: 'Latest release: {version}',
    noRelease: 'No public release yet',
    openSource: 'Open source under the MIT License.',
    trademark: 'Mac and macOS are trademarks of Apple Inc. iSensa is not affiliated with Apple.',
  },
  notFound: {
    title: 'This page does not exist',
    text: 'The address may be mistyped, or the page has moved.',
    home: 'Go to the home page',
  },
  legal: {
    draft: 'Draft for legal review. This text describes how the project works today but has not yet been reviewed by a lawyer.',
    updated: 'Last updated: {date}',
    back: 'Back to the home page',
    terms: {
      title: 'Terms of Use',
      description: 'The conditions for using iSensa and its website.',
      sections: [
        {
          heading: 'About iSensa',
          body: [
            'iSensa is an open-source application that monitors and diagnoses the hardware of Mac computers and, on compatible models, can control fan speeds. It is developed by independent contributors and published at github.com/steinertruthy/isensa.',
          ],
        },
        {
          heading: 'License',
          body: [
            'The source code and the published builds are distributed under the MIT License. The license grants permission to use, copy, modify, merge, publish, distribute, sublicense and sell copies of the software, provided the copyright and permission notice are kept. Where these terms and the license differ about the software, the license prevails.',
          ],
        },
        {
          heading: 'Using the software',
          body: [
            'You may use iSensa for personal or professional purposes. You are responsible for how you use it, including any change you make to hardware settings and any file you choose to move to the Trash with the Free Up Space analysis.',
          ],
        },
        {
          heading: 'Monitoring and its limits',
          body: [
            'Readings come from interfaces provided by macOS and by the Mac’s hardware, some of them undocumented. Their availability and precision vary by model and macOS version, and they can change or stop working after updates. iSensa labels estimated and derived values, but no reading should be treated as a certified measurement.',
          ],
        },
        {
          heading: 'Fan control and privileged components',
          body: [
            'Fan control is experimental. It requires installing a helper that runs with administrator privileges, which you authorize with your password. The helper validates every command, enforces the speed limits reported by the hardware and returns the fans to automatic control when the app stops responding or a reading fails. Even so, changing fan behavior affects temperatures and noise; use it at your own risk and uninstall the helper whenever you wish.',
          ],
        },
        {
          heading: 'No warranty',
          body: [
            'The software is provided “as is”, without warranty of any kind, express or implied, including warranties of merchantability, fitness for a particular purpose and non-infringement. To the extent permitted by applicable law, the authors and contributors are not liable for any claim, damage or other liability arising from the software or its use. Some jurisdictions do not allow these exclusions; in that case they apply as far as the law allows.',
          ],
        },
        {
          heading: 'Intellectual property',
          body: [
            'The name iSensa and its icon identify the project. Contributions are accepted under the project’s license. Mac and macOS are trademarks of Apple Inc.; iSensa is not affiliated with, endorsed or sponsored by Apple.',
          ],
        },
        {
          heading: 'Changes to these terms',
          body: [
            'These terms may change as the project evolves. Changes are published on this page and recorded in the repository’s history, with the date of the last update shown above.',
          ],
        },
        {
          heading: 'Contact',
          body: ['Questions about these terms can be raised as an issue in the GitHub repository.'],
        },
      ],
    },
    privacy: {
      title: 'Privacy Policy',
      description: 'What the iSensa website and app do with data.',
      sections: [
        {
          heading: 'Summary',
          body: [
            'The iSensa app runs entirely on your Mac. Its only connection is a daily check on GitHub for a newer version, which you can turn off. This website sets no cookies and uses no analytics. The services that do see your requests are GitHub’s, described below.',
          ],
        },
        {
          heading: 'The website',
          body: [
            'The site is hosted by GitHub Pages. To show the latest version, your browser requests public information from GitHub’s API (api.github.com). Downloads are served by GitHub. Like any web server, GitHub receives your IP address and browser details with these requests and handles them under the GitHub General Privacy Statement.',
            'The site remembers your chosen language and appearance in your browser’s local storage. This stays on your device, is not sent anywhere and can be cleared at any time from your browser’s settings.',
          ],
        },
        {
          heading: 'The app',
          body: [
            'iSensa reads hardware and system information (such as usage, temperatures, battery and storage) on your Mac to display it. Its history and preferences are stored only on your Mac, in ~/Library/Application Support/iSensa and in the app’s preferences, and you can export or delete them in Settings.',
            'Once a day, and whenever you choose Check for Updates, the app asks GitHub’s API (api.github.com) for the list of published versions. The request carries only the app’s name and version number; like any server, GitHub also receives your IP address. You can turn this off in Settings › About iSensa.',
            'The Free Up Space analysis reads folder and file sizes and names, never their contents, and only when you start it. macOS may ask for permission to access some folders; you can refuse or revoke it in System Settings.',
            'Notifications are created locally by macOS. The app contains no analytics, advertising or crash reporting services.',
          ],
        },
        {
          heading: 'Retention and security',
          body: [
            'The app keeps detailed history for a short period and summaries for up to the number of days chosen in Settings. Nothing is stored by the project’s maintainers, because nothing is sent to them.',
          ],
        },
        {
          heading: 'Your rights',
          body: [
            'Because the project does not collect personal data, there is nothing held by it to access, correct or delete. For data processed by GitHub, you can exercise your rights with GitHub under its privacy statement. Depending on where you live, laws such as the GDPR or Brazil’s LGPD may grant you further rights.',
          ],
        },
        {
          heading: 'Changes',
          body: ['If the website or the app starts handling data differently, this policy will be updated before that change is published.'],
        },
        {
          heading: 'Contact',
          body: ['Questions about privacy can be raised as an issue in the GitHub repository.'],
        },
      ],
    },
  },
};

type Widen<T> = T extends string ? string : T extends readonly (infer U)[] ? Widen<U>[] : { [K in keyof T]: Widen<T[K]> };
export type Dictionary = Widen<typeof en>;
export default en satisfies Dictionary;
