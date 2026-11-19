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
      'Precise readings, clear explanations and careful hardware control, in a native app made for macOS.',
    download: 'Download for macOS',
    github: 'View on GitHub',
    openSource: 'Free and open source, under the MIT License.',
    eyebrow: 'Monitoring · Sensors · Control',
    howItWorks: 'See how it works',
    detected: 'Detected system: {os}',
    platform: 'macOS 14 or later on Apple silicon',
    screenAlt: 'iSensa’s Overview on a MacBook Pro with M3 Pro: a summary of the Mac’s state, live CPU and GPU graphs and tiles for every component.',
  },
  overview: {
    eyebrow: 'Overview',
    title: 'One window for everything inside your Mac.',
    text: 'iSensa reads the processor, graphics, memory, temperatures, battery, fans, storage and network, and turns each reading into something you can understand at a glance, in the window or from the menu bar.',
    pillars: {
      native: { title: 'Native and light', text: 'SwiftUI and AppKit, in light and dark, with adaptive sampling that slows down when nobody is looking.' },
      honest: { title: 'Honest about data', text: 'Sensors are named only when verified. Estimates are labelled. Nothing is invented to fill a screen.' },
      safe: { title: 'Careful with hardware', text: 'Fan control is optional and experimental, validated twice and handed back to macOS on any failure.' },
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
    intro: 'Each component keeps one color everywhere, and each number comes with a sentence that says whether it is normal.',
    items: {
      realtime: {
        title: 'Live, without the noise',
        text: 'CPU, GPU, memory, power and network refresh every second. Performance and efficiency cores are shown apart, and memory is judged by pressure, the way macOS judges it, not by how full it looks.',
        alt: 'The Overview: a summary sentence, live CPU and GPU waveform, and tiles for CPU, GPU, memory, temperature, power and fans.',
        label: 'Real time',
        why: 'Spot what is slowing the Mac down in seconds, without opening Activity Monitor.',
      },
      thermals: {
        title: 'Temperatures you can trust',
        text: 'iSensa reads the Mac’s thermal sensors and names a sensor only after it has been verified on that model. Anything it cannot identify keeps its raw key instead of a guessed name. Which sensors exist depends on the Mac.',
        alt: 'The Temperatures screen with CPU, GPU, SSD and battery readings and a temperature chart.',
        label: 'Temperatures',
        why: 'Know whether the Mac is just warm or really hot before it starts throttling.',
      },
      battery: {
        title: 'Battery health, in plain words',
        text: 'Charge, health, cycle count, design and full-charge capacity, voltage, current, the charger’s wattage and the time remaining reported by macOS.',
        alt: 'The Battery screen with charge level, health, cycle count and charging details.',
        label: 'Battery',
        why: 'Understand how the battery is ageing and what the charger is really delivering.',
      },
      fans: {
        title: 'Fans: watch them, and take control when you choose',
        text: 'RPM and range for each fan. On Macs with fans, an experimental control offers fixed speeds and curves. It needs a small helper installed with your administrator password, and it hands the fans back to macOS whenever anything looks wrong.',
        alt: 'The Fans screen with two fans spinning under automatic control and the option to install the fan helper.',
        label: 'Fans',
        why: 'Keep a quiet Mac during calls, or cooler during long renders, with automatic safeguards.',
      },
      storage: {
        title: 'Storage that tells you why it is full',
        text: 'Used, purgeable and free space, disk speed, SSD health from the drive itself, and a Free Up Space analysis that finds the largest folders, files and apps and moves what you choose to the Trash.',
        alt: 'The Storage screen with disk usage, purgeable space, local snapshots and the Free Up Space entry.',
        label: 'Storage',
        why: 'Get gigabytes back without guessing which files are safe to remove.',
      },
      history: {
        title: 'History that finds patterns',
        text: 'Thirty days of readings kept on your Mac, from the last hour to the last month. Compare periods, export CSV or JSON, and read short notes about what changed together.',
        alt: 'The History screen with 24 hours of CPU, GPU, memory pressure, temperature and fan charts.',
        label: 'History',
        why: 'See whether yesterday’s slowdown was heat, memory or the disk.',
      },
      settings: {
        title: 'Yours to arrange',
        text: 'Choose the menu bar indicators and their order, the overview tiles, units, refresh rate, alerts with thresholds that must last before you are notified, appearance and language.',
        alt: 'The Settings window on the General pane.',
        label: 'Settings',
        why: 'Keep only the numbers you care about, where you want them.',
      },
      native: {
        title: 'Native through and through',
        text: 'Built with SwiftUI and AppKit for macOS 14 and later, in light and dark, in ten languages, with VoiceOver labels and keyboard navigation. It samples less when its window is hidden and pauses while the Mac sleeps.',
        alt: 'The Memory screen with memory pressure, usage by type and a memory chart.',
        label: 'Native',
        why: 'It feels like part of macOS and stays out of the way of your work.',
      },
    },
  },
  menubar: {
    eyebrow: 'Menu bar',
    title: 'Your Mac, from the menu bar',
    text: 'Keep the numbers you care about next to the clock, as text or small graphs. A click opens the whole picture; the window stays closed.',
    points: [
      'Pick the indicators, their order and whether each shows a graph.',
      'Stack two indicators in one column when the menu bar is crowded.',
      'When only the menu bar is visible, iSensa refreshes less often to save energy.',
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
      chip: { label: 'Processor', value: 'Apple silicon. Validated on an M3 Pro; on other chips some sensors may appear under their raw names.' },
      intel: { label: 'Intel Macs', value: 'Not supported by current builds.' },
      space: { label: 'Disk space', value: 'Less than 20 MB' },
      permissions: {
        label: 'Permissions',
        value: 'None to monitor. Optional: notifications for alerts, folder access for the Free Up Space analysis, and your administrator password to install the fan helper.',
      },
    },
    limitations: 'Available sensors and controls depend on the Mac model. Fan control is experimental and only exists on Macs with fans. Frequencies and power are derived from system counters and labelled as such.',
  },
  openSource: {
    eyebrow: 'Open source',
    title: 'Open source, and honest about its data',
    text: 'iSensa is free software. Every reading, every rule and every word on screen can be read, questioned and improved on GitHub.',
    principles: {
      honest: { title: 'No invented names', text: 'A sensor is named only when verified on that model. Estimated and derived values say so.' },
      local: { title: 'Nothing leaves your Mac', text: 'The app makes no network connections. History stays in a file on your Mac.' },
      safe: { title: 'Careful with hardware', text: 'Fan control is validated twice, has its own safety limits and returns the fans to macOS on any failure.' },
    },
    explore: 'Explore on GitHub',
    stats: { stars: 'Stars', forks: 'Forks', issues: 'Open issues', release: 'Latest release', none: 'None yet' },
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
            'The iSensa app runs entirely on your Mac and makes no network connections. This website sets no cookies and uses no analytics. The services that do see your requests are GitHub’s, described below.',
          ],
        },
        {
          heading: 'The website',
          body: [
            'The site is hosted by GitHub Pages. To show the latest version and the repository’s statistics, your browser requests public information from GitHub’s API (api.github.com). Downloads are served by GitHub. Like any web server, GitHub receives your IP address and browser details with these requests and handles them under the GitHub General Privacy Statement.',
            'The site remembers your chosen language and appearance in your browser’s local storage. This stays on your device, is not sent anywhere and can be cleared at any time from your browser’s settings.',
          ],
        },
        {
          heading: 'The app',
          body: [
            'iSensa reads hardware and system information (such as usage, temperatures, battery and storage) on your Mac to display it. Its history and preferences are stored only on your Mac, in ~/Library/Application Support/iSensa and in the app’s preferences, and you can export or delete them in Settings.',
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
