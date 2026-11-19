import type { Dictionary } from './en';

const de: Dictionary = {
  meta: {
    title: 'iSensa – Hardware-Monitor für macOS',
    description:
      'iSensa ist eine kostenlose Open-Source-App für den Mac, die CPU, GPU, Arbeitsspeicher, Temperaturen, Batterie, Lüfter und Speicher live anzeigt, erklärt, was die Werte bedeuten, und angibt, woher jede Zahl stammt.',
    ogAlt: 'Das iSensa-Fenster mit der Übersicht eines MacBook Pro und Live-Diagrammen für CPU und GPU.',
  },
  nav: {
    skip: 'Zum Inhalt springen',
    overview: 'Überblick',
    features: 'Funktionen',
    gallery: 'Galerie',
    download: 'Laden',
    openSource: 'Open Source',
    github: 'iSensa auf GitHub',
    menu: 'Menü',
    closeMenu: 'Menü schließen',
    language: 'Sprache',
    theme: 'Erscheinungsbild',
    themeSystem: 'Automatisch',
    themeLight: 'Hell',
    themeDark: 'Dunkel',
    home: 'iSensa-Startseite',
  },
  hero: {
    title: 'Kenne deinen Mac.\nBis ins Detail.',
    subtitle: 'Sieh, was dein Mac gerade tut, und versteh es in einfachen Worten. Eine kostenlose App, gemacht für macOS.',
    download: 'Für macOS laden',
    github: 'Auf GitHub ansehen',
    openSource: 'Kostenlos und Open Source unter der MIT-Lizenz.',
    eyebrow: 'Überwachung · Sensoren · Steuerung',
    howItWorks: 'So funktioniert’s',
    detected: 'Erkanntes System: {os}',
    platform: 'Für Macs mit Apple Silicon und macOS 14 oder neuer',
    screenAlt: 'Die Übersicht von iSensa auf einem MacBook Pro mit M3 Pro: der Zustand des Mac, Live-Diagramme für CPU und GPU und Kacheln für jede Komponente.',
  },
  overview: {
    eyebrow: 'Überblick',
    title: 'Ein Fenster für alles in deinem Mac.',
    text: 'Prozessor, Grafik, Arbeitsspeicher, Temperatur, Batterie, Lüfter, Speicher und Netzwerk: alles an einem Ort, einfach erklärt – im Fenster oder direkt in der Menüleiste.',
    pillars: {
      native: { title: 'Fühlt sich an wie ein Teil deines Mac', text: 'Sieht aus und verhält sich wie die Apps, die mit deinem Mac kommen – hell und dunkel.' },
      honest: { title: 'Einfache Worte statt Fachsprache', text: 'Zu jeder Zahl gibt es einen kurzen Satz, damit du weißt, wann etwas Aufmerksamkeit verdient.' },
      safe: { title: 'Leicht für deinen Mac', text: 'Es braucht sehr wenig Energie und wird langsamer, wenn du nicht hinsiehst.' },
    },
  },
  spectrum: {
    cpu: 'CPU',
    gpu: 'GPU',
    memory: 'Speicher',
    thermal: 'Temperatur',
    power: 'Leistung',
    battery: 'Batterie',
    fans: 'Lüfter',
    network: 'Netzwerk',
    storage: 'Festplatte',
  },
  status: {
    available: 'Verfügbar',
    experimental: 'Experimentell',
    varies: 'Je nach Mac',
  },
  features: {
    eyebrow: 'Funktionen',
    whyLabel: 'Warum das hilft',
    title: 'Alles, was dein Mac gerade tut – erklärt.',
    intro: 'Jeder Teil deines Mac hat seine eigene Farbe, und jede Zahl sagt dir, ob sie normal ist.',
    items: {
      realtime: {
        title: 'Live, ohne Rauschen',
        text: 'Sieh auf einen Blick, wie stark dein Mac gerade arbeitet und was ihn beschäftigt.',
        alt: 'Die Übersicht: ein zusammenfassender Satz, die Live-Kurve von CPU und GPU und Kacheln für CPU, GPU, Speicher, Temperatur, Leistung und Lüfter.',
        label: 'Echtzeit',
        why: 'Erkenne in Sekunden, was den Mac bremst – ohne die Aktivitätsanzeige zu öffnen.',
      },
      thermals: {
        title: 'Temperaturen, denen du trauen kannst',
        text: 'Wisse, wie warm Prozessor, Grafik, SSD und Batterie sind. iSensa benennt einen Sensor nur, wenn es genau weiß, was er misst. Was du siehst, hängt von deinem Mac ab.',
        alt: 'Der Bildschirm Temperaturen mit Werten für CPU, GPU, SSD und Batterie sowie einem Temperaturdiagramm.',
        label: 'Temperaturen',
        why: 'Wisse, ob der Mac nur warm oder wirklich heiß ist, bevor er die Leistung drosselt.',
      },
      battery: {
        title: 'Batteriezustand in klaren Worten',
        text: 'Ladestand, Zustand, wie viele Ladezyklen die Batterie hinter sich hat und wie viel Leistung dein Netzteil wirklich liefert.',
        alt: 'Der Bildschirm Batterie mit Ladestand, Zustand, Ladezyklen und Ladedetails.',
        label: 'Batterie',
        why: 'Verstehe, wie die Batterie altert und was das Netzteil wirklich liefert.',
      },
      fans: {
        title: 'Lüfter: beobachten oder selbst steuern',
        text: 'Sieh, wie schnell sich jeder Lüfter dreht. Auf Macs mit Lüftern kannst du auch leisere oder kühlere Einstellungen wählen. Das ist optional und experimentell und gibt die Steuerung an macOS zurück, wenn etwas nicht stimmt.',
        alt: 'Der Bildschirm Lüfter mit zwei automatisch gesteuerten Lüftern und der Option, das Hilfsprogramm zu installieren.',
        label: 'Lüfter',
        why: 'Halte den Mac bei Anrufen leise oder bei langen Renderings kühler – mit automatischen Schutzmechanismen.',
      },
      storage: {
        title: 'Finde heraus, was deine Festplatte füllt',
        text: 'Sieh, wie viel Platz belegt und frei ist, prüfe den Zustand der SSD und finde die größten Ordner, Dateien und Apps. In den Papierkorb kommt nur, was du auswählst.',
        alt: 'Der Bildschirm Speicher mit Belegung, löschbarem Platz, lokalen Snapshots und dem Zugang zu „Speicher freigeben“.',
        label: 'Speicher',
        why: 'Hol dir Gigabytes zurück, ohne raten zu müssen, welche Dateien sicher gelöscht werden können.',
      },
      history: {
        title: 'Ein Verlauf, der Muster erkennt',
        text: 'Blick zurück, von der letzten Stunde bis zum letzten Monat. iSensa zeigt, was sich gemeinsam verändert hat – etwa die Temperatur, die steigt, wenn der Mac viel arbeitet.',
        alt: 'Der Bildschirm Verlauf mit 24 Stunden Diagrammen für CPU, GPU, Speicherdruck, Temperatur und Lüfter.',
        label: 'Verlauf',
        why: 'Sieh nach, ob die Verlangsamung von gestern an Hitze, Speicher oder Laufwerk lag.',
      },
      settings: {
        title: 'Ganz nach deinem Geschmack',
        text: 'Wähle, was in der Menüleiste und in der Übersicht erscheint, lass dich warnen, wenn etwas zu lange zu hoch bleibt, und such dir Aussehen und Sprache aus.',
        alt: 'Das Einstellungsfenster im Bereich Allgemein.',
        label: 'Einstellungen',
        why: 'Behalte nur die Zahlen, die dir wichtig sind, dort, wo du sie willst.',
      },
      native: {
        title: 'Gemacht für den Mac',
        text: 'Hell und dunkel, zehn Sprachen, VoiceOver und Tastatur funktionieren, wie du es erwartest. Wenn du nicht hinsiehst, wird iSensa langsamer und schont die Batterie.',
        alt: 'Der Bildschirm Speicher mit Speicherdruck, Nutzung nach Art und einem Speicherdiagramm.',
        label: 'Nativ',
        why: 'Es fühlt sich wie ein Teil von macOS an und stört nicht bei der Arbeit.',
      },
    },
  },
  menubar: {
    eyebrow: 'Menüleiste',
    title: 'Dein Mac, direkt aus der Menüleiste',
    text: 'Behalte die wichtigen Zahlen neben der Uhr. Ein Klick zeigt alles andere, ohne ein Fenster zu öffnen.',
    points: [
      'Wähle, welche Zahlen in welcher Reihenfolge erscheinen – als Text oder kleine Diagramme.',
      'Wenig Platz? Stapele zwei Zahlen an einer Stelle.',
      'Ist nur die Menüleiste sichtbar, aktualisiert iSensa seltener und spart Energie.',
    ],
    statusAlt: 'iSensa in der Menüleiste mit CPU-Auslastung und -Temperatur.',
    popoverAlt: 'Das iSensa-Fenster mit Werten für CPU, GPU, Temperatur, Speicher, Batterie, Leistung, Lüfter und Netzwerk.',
  },
  gallery: {
    eyebrow: 'Galerie',
    title: 'Galerie',
    intro: 'Bildschirmfotos von iSensa auf einem MacBook Pro mit M3 Pro.',
    previous: 'Vorheriges Bildschirmfoto',
    next: 'Nächstes Bildschirmfoto',
    open: 'Bildschirmfoto vergrößern',
    close: 'Schließen',
    counter: '{current} von {total}',
    items: {
      overview: 'Übersicht',
      cpu: 'CPU',
      gpu: 'GPU',
      memory: 'Speicher',
      battery: 'Batterie',
      thermals: 'Temperaturen',
      sensors: 'Sensoren',
      fans: 'Lüfter',
      storage: 'Festplatte',
      history: 'Verlauf',
      popover: 'Menüleisten-Fenster',
      settings: 'Einstellungen',
    },
  },
  download: {
    eyebrow: 'Download',
    title: 'iSensa laden',
    intro: 'Veröffentlicht auf GitHub Releases, mit dem Quellcode jeder Version.',
    loading: 'Neueste Version auf GitHub wird abgefragt …',
    version: 'Version {version}',
    stable: 'Stabil',
    beta: 'Beta',
    released: 'Veröffentlicht',
    size: 'Größe',
    architecture: 'Architektur',
    checksum: 'SHA-256',
    copy: 'Kopieren',
    copied: 'Kopiert',
    notes: 'Versionshinweise',
    allReleases: 'Alle Versionen',
    source: 'Quellcode',
    buttonMac: 'Für macOS laden',
    buttonOther: 'Downloads für macOS ansehen',
    noReleaseTitle: 'Die erste öffentliche Version ist unterwegs',
    noReleaseText: 'Es gibt noch keine Version zum Herunterladen. Folge dem Repository, um zu erfahren, wann sie erscheint, oder kompiliere iSensa aus dem Quellcode.',
    errorText: 'GitHub ist gerade nicht erreichbar. Auf der Versionsseite findest du alle Versionen.',
    notMac: 'iSensa ist für macOS gemacht. Du kannst dir trotzdem die Versionen ansehen oder den Quellcode lesen.',
    archUnknown: 'Siehe Versionshinweise',
    installTitle: 'Installation',
    install: [
      'Öffne das geladene Festplattenimage.',
      'Ziehe iSensa in den Ordner „Programme“.',
      'Öffne iSensa. Die Versionen sind noch nicht mit einer Apple Developer ID signiert, daher fragt macOS beim ersten Mal nach: Öffne Systemeinstellungen › Datenschutz & Sicherheit und wähle „Dennoch öffnen“.',
    ],
    license: 'MIT-Lizenz',
  },
  requirements: {
    title: 'Systemvoraussetzungen',
    items: {
      macos: { label: 'System', value: 'macOS 14 Sonoma oder neuer' },
      chip: { label: 'Prozessor', value: 'Macs mit Apple Silicon. Getestet auf einem M3 Pro; auf anderen Macs erscheinen einige Sensoren eventuell ohne verständlichen Namen.' },
      intel: { label: 'Intel-Macs', value: 'Von den aktuellen Versionen nicht unterstützt.' },
      space: { label: 'Speicherplatz', value: 'Weniger als 20 MB' },
      permissions: {
        label: 'Berechtigungen',
        value: 'Keine, um die Werte deines Mac zu sehen. Optional: Mitteilungen für Warnungen, Ordnerzugriff, um herauszufinden, was die Festplatte füllt, und dein Passwort für die Lüftersteuerung.',
      },
    },
    limitations: 'Was iSensa anzeigen kann, hängt von deinem Mac ab. Die Lüftersteuerung ist experimentell und nur auf Macs mit Lüftern verfügbar. Manche Werte sind Schätzungen und als solche gekennzeichnet.',
  },
  openSource: {
    eyebrow: 'Open Source',
    title: 'Open Source – und ehrlich zu seinen Daten',
    text: 'iSensa ist kostenlos und Open Source. Jeder kann auf GitHub sehen, wie es funktioniert, Änderungen vorschlagen und helfen, es zu verbessern.',
    principles: {
      honest: { title: 'Nichts erfunden', text: 'Ein Sensor bekommt nur einen Namen, wenn iSensa sicher weiß, was er ist. Schätzungen sind als Schätzungen gekennzeichnet.' },
      local: { title: 'Nichts verlässt deinen Mac', text: 'Deine Messwerte und dein Verlauf bleiben auf deinem Mac. Online prüft iSensa nur, ob es eine neue Version gibt.' },
      safe: { title: 'Sorgfältig mit Hardware', text: 'Die Lüftersteuerung ist optional und gibt die Kontrolle sofort an macOS zurück, wenn etwas nicht stimmt.' },
    },
    links: {
      issues: 'Issues',
      pulls: 'Pull Requests',
      releases: 'Versionen',
      docs: 'Dokumentation',
      contributing: 'Leitfaden für Beiträge',
      security: 'Sicherheitsrichtlinie',
      license: 'Lizenz',
    },
  },
  footer: {
    tagline: 'Ein nativer Hardware-Monitor für macOS, ehrlich bei dem, was er misst.',
    product: 'Produkt',
    project: 'Projekt',
    legal: 'Rechtliches',
    terms: 'Nutzungsbedingungen',
    privacy: 'Datenschutzerklärung',
    latest: 'Neueste Version: {version}',
    noRelease: 'Noch keine öffentliche Version',
    openSource: 'Open Source unter der MIT-Lizenz.',
    trademark: 'Mac und macOS sind Marken der Apple Inc. iSensa steht in keiner Verbindung zu Apple.',
  },
  notFound: {
    title: 'Diese Seite gibt es nicht',
    text: 'Die Adresse ist vielleicht falsch geschrieben, oder die Seite wurde verschoben.',
    home: 'Zur Startseite',
  },
  legal: {
    draft: 'Entwurf zur rechtlichen Prüfung. Dieser Text beschreibt, wie das Projekt heute funktioniert, wurde aber noch nicht anwaltlich geprüft.',
    updated: 'Zuletzt aktualisiert: {date}',
    back: 'Zurück zur Startseite',
    terms: {
      title: 'Nutzungsbedingungen',
      description: 'Die Bedingungen für die Nutzung von iSensa und seiner Website.',
      sections: [
        {
          heading: 'Über iSensa',
          body: [
            'iSensa ist eine Open-Source-Anwendung, die die Hardware von Mac-Computern überwacht und diagnostiziert und auf kompatiblen Modellen die Lüfterdrehzahl steuern kann. Sie wird von unabhängigen Mitwirkenden entwickelt und unter github.com/steinertruthy/isensa veröffentlicht.',
          ],
        },
        {
          heading: 'Lizenz',
          body: [
            'Quellcode und veröffentlichte Versionen stehen unter der MIT-Lizenz. Sie erlaubt, die Software zu nutzen, zu kopieren, zu ändern, zusammenzuführen, zu veröffentlichen, zu verbreiten, unterzulizenzieren und Kopien zu verkaufen, sofern der Urheberrechts- und Genehmigungshinweis erhalten bleibt. Weichen diese Bedingungen und die Lizenz in Bezug auf die Software voneinander ab, gilt die Lizenz.',
          ],
        },
        {
          heading: 'Nutzung der Software',
          body: [
            'Du darfst iSensa privat oder beruflich nutzen. Du bist dafür verantwortlich, wie du es nutzt, einschließlich aller Änderungen an Hardware-Einstellungen und aller Dateien, die du mit der Analyse „Speicher freigeben“ in den Papierkorb legst.',
          ],
        },
        {
          heading: 'Überwachung und ihre Grenzen',
          body: [
            'Die Messwerte stammen aus Schnittstellen von macOS und der Mac-Hardware, von denen einige nicht dokumentiert sind. Verfügbarkeit und Genauigkeit hängen von Modell und macOS-Version ab und können sich nach Updates ändern oder wegfallen. iSensa kennzeichnet geschätzte und abgeleitete Werte, doch kein Messwert ist als zertifizierte Messung zu verstehen.',
          ],
        },
        {
          heading: 'Lüftersteuerung und privilegierte Komponenten',
          body: [
            'Die Lüftersteuerung ist experimentell. Sie erfordert ein Hilfsprogramm mit Administratorrechten, das du mit deinem Passwort autorisierst. Das Hilfsprogramm prüft jeden Befehl, hält die von der Hardware gemeldeten Drehzahlgrenzen ein und gibt die Lüfter an die automatische Steuerung zurück, wenn die App nicht mehr reagiert oder ein Messwert fehlschlägt. Dennoch wirkt sich ein geändertes Lüfterverhalten auf Temperaturen und Geräusche aus; die Nutzung erfolgt auf eigenes Risiko, und du kannst das Hilfsprogramm jederzeit entfernen.',
          ],
        },
        {
          heading: 'Keine Gewährleistung',
          body: [
            'Die Software wird „wie besehen“ bereitgestellt, ohne ausdrückliche oder stillschweigende Gewährleistung jeglicher Art, einschließlich der Gewährleistung der Marktgängigkeit, der Eignung für einen bestimmten Zweck und der Nichtverletzung von Rechten. Soweit das anwendbare Recht es zulässt, haften die Autoren und Mitwirkenden nicht für Ansprüche, Schäden oder sonstige Verbindlichkeiten, die aus der Software oder ihrer Nutzung entstehen. Manche Rechtsordnungen lassen solche Ausschlüsse nicht zu; dann gelten sie, soweit gesetzlich zulässig.',
          ],
        },
        {
          heading: 'Geistiges Eigentum',
          body: [
            'Der Name iSensa und sein Symbol kennzeichnen das Projekt. Beiträge werden unter der Lizenz des Projekts angenommen. Mac und macOS sind Marken der Apple Inc.; iSensa steht in keiner Verbindung zu Apple und wird von Apple weder unterstützt noch gesponsert.',
          ],
        },
        {
          heading: 'Änderungen dieser Bedingungen',
          body: [
            'Diese Bedingungen können sich mit dem Projekt weiterentwickeln. Änderungen werden auf dieser Seite veröffentlicht und im Verlauf des Repositorys festgehalten; das Datum der letzten Aktualisierung steht oben.',
          ],
        },
        {
          heading: 'Kontakt',
          body: ['Fragen zu diesen Bedingungen kannst du als Issue im GitHub-Repository stellen.'],
        },
      ],
    },
    privacy: {
      title: 'Datenschutzerklärung',
      description: 'Was die Website und die App iSensa mit Daten tun.',
      sections: [
        {
          heading: 'Kurz gesagt',
          body: [
            'Die App iSensa läuft vollständig auf deinem Mac. Ihre einzige Verbindung ist eine tägliche Prüfung auf GitHub, ob es eine neuere Version gibt; du kannst sie ausschalten. Diese Website setzt keine Cookies und keine Analysewerkzeuge ein. Deine Anfragen sehen die Dienste von GitHub, wie unten beschrieben.',
          ],
        },
        {
          heading: 'Die Website',
          body: [
            'Die Website wird von GitHub Pages gehostet. Um die neueste Version anzuzeigen, fragt dein Browser öffentliche Informationen bei der GitHub-API (api.github.com) ab. Downloads werden von GitHub ausgeliefert. Wie jeder Webserver erhält GitHub dabei deine IP-Adresse und Browserangaben und verarbeitet sie gemäß der GitHub-Datenschutzerklärung.',
            'Die Website merkt sich die gewählte Sprache und das Erscheinungsbild im lokalen Speicher deines Browsers. Diese Angaben bleiben auf deinem Gerät, werden nirgendwohin gesendet und lassen sich jederzeit in den Browsereinstellungen löschen.',
          ],
        },
        {
          heading: 'Die App',
          body: [
            'iSensa liest Hardware- und Systeminformationen deines Mac (etwa Auslastung, Temperaturen, Batterie und Speicher), um sie anzuzeigen. Verlauf und Einstellungen werden ausschließlich auf deinem Mac gespeichert, in ~/Library/Application Support/iSensa und in den Einstellungen der App; du kannst sie in den Einstellungen exportieren oder löschen.',
            'Einmal am Tag und immer, wenn du „Nach Updates suchen“ wählst, fragt die App bei der GitHub-API (api.github.com) die Liste der veröffentlichten Versionen ab. Die Anfrage enthält nur den Namen und die Versionsnummer der App; wie jeder Server erhält GitHub dabei auch deine IP-Adresse. Du kannst das unter Einstellungen › Über iSensa ausschalten.',
            'Die Analyse „Speicher freigeben“ liest Größen und Namen von Ordnern und Dateien, nie deren Inhalt, und nur, wenn du sie startest. macOS fragt eventuell nach dem Zugriff auf bestimmte Ordner; du kannst ihn verweigern oder in den Systemeinstellungen widerrufen.',
            'Mitteilungen erzeugt macOS lokal. Die App enthält keine Analyse-, Werbe- oder Absturzberichtsdienste.',
          ],
        },
        {
          heading: 'Speicherdauer und Sicherheit',
          body: [
            'Die App bewahrt den detaillierten Verlauf für kurze Zeit und Zusammenfassungen für die in den Einstellungen gewählte Anzahl von Tagen auf. Die Betreuer des Projekts speichern nichts, weil ihnen nichts übermittelt wird.',
          ],
        },
        {
          heading: 'Deine Rechte',
          body: [
            'Da das Projekt keine personenbezogenen Daten erhebt, liegt dort nichts vor, worauf du zugreifen, was du berichtigen oder löschen könntest. Für Daten, die GitHub verarbeitet, kannst du deine Rechte gegenüber GitHub gemäß dessen Datenschutzerklärung geltend machen. Je nach Wohnort können dir Gesetze wie die DSGVO weitere Rechte geben.',
          ],
        },
        {
          heading: 'Änderungen',
          body: ['Sollten Website oder App Daten künftig anders verarbeiten, wird diese Erklärung vor Veröffentlichung der Änderung aktualisiert.'],
        },
        {
          heading: 'Kontakt',
          body: ['Fragen zum Datenschutz kannst du als Issue im GitHub-Repository stellen.'],
        },
      ],
    },
  },
};

export default de;
