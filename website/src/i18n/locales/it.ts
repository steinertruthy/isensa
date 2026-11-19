import type { Dictionary } from './en';

const it: Dictionary = {
  meta: {
    title: 'iSensa — Monitor hardware per macOS',
    description:
      'iSensa è un’app per Mac gratuita e open source che mostra in tempo reale CPU, GPU, memoria, temperature, batteria, ventole e archiviazione, spiega cosa significano i valori e indica da dove proviene ogni numero.',
    ogAlt: 'La finestra di iSensa con la Panoramica di un MacBook Pro e i grafici in tempo reale di CPU e GPU.',
  },
  nav: {
    skip: 'Vai al contenuto',
    overview: 'Panoramica',
    features: 'Funzioni',
    gallery: 'Galleria',
    download: 'Scarica',
    openSource: 'Open source',
    github: 'iSensa su GitHub',
    menu: 'Menu',
    closeMenu: 'Chiudi menu',
    language: 'Lingua',
    theme: 'Aspetto',
    themeSystem: 'Automatico',
    themeLight: 'Chiaro',
    themeDark: 'Scuro',
    home: 'Home di iSensa',
  },
  hero: {
    title: 'Conosci il tuo Mac.\nIn ogni dettaglio.',
    subtitle: 'Guarda cosa sta facendo il tuo Mac e capiscilo con parole semplici. Un’app gratuita, pensata per macOS.',
    download: 'Scarica per macOS',
    github: 'Vedi su GitHub',
    openSource: 'Gratuito e open source, con licenza MIT.',
    eyebrow: 'Monitoraggio · Sensori · Controllo',
    howItWorks: 'Scopri come funziona',
    detected: 'Sistema rilevato: {os}',
    platform: 'Per Mac con Apple silicon e macOS 14 o successivo',
    screenAlt: 'La Panoramica di iSensa su un MacBook Pro con M3 Pro: lo stato del Mac, i grafici in tempo reale di CPU e GPU e un riquadro per ogni componente.',
  },
  overview: {
    eyebrow: 'Panoramica',
    title: 'Una finestra su tutto ciò che c’è nel tuo Mac.',
    text: 'Processore, scheda grafica, memoria, temperatura, batteria, ventole, archiviazione e rete: tutto in un unico posto, spiegato in modo semplice, in una finestra o direttamente dalla barra dei menu.',
    pillars: {
      native: { title: 'Sembra parte del tuo Mac', text: 'Ha l’aspetto e il comportamento delle app incluse nel tuo Mac, in chiaro e in scuro.' },
      honest: { title: 'Parole semplici, niente gergo', text: 'Ogni numero ha una breve frase, così sai quando qualcosa merita attenzione.' },
      safe: { title: 'Leggero per il tuo Mac', text: 'Consuma pochissima energia e rallenta quando non lo stai guardando.' },
    },
  },
  spectrum: {
    cpu: 'CPU',
    gpu: 'GPU',
    memory: 'Memoria',
    thermal: 'Temperatura',
    power: 'Energia',
    battery: 'Batteria',
    fans: 'Ventole',
    network: 'Rete',
    storage: 'Archiviazione',
  },
  status: {
    available: 'Disponibile',
    experimental: 'Sperimentale',
    varies: 'Dipende dal Mac',
  },
  features: {
    eyebrow: 'Funzioni',
    whyLabel: 'Perché è utile',
    title: 'Tutto quello che fa il tuo Mac, spiegato.',
    intro: 'Ogni parte del tuo Mac ha il suo colore, e ogni numero ti dice se è normale.',
    items: {
      realtime: {
        title: 'In tempo reale, senza rumore',
        text: 'Vedi a colpo d’occhio quanto sta lavorando il tuo Mac in questo momento e cosa lo tiene occupato.',
        alt: 'La Panoramica: una frase di sintesi, l’onda in tempo reale di CPU e GPU e i riquadri di CPU, GPU, memoria, temperatura, energia e ventole.',
        label: 'Tempo reale',
        why: 'Scopri in pochi secondi cosa rallenta il Mac, senza aprire Monitoraggio Attività.',
      },
      thermals: {
        title: 'Temperature di cui fidarsi',
        text: 'Scopri quanto sono caldi processore, scheda grafica, SSD e batteria. iSensa dà un nome a un sensore solo quando sa esattamente cosa misura. Ciò che vedi dipende dal tuo Mac.',
        alt: 'La schermata Temperature con le letture di CPU, GPU, SSD e batteria e un grafico della temperatura.',
        label: 'Temperature',
        why: 'Sappi se il Mac è solo tiepido o davvero caldo prima che riduca le prestazioni.',
      },
      battery: {
        title: 'La salute della batteria, in parole semplici',
        text: 'Carica, salute, quanti cicli ha già fatto la batteria e quanta energia fornisce davvero il tuo alimentatore.',
        alt: 'La schermata Batteria con livello di carica, salute, cicli e dettagli di ricarica.',
        label: 'Batteria',
        why: 'Capisci come invecchia la batteria e cosa fornisce davvero l’alimentatore.',
      },
      fans: {
        title: 'Ventole: tienile d’occhio o prendi il comando',
        text: 'Guarda la velocità di ogni ventola. Sui Mac con ventole puoi anche scegliere impostazioni più silenziose o più fresche. È facoltativo e sperimentale, e restituisce il controllo a macOS se qualcosa non va.',
        alt: 'La schermata Ventole con due ventole in controllo automatico e l’opzione per installare l’assistente.',
        label: 'Ventole',
        why: 'Mantieni il Mac silenzioso durante le chiamate, o più fresco nei rendering lunghi, con protezioni automatiche.',
      },
      storage: {
        title: 'Scopri cosa riempie il disco',
        text: 'Vedi quanto spazio è occupato e libero, controlla la salute dell’SSD e trova le cartelle, i file e le app più grandi. Nel Cestino finisce solo ciò che scegli tu.',
        alt: 'La schermata Archiviazione con uso del disco, spazio eliminabile, istantanee locali e l’accesso a Libera spazio.',
        label: 'Archiviazione',
        why: 'Recupera gigabyte senza indovinare quali file si possono eliminare in sicurezza.',
      },
      history: {
        title: 'Una cronologia che trova le tendenze',
        text: 'Guarda indietro, dall’ultima ora all’ultimo mese. iSensa segnala ciò che è cambiato insieme, come la temperatura che sale quando il Mac lavora sodo.',
        alt: 'La schermata Cronologia con 24 ore di grafici di CPU, GPU, pressione della memoria, temperatura e ventole.',
        label: 'Cronologia',
        why: 'Verifica se il rallentamento di ieri dipendeva dal calore, dalla memoria o dal disco.',
      },
      settings: {
        title: 'A modo tuo',
        text: 'Scegli cosa compare nella barra dei menu e nella panoramica, ricevi un avviso quando qualcosa resta troppo alto troppo a lungo e scegli aspetto e lingua.',
        alt: 'La finestra Impostazioni sul pannello Generali.',
        label: 'Impostazioni',
        why: 'Tieni solo i numeri che ti interessano, dove li vuoi.',
      },
      native: {
        title: 'Fatto per il Mac',
        text: 'Chiaro e scuro, dieci lingue, VoiceOver e tastiera funzionano come ti aspetti. Quando non lo guardi, iSensa rallenta per risparmiare batteria.',
        alt: 'La schermata Memoria con pressione della memoria, uso per tipo e un grafico della memoria.',
        label: 'Nativo',
        why: 'Sembra parte di macOS e non intralcia il tuo lavoro.',
      },
    },
  },
  menubar: {
    eyebrow: 'Barra dei menu',
    title: 'Il tuo Mac, dalla barra dei menu',
    text: 'Tieni i numeri che ti interessano accanto all’orologio. Un clic mostra tutto il resto, senza aprire finestre.',
    points: [
      'Scegli quali numeri mostrare e in che ordine, come testo o piccoli grafici.',
      'Poco spazio? Metti due numeri nello stesso punto.',
      'Quando è visibile solo la barra dei menu, iSensa si aggiorna meno spesso per risparmiare energia.',
    ],
    statusAlt: 'iSensa nella barra dei menu con utilizzo e temperatura della CPU.',
    popoverAlt: 'Il pannello di iSensa con letture di CPU, GPU, temperatura, memoria, batteria, energia, ventole e rete.',
  },
  gallery: {
    eyebrow: 'Galleria',
    title: 'Galleria',
    intro: 'Schermate acquisite da iSensa su un MacBook Pro con M3 Pro.',
    previous: 'Schermata precedente',
    next: 'Schermata successiva',
    open: 'Ingrandisci la schermata',
    close: 'Chiudi',
    counter: '{current} di {total}',
    items: {
      overview: 'Panoramica',
      cpu: 'CPU',
      gpu: 'GPU',
      memory: 'Memoria',
      battery: 'Batteria',
      thermals: 'Temperature',
      sensors: 'Sensori',
      fans: 'Ventole',
      storage: 'Archiviazione',
      history: 'Cronologia',
      popover: 'Pannello della barra dei menu',
      settings: 'Impostazioni',
    },
  },
  download: {
    eyebrow: 'Download',
    title: 'Scarica iSensa',
    intro: 'Pubblicato su GitHub Releases, con il codice sorgente di ogni versione.',
    loading: 'Ricerca dell’ultima versione su GitHub…',
    version: 'Versione {version}',
    stable: 'Stabile',
    beta: 'Beta',
    released: 'Pubblicata',
    size: 'Dimensioni',
    architecture: 'Architettura',
    checksum: 'SHA-256',
    copy: 'Copia',
    copied: 'Copiato',
    notes: 'Note di rilascio',
    allReleases: 'Tutte le versioni',
    source: 'Codice sorgente',
    buttonMac: 'Scarica per macOS',
    buttonOther: 'Vedi i download per macOS',
    noReleaseTitle: 'La prima versione pubblica è in arrivo',
    noReleaseText: 'Non c’è ancora una versione da scaricare. Segui il repository per sapere quando arriverà, oppure compila iSensa dal codice sorgente.',
    errorText: 'Al momento GitHub non è raggiungibile. La pagina delle versioni le elenca tutte.',
    notMac: 'iSensa è fatto per macOS. Puoi comunque consultare le versioni o leggere il codice sorgente.',
    archUnknown: 'Vedi le note di rilascio',
    installTitle: 'Installazione',
    install: [
      'Apri l’immagine disco scaricata.',
      'Trascina iSensa nella cartella Applicazioni.',
      'Apri iSensa. Le versioni non sono ancora firmate con un Developer ID di Apple, quindi la prima volta macOS chiede conferma: apri Impostazioni di Sistema › Privacy e sicurezza e scegli Apri comunque.',
    ],
    license: 'Licenza MIT',
  },
  requirements: {
    title: 'Requisiti',
    items: {
      macos: { label: 'Sistema', value: 'macOS 14 Sonoma o successivo' },
      chip: { label: 'Processore', value: 'Mac con Apple silicon. Provato su un M3 Pro; su altri Mac alcuni sensori potrebbero comparire senza un nome chiaro.' },
      intel: { label: 'Mac con Intel', value: 'Non supportati dalle versioni attuali.' },
      space: { label: 'Spazio su disco', value: 'Meno di 20 MB' },
      permissions: {
        label: 'Autorizzazioni',
        value: 'Nessuna per vedere le letture del Mac. Facoltative: notifiche per gli avvisi, accesso alle cartelle per scoprire cosa riempie il disco e la tua password per attivare il controllo delle ventole.',
      },
    },
    limitations: 'Ciò che iSensa può mostrare dipende dal tuo Mac. Il controllo delle ventole è sperimentale ed esiste solo sui Mac con ventole. Alcuni valori sono stime e sono indicati come tali.',
  },
  openSource: {
    eyebrow: 'Open source',
    title: 'Open source e onesto sui suoi dati',
    text: 'iSensa è gratuito e open source. Chiunque può vedere come funziona, proporre modifiche e aiutare a migliorarlo su GitHub.',
    principles: {
      honest: { title: 'Niente di inventato', text: 'Un sensore riceve un nome solo quando iSensa è sicuro di cosa sia. Le stime sono indicate come stime.' },
      local: { title: 'Nulla lascia il tuo Mac', text: 'Le tue letture e la tua cronologia restano sul tuo Mac. Online, iSensa controlla solo se esiste una nuova versione.' },
      safe: { title: 'Attento all’hardware', text: 'Il controllo delle ventole è facoltativo e restituisce il comando a macOS appena qualcosa non va.' },
    },
    links: {
      issues: 'Issue',
      pulls: 'Pull request',
      releases: 'Versioni',
      docs: 'Documentazione',
      contributing: 'Guida per contribuire',
      security: 'Politica di sicurezza',
      license: 'Licenza',
    },
  },
  footer: {
    tagline: 'Un monitor hardware nativo per macOS, onesto su ciò che misura.',
    product: 'Prodotto',
    project: 'Progetto',
    legal: 'Note legali',
    terms: 'Termini d’uso',
    privacy: 'Informativa sulla privacy',
    latest: 'Ultima versione: {version}',
    noRelease: 'Ancora nessuna versione pubblica',
    openSource: 'Open source con licenza MIT.',
    trademark: 'Mac e macOS sono marchi di Apple Inc. iSensa non è affiliato ad Apple.',
  },
  notFound: {
    title: 'Questa pagina non esiste',
    text: 'L’indirizzo potrebbe essere errato, oppure la pagina è stata spostata.',
    home: 'Vai alla home',
  },
  legal: {
    draft: 'Bozza da sottoporre a revisione legale. Questo testo descrive il funzionamento attuale del progetto, ma non è ancora stato esaminato da un avvocato.',
    updated: 'Ultimo aggiornamento: {date}',
    back: 'Torna alla home',
    terms: {
      title: 'Termini d’uso',
      description: 'Le condizioni per usare iSensa e il suo sito web.',
      sections: [
        {
          heading: 'Informazioni su iSensa',
          body: [
            'iSensa è un’applicazione open source che monitora e diagnostica l’hardware dei computer Mac e, sui modelli compatibili, può controllare la velocità delle ventole. È sviluppata da collaboratori indipendenti e pubblicata su github.com/steinertruthy/isensa.',
          ],
        },
        {
          heading: 'Licenza',
          body: [
            'Il codice sorgente e le versioni pubblicate sono distribuiti con licenza MIT. La licenza consente di usare, copiare, modificare, unire, pubblicare, distribuire, concedere in sublicenza e vendere copie del software, purché si mantenga l’avviso di copyright e di autorizzazione. Se questi termini e la licenza differiscono riguardo al software, prevale la licenza.',
          ],
        },
        {
          heading: 'Uso del software',
          body: [
            'Puoi usare iSensa per scopi personali o professionali. Sei responsabile di come lo usi, comprese le modifiche alle impostazioni dell’hardware e i file che scegli di spostare nel Cestino con l’analisi Libera spazio.',
          ],
        },
        {
          heading: 'Il monitoraggio e i suoi limiti',
          body: [
            'Le letture provengono da interfacce fornite da macOS e dall’hardware del Mac, alcune non documentate. Disponibilità e precisione variano in base al modello e alla versione di macOS, e possono cambiare o smettere di funzionare dopo un aggiornamento. iSensa segnala i valori stimati e derivati, ma nessuna lettura va considerata una misurazione certificata.',
          ],
        },
        {
          heading: 'Controllo delle ventole e componenti con privilegi',
          body: [
            'Il controllo delle ventole è sperimentale. Richiede di installare un assistente che funziona con privilegi di amministratore, autorizzato con la tua password. L’assistente verifica ogni comando, rispetta i limiti di velocità indicati dall’hardware e riporta le ventole al controllo automatico se l’app smette di rispondere o una lettura fallisce. Modificare il comportamento delle ventole influisce comunque su temperature e rumore; usalo a tuo rischio e disinstalla l’assistente quando vuoi.',
          ],
        },
        {
          heading: 'Nessuna garanzia',
          body: [
            'Il software è fornito «così com’è», senza garanzie di alcun tipo, esplicite o implicite, comprese le garanzie di commerciabilità, idoneità a uno scopo particolare e non violazione. Nei limiti consentiti dalla legge applicabile, gli autori e i collaboratori non sono responsabili di alcuna richiesta, danno o altra responsabilità derivante dal software o dal suo uso. Alcune giurisdizioni non ammettono queste esclusioni; in tal caso si applicano nella misura consentita dalla legge.',
          ],
        },
        {
          heading: 'Proprietà intellettuale',
          body: [
            'Il nome iSensa e la sua icona identificano il progetto. I contributi sono accettati con la licenza del progetto. Mac e macOS sono marchi di Apple Inc.; iSensa non è affiliato, approvato né sponsorizzato da Apple.',
          ],
        },
        {
          heading: 'Modifiche ai termini',
          body: [
            'Questi termini possono cambiare con l’evoluzione del progetto. Le modifiche vengono pubblicate in questa pagina e registrate nella cronologia del repository, con la data dell’ultimo aggiornamento indicata sopra.',
          ],
        },
        {
          heading: 'Contatti',
          body: ['Le domande su questi termini si possono porre aprendo una issue nel repository GitHub.'],
        },
      ],
    },
    privacy: {
      title: 'Informativa sulla privacy',
      description: 'Cosa fanno con i dati il sito e l’app iSensa.',
      sections: [
        {
          heading: 'In breve',
          body: [
            'L’app iSensa funziona interamente sul tuo Mac. La sua unica connessione è un controllo giornaliero su GitHub per una versione più recente, che puoi disattivare. Questo sito non usa cookie né strumenti di analisi. I servizi che vedono le tue richieste sono quelli di GitHub, descritti di seguito.',
          ],
        },
        {
          heading: 'Il sito web',
          body: [
            'Il sito è ospitato da GitHub Pages. Per mostrare l’ultima versione, il tuo browser richiede informazioni pubbliche all’API di GitHub (api.github.com). I download sono forniti da GitHub. Come qualsiasi server web, GitHub riceve con queste richieste il tuo indirizzo IP e i dati del browser e li tratta secondo la propria informativa sulla privacy.',
            'Il sito memorizza la lingua e l’aspetto che hai scelto nell’archivio locale del browser. Questi dati restano sul tuo dispositivo, non vengono inviati altrove e puoi cancellarli in qualsiasi momento dalle impostazioni del browser.',
          ],
        },
        {
          heading: 'L’app',
          body: [
            'iSensa legge informazioni sull’hardware e sul sistema del tuo Mac (come utilizzo, temperature, batteria e archiviazione) per mostrarle. La cronologia e le preferenze restano solo sul tuo Mac, in ~/Library/Application Support/iSensa e nelle preferenze dell’app, e puoi esportarle o eliminarle nelle Impostazioni.',
            'Una volta al giorno, e ogni volta che scegli Cerca aggiornamenti, l’app chiede all’API di GitHub (api.github.com) l’elenco delle versioni pubblicate. La richiesta contiene solo il nome e il numero di versione dell’app; come qualsiasi server, GitHub riceve anche il tuo indirizzo IP. Puoi disattivarlo in Impostazioni › Informazioni su iSensa.',
            'L’analisi Libera spazio legge dimensioni e nomi di cartelle e file, mai il loro contenuto, e solo quando la avvii. macOS può chiedere il permesso di accedere ad alcune cartelle; puoi negarlo o revocarlo nelle Impostazioni di Sistema.',
            'Le notifiche sono create localmente da macOS. L’app non contiene servizi di analisi, pubblicità o segnalazione degli arresti anomali.',
          ],
        },
        {
          heading: 'Conservazione e sicurezza',
          body: [
            'L’app conserva la cronologia dettagliata per un breve periodo e i riepiloghi per il numero di giorni scelto nelle Impostazioni. I responsabili del progetto non conservano nulla, perché nulla viene inviato loro.',
          ],
        },
        {
          heading: 'I tuoi diritti',
          body: [
            'Poiché il progetto non raccoglie dati personali, non possiede nulla a cui tu possa accedere o che tu possa correggere o cancellare. Per i dati trattati da GitHub puoi esercitare i tuoi diritti nei confronti di GitHub secondo la sua informativa. A seconda di dove vivi, leggi come il GDPR possono riconoscerti ulteriori diritti.',
          ],
        },
        {
          heading: 'Modifiche',
          body: ['Se il sito o l’app inizieranno a trattare i dati in modo diverso, questa informativa sarà aggiornata prima della pubblicazione della modifica.'],
        },
        {
          heading: 'Contatti',
          body: ['Le domande sulla privacy si possono porre aprendo una issue nel repository GitHub.'],
        },
      ],
    },
  },
};

export default it;
