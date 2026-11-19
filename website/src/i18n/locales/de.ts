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
    subtitle: 'Präzise Messwerte, klare Erklärungen und eine umsichtige Hardware-Steuerung – in einer nativen App für macOS.',
    download: 'Für macOS laden',
    github: 'Auf GitHub ansehen',
    openSource: 'Kostenlos und Open Source unter der MIT-Lizenz.',
    videoLabel: 'iSensa auf einem MacBook Pro: Übersicht, Temperaturen, Verlauf und CPU mit Live-Messwerten.',
    pause: 'Video anhalten',
    play: 'Video abspielen',
  },
  tour: {
    title: 'Eine Minute mit iSensa',
    text: 'Aufgenommen auf einem 14-Zoll-MacBook-Pro mit M3 Pro. Jeder Wert auf dem Bildschirm ist ein Live-Messwert dieses Mac; nichts wurde inszeniert oder nachträglich eingefügt.',
    play: 'Rundgang starten',
    label: 'Rundgang durch iSensa: Übersicht, CPU, GPU, Temperaturen, Batterie, Lüfter, Speicher, Verlauf, Einstellungen und das Menüleisten-Fenster.',
    unsupported: 'Dein Browser kann dieses Video nicht abspielen.',
    download: 'Video laden (MP4)',
  },
  status: {
    available: 'Verfügbar',
    experimental: 'Experimentell',
    varies: 'Je nach Mac',
  },
  features: {
    title: 'Alles, was dein Mac gerade tut – erklärt.',
    intro: 'Jede Komponente behält überall ihre Farbe, und zu jeder Zahl gibt es einen Satz, der sagt, ob sie normal ist.',
    items: {
      realtime: {
        title: 'Live, ohne Rauschen',
        text: 'CPU, GPU, Arbeitsspeicher, Leistung und Netzwerk werden jede Sekunde aktualisiert. Leistungs- und Effizienzkerne erscheinen getrennt, und der Arbeitsspeicher wird wie bei macOS nach dem Speicherdruck beurteilt, nicht danach, wie voll er aussieht.',
        alt: 'Die Übersicht: ein zusammenfassender Satz, die Live-Kurve von CPU und GPU und Kacheln für CPU, GPU, Speicher, Temperatur, Leistung und Lüfter.',
      },
      thermals: {
        title: 'Temperaturen, denen du trauen kannst',
        text: 'iSensa liest die Temperatursensoren des Mac und benennt einen Sensor erst, nachdem er auf diesem Modell überprüft wurde. Was sich nicht zuordnen lässt, behält seinen ursprünglichen Schlüssel statt eines geratenen Namens. Welche Sensoren es gibt, hängt vom Mac ab.',
        alt: 'Der Bildschirm Temperaturen mit Werten für CPU, GPU, SSD und Batterie sowie einem Temperaturdiagramm.',
      },
      battery: {
        title: 'Batteriezustand in klaren Worten',
        text: 'Ladestand, Zustand, Ladezyklen, Nenn- und Vollladekapazität, Spannung, Stromstärke, die Leistung des Netzteils und die von macOS gemeldete Restlaufzeit.',
        alt: 'Der Bildschirm Batterie mit Ladestand, Zustand, Ladezyklen und Ladedetails.',
      },
      fans: {
        title: 'Lüfter: im Blick behalten und bei Bedarf selbst steuern',
        text: 'Drehzahl und Bereich jedes Lüfters. Auf Macs mit Lüftern bietet eine experimentelle Steuerung feste Drehzahlen und Kurven. Dafür ist ein kleines Hilfsprogramm nötig, das mit deinem Administratorpasswort installiert wird. Es gibt die Lüfter an macOS zurück, sobald etwas nicht stimmt.',
        alt: 'Der Bildschirm Lüfter mit zwei automatisch gesteuerten Lüftern und der Option, das Hilfsprogramm zu installieren.',
      },
      storage: {
        title: 'Speicher, der erklärt, warum er voll ist',
        text: 'Belegter, löschbarer und freier Platz, Laufwerksgeschwindigkeit, SSD-Zustand direkt vom Laufwerk und eine Analyse „Speicher freigeben“, die die größten Ordner, Dateien und Apps findet und das, was du auswählst, in den Papierkorb legt.',
        alt: 'Der Bildschirm Speicher mit Belegung, löschbarem Platz, lokalen Snapshots und dem Zugang zu „Speicher freigeben“.',
      },
      history: {
        title: 'Ein Verlauf, der Muster erkennt',
        text: 'Dreißig Tage Messwerte, gespeichert auf deinem Mac – von der letzten Stunde bis zum letzten Monat. Vergleiche Zeiträume, exportiere als CSV oder JSON und lies kurze Hinweise dazu, was sich gemeinsam verändert hat.',
        alt: 'Der Bildschirm Verlauf mit 24 Stunden Diagrammen für CPU, GPU, Speicherdruck, Temperatur und Lüfter.',
      },
      settings: {
        title: 'Ganz nach deinem Geschmack',
        text: 'Wähle die Menüleisten-Anzeigen und ihre Reihenfolge, die Kacheln der Übersicht, Einheiten, Aktualisierungsrate, Warnungen mit Schwellen, die erst eine Weile anhalten müssen, Erscheinungsbild und Sprache.',
        alt: 'Das Einstellungsfenster im Bereich Allgemein.',
      },
      native: {
        title: 'Durch und durch nativ',
        text: 'Mit SwiftUI und AppKit für macOS 14 und neuer entwickelt, hell und dunkel, in zehn Sprachen, mit VoiceOver-Beschriftungen und Tastaturbedienung. Ist das Fenster verborgen, misst iSensa seltener, und im Ruhezustand des Mac pausiert es.',
        alt: 'Der Bildschirm Speicher mit Speicherdruck, Nutzung nach Art und einem Speicherdiagramm.',
      },
    },
  },
  menubar: {
    title: 'Dein Mac, direkt aus der Menüleiste',
    text: 'Behalte die wichtigen Zahlen neben der Uhr – als Text oder kleine Diagramme. Ein Klick öffnet das Gesamtbild; das Fenster bleibt geschlossen.',
    points: [
      'Wähle die Anzeigen, ihre Reihenfolge und ob sie ein Diagramm zeigen.',
      'Stapele zwei Anzeigen in einer Spalte, wenn die Menüleiste voll ist.',
      'Ist nur die Menüleiste sichtbar, aktualisiert iSensa seltener und spart so Energie.',
    ],
    statusAlt: 'iSensa in der Menüleiste mit CPU-Auslastung und -Temperatur.',
    popoverAlt: 'Das iSensa-Fenster mit Werten für CPU, GPU, Temperatur, Speicher, Batterie, Leistung, Lüfter und Netzwerk.',
  },
  gallery: {
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
      chip: { label: 'Prozessor', value: 'Apple Silicon. Geprüft auf einem M3 Pro; auf anderen Chips erscheinen manche Sensoren unter ihrem Rohnamen.' },
      intel: { label: 'Intel-Macs', value: 'Von den aktuellen Versionen nicht unterstützt.' },
      space: { label: 'Speicherplatz', value: 'Weniger als 20 MB' },
      permissions: {
        label: 'Berechtigungen',
        value: 'Keine für die Überwachung. Optional: Mitteilungen für Warnungen, Ordnerzugriff für die Analyse „Speicher freigeben“ und dein Administratorpasswort für das Lüfter-Hilfsprogramm.',
      },
    },
    limitations: 'Welche Sensoren und Steuerungen verfügbar sind, hängt vom Mac-Modell ab. Die Lüftersteuerung ist experimentell und nur auf Macs mit Lüftern vorhanden. Frequenzen und Leistung werden aus Systemzählern abgeleitet und entsprechend gekennzeichnet.',
  },
  openSource: {
    title: 'Open Source – und ehrlich zu seinen Daten',
    text: 'iSensa ist freie Software. Jeder Messwert, jede Regel und jedes Wort auf dem Bildschirm lässt sich auf GitHub lesen, hinterfragen und verbessern.',
    principles: {
      honest: { title: 'Keine erfundenen Namen', text: 'Ein Sensor erhält nur einen Namen, wenn er auf diesem Modell überprüft wurde. Geschätzte und abgeleitete Werte sagen das.' },
      local: { title: 'Nichts verlässt deinen Mac', text: 'Die App baut keine Netzwerkverbindungen auf. Der Verlauf bleibt in einer Datei auf deinem Mac.' },
      safe: { title: 'Sorgfältig mit Hardware', text: 'Die Lüftersteuerung wird doppelt geprüft, hat eigene Sicherheitsgrenzen und gibt die Lüfter bei jedem Fehler an macOS zurück.' },
    },
    explore: 'Auf GitHub erkunden',
    stats: { stars: 'Sterne', forks: 'Forks', issues: 'Offene Issues', release: 'Neueste Version', none: 'Noch keine' },
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
            'Die App iSensa läuft vollständig auf deinem Mac und baut keine Netzwerkverbindungen auf. Diese Website setzt keine Cookies und keine Analysewerkzeuge ein. Deine Anfragen sehen die Dienste von GitHub, wie unten beschrieben.',
          ],
        },
        {
          heading: 'Die Website',
          body: [
            'Die Website wird von GitHub Pages gehostet. Um die neueste Version und die Statistiken des Repositorys anzuzeigen, fragt dein Browser öffentliche Informationen bei der GitHub-API (api.github.com) ab. Downloads werden von GitHub ausgeliefert. Wie jeder Webserver erhält GitHub dabei deine IP-Adresse und Browserangaben und verarbeitet sie gemäß der GitHub-Datenschutzerklärung.',
            'Die Website merkt sich die gewählte Sprache und das Erscheinungsbild im lokalen Speicher deines Browsers. Diese Angaben bleiben auf deinem Gerät, werden nirgendwohin gesendet und lassen sich jederzeit in den Browsereinstellungen löschen.',
          ],
        },
        {
          heading: 'Die App',
          body: [
            'iSensa liest Hardware- und Systeminformationen deines Mac (etwa Auslastung, Temperaturen, Batterie und Speicher), um sie anzuzeigen. Verlauf und Einstellungen werden ausschließlich auf deinem Mac gespeichert, in ~/Library/Application Support/iSensa und in den Einstellungen der App; du kannst sie in den Einstellungen exportieren oder löschen.',
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
