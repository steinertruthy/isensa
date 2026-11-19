import type { Dictionary } from './en';

const fr: Dictionary = {
  meta: {
    title: 'iSensa — Moniteur matériel pour macOS',
    description:
      'iSensa est une app Mac gratuite et open source qui affiche en direct le processeur, la carte graphique, la mémoire, les températures, la batterie, les ventilateurs et le stockage, explique ce que signifient les valeurs et indique d’où vient chaque chiffre.',
    ogAlt: 'La fenêtre d’iSensa affichant la Vue d’ensemble d’un MacBook Pro, avec les graphiques CPU et GPU en direct.',
  },
  nav: {
    skip: 'Aller au contenu',
    overview: 'Aperçu',
    features: 'Fonctionnalités',
    gallery: 'Galerie',
    download: 'Télécharger',
    openSource: 'Open source',
    github: 'iSensa sur GitHub',
    menu: 'Menu',
    closeMenu: 'Fermer le menu',
    language: 'Langue',
    theme: 'Apparence',
    themeSystem: 'Automatique',
    themeLight: 'Claire',
    themeDark: 'Sombre',
    home: 'Accueil d’iSensa',
  },
  hero: {
    title: 'Connaissez votre Mac.\nDans le moindre détail.',
    subtitle: 'Voyez ce que fait votre Mac et comprenez-le avec des mots simples. Une app gratuite, conçue pour macOS.',
    download: 'Télécharger pour macOS',
    github: 'Voir sur GitHub',
    openSource: 'Gratuit et open source, sous licence MIT.',
    eyebrow: 'Surveillance · Capteurs · Contrôle',
    howItWorks: 'Voir comment ça marche',
    detected: 'Système détecté : {os}',
    platform: 'Pour les Mac avec Apple silicon et macOS 14 ou ultérieur',
    screenAlt: 'La Vue d’ensemble d’iSensa sur un MacBook Pro M3 Pro : l’état du Mac, les graphiques CPU et GPU en direct et une tuile par composant.',
  },
  overview: {
    eyebrow: 'Aperçu',
    title: 'Une fenêtre pour tout ce qui se passe dans votre Mac.',
    text: 'Processeur, carte graphique, mémoire, température, batterie, ventilateurs, stockage et réseau : tout au même endroit, expliqué simplement, dans une fenêtre ou depuis la barre des menus.',
    pillars: {
      native: { title: 'Comme une partie de votre Mac', text: 'Il ressemble aux apps fournies avec votre Mac et se comporte comme elles, en clair et en sombre.' },
      honest: { title: 'Des mots simples, pas de jargon', text: 'Chaque chiffre est accompagné d’une courte phrase, pour savoir quand quelque chose mérite votre attention.' },
      safe: { title: 'Léger pour votre Mac', text: 'Il consomme très peu d’énergie et ralentit quand vous ne le regardez pas.' },
    },
  },
  spectrum: {
    cpu: 'CPU',
    gpu: 'GPU',
    memory: 'Mémoire',
    thermal: 'Température',
    power: 'Énergie',
    battery: 'Batterie',
    fans: 'Ventilateurs',
    network: 'Réseau',
    storage: 'Stockage',
  },
  status: {
    available: 'Disponible',
    experimental: 'Expérimental',
    varies: 'Selon le Mac',
  },
  features: {
    eyebrow: 'Fonctionnalités',
    whyLabel: 'Pourquoi c’est utile',
    title: 'Tout ce que fait votre Mac, expliqué.',
    intro: 'Chaque partie de votre Mac a sa propre couleur, et chaque chiffre vous dit s’il est normal.',
    items: {
      realtime: {
        title: 'En direct, sans le bruit',
        text: 'Voyez d’un coup d’œil à quel point votre Mac travaille en ce moment, et ce qui l’occupe.',
        alt: 'La Vue d’ensemble : une phrase de synthèse, l’onde en direct du CPU et du GPU et des tuiles CPU, GPU, mémoire, température, énergie et ventilateurs.',
        label: 'Temps réel',
        why: 'Repérez en quelques secondes ce qui ralentit le Mac, sans ouvrir le Moniteur d’activité.',
      },
      thermals: {
        title: 'Des températures fiables',
        text: 'Connaissez la température du processeur, de la carte graphique, du SSD et de la batterie. iSensa ne nomme un capteur que s’il sait exactement ce qu’il mesure. Ce que vous voyez dépend de votre Mac.',
        alt: 'L’écran Températures avec les mesures du CPU, du GPU, du SSD et de la batterie et un graphique de température.',
        label: 'Températures',
        why: 'Sachez si le Mac est simplement tiède ou vraiment chaud avant qu’il ne bride ses performances.',
      },
      battery: {
        title: 'La santé de la batterie, en termes simples',
        text: 'Charge, santé, nombre de cycles déjà effectués et puissance réellement fournie par votre chargeur.',
        alt: 'L’écran Batterie avec le niveau de charge, la santé, le nombre de cycles et les détails de recharge.',
        label: 'Batterie',
        why: 'Comprenez comment la batterie vieillit et ce que fournit réellement le chargeur.',
      },
      fans: {
        title: 'Ventilateurs : observez-les ou prenez la main',
        text: 'Voyez la vitesse de chaque ventilateur. Sur les Mac équipés, vous pouvez aussi choisir des réglages plus silencieux ou plus frais. C’est facultatif et expérimental, et macOS reprend la main si quelque chose semble anormal.',
        alt: 'L’écran Ventilateurs avec deux ventilateurs en contrôle automatique et l’option d’installer l’assistant.',
        label: 'Ventilateurs',
        why: 'Gardez un Mac silencieux pendant les appels, ou plus frais pendant les longs rendus, avec des protections automatiques.',
      },
      storage: {
        title: 'Découvrez ce qui remplit votre disque',
        text: 'Voyez l’espace utilisé et libre, vérifiez la santé du SSD et trouvez les plus gros dossiers, fichiers et apps. Seul ce que vous choisissez part à la Corbeille.',
        alt: 'L’écran Stockage avec l’utilisation du disque, l’espace purgeable, les instantanés locaux et l’accès à Libérer de l’espace.',
        label: 'Stockage',
        why: 'Récupérez des gigaoctets sans deviner quels fichiers peuvent être supprimés sans risque.',
      },
      history: {
        title: 'Un historique qui révèle les tendances',
        text: 'Remontez de la dernière heure au dernier mois. iSensa signale ce qui a changé en même temps, comme la température qui monte quand le Mac travaille dur.',
        alt: 'L’écran Historique avec 24 heures de graphiques CPU, GPU, pression mémoire, température et ventilateurs.',
        label: 'Historique',
        why: 'Voyez si le ralentissement d’hier venait de la chaleur, de la mémoire ou du disque.',
      },
      settings: {
        title: 'À votre goût',
        text: 'Choisissez ce qui apparaît dans la barre des menus et la vue d’ensemble, recevez une alerte quand une valeur reste trop haute trop longtemps, et choisissez l’apparence et la langue.',
        alt: 'La fenêtre Réglages sur le panneau Général.',
        label: 'Réglages',
        why: 'Gardez seulement les chiffres qui comptent, là où vous les voulez.',
      },
      native: {
        title: 'Conçu pour le Mac',
        text: 'Mode clair et sombre, dix langues, VoiceOver et clavier fonctionnent comme vous l’attendez. Quand vous ne regardez pas, iSensa ralentit pour économiser la batterie.',
        alt: 'L’écran Mémoire avec la pression mémoire, l’utilisation par type et un graphique de mémoire.',
        label: 'Natif',
        why: 'Il s’intègre à macOS et ne gêne pas votre travail.',
      },
    },
  },
  menubar: {
    eyebrow: 'Barre des menus',
    title: 'Votre Mac, depuis la barre des menus',
    text: 'Gardez les chiffres qui comptent à côté de l’horloge. Un clic montre tout le reste, sans ouvrir de fenêtre.',
    points: [
      'Choisissez les chiffres à afficher et leur ordre, en texte ou en petits graphiques.',
      'Peu de place ? Regroupez deux chiffres au même endroit.',
      'Quand seule la barre des menus est visible, iSensa se met à jour moins souvent pour économiser l’énergie.',
    ],
    statusAlt: 'iSensa dans la barre des menus affichant l’utilisation et la température du CPU.',
    popoverAlt: 'Le panneau d’iSensa avec les mesures du CPU, du GPU, de la température, de la mémoire, de la batterie, de l’énergie, des ventilateurs et du réseau.',
  },
  gallery: {
    eyebrow: 'Galerie',
    title: 'Galerie',
    intro: 'Écrans capturés depuis iSensa sur un MacBook Pro avec M3 Pro.',
    previous: 'Capture précédente',
    next: 'Capture suivante',
    open: 'Agrandir la capture',
    close: 'Fermer',
    counter: '{current} sur {total}',
    items: {
      overview: 'Vue d’ensemble',
      cpu: 'CPU',
      gpu: 'GPU',
      memory: 'Mémoire',
      battery: 'Batterie',
      thermals: 'Températures',
      sensors: 'Capteurs',
      fans: 'Ventilateurs',
      storage: 'Stockage',
      history: 'Historique',
      popover: 'Panneau de la barre des menus',
      settings: 'Réglages',
    },
  },
  download: {
    eyebrow: 'Téléchargement',
    title: 'Télécharger iSensa',
    intro: 'Publié sur GitHub Releases, avec le code source de chaque version.',
    loading: 'Recherche de la dernière version sur GitHub…',
    version: 'Version {version}',
    stable: 'Stable',
    beta: 'Bêta',
    released: 'Publiée le',
    size: 'Taille',
    architecture: 'Architecture',
    checksum: 'SHA-256',
    copy: 'Copier',
    copied: 'Copié',
    notes: 'Notes de version',
    allReleases: 'Toutes les versions',
    source: 'Code source',
    buttonMac: 'Télécharger pour macOS',
    buttonOther: 'Voir les téléchargements pour macOS',
    noReleaseTitle: 'La première version publique arrive',
    noReleaseText: 'Aucune version n’est encore téléchargeable. Suivez le dépôt pour savoir quand elle sera disponible, ou compilez iSensa à partir du code source.',
    errorText: 'GitHub est injoignable pour le moment. La page des versions les répertorie toutes.',
    notMac: 'iSensa est conçu pour macOS. Vous pouvez tout de même consulter ses versions ou lire son code source.',
    archUnknown: 'Voir les notes de version',
    installTitle: 'Installation',
    install: [
      'Ouvrez l’image disque téléchargée.',
      'Faites glisser iSensa dans le dossier Applications.',
      'Ouvrez iSensa. Les versions ne sont pas encore signées avec un Developer ID d’Apple ; la première fois, macOS demande une confirmation : ouvrez Réglages Système › Confidentialité et sécurité et choisissez Ouvrir quand même.',
    ],
    license: 'Licence MIT',
  },
  requirements: {
    title: 'Configuration requise',
    items: {
      macos: { label: 'Système', value: 'macOS 14 Sonoma ou ultérieur' },
      chip: { label: 'Processeur', value: 'Mac avec Apple silicon. Testé sur un M3 Pro ; sur d’autres Mac, quelques capteurs peuvent apparaître sans nom explicite.' },
      intel: { label: 'Mac Intel', value: 'Non pris en charge par les versions actuelles.' },
      space: { label: 'Espace disque', value: 'Moins de 20 Mo' },
      permissions: {
        label: 'Autorisations',
        value: 'Aucune pour voir les mesures du Mac. Facultatives : les notifications pour les alertes, l’accès aux dossiers pour trouver ce qui remplit le disque et votre mot de passe pour activer le contrôle des ventilateurs.',
      },
    },
    limitations: 'Ce que iSensa peut afficher dépend de votre Mac. Le contrôle des ventilateurs est expérimental et n’existe que sur les Mac équipés de ventilateurs. Certaines valeurs sont des estimations, signalées comme telles.',
  },
  openSource: {
    eyebrow: 'Open source',
    title: 'Open source, et honnête sur ses données',
    text: 'iSensa est gratuit et open source. Tout le monde peut voir comment il fonctionne, proposer des changements et aider à l’améliorer sur GitHub.',
    principles: {
      honest: { title: 'Rien d’inventé', text: 'Un capteur n’est nommé que lorsque iSensa est sûr de ce qu’il est. Les estimations sont signalées comme telles.' },
      local: { title: 'Rien ne quitte votre Mac', text: 'iSensa n’utilise pas internet. Votre historique reste sur votre Mac.' },
      safe: { title: 'Prudent avec le matériel', text: 'Le contrôle des ventilateurs est facultatif et rend la main à macOS dès que quelque chose semble anormal.' },
    },
    explore: 'Explorer sur GitHub',
    stats: { stars: 'Étoiles', forks: 'Forks', issues: 'Issues ouvertes', release: 'Dernière version', none: 'Aucune pour l’instant' },
    links: {
      issues: 'Issues',
      pulls: 'Pull requests',
      releases: 'Versions',
      docs: 'Documentation',
      contributing: 'Guide de contribution',
      security: 'Politique de sécurité',
      license: 'Licence',
    },
  },
  footer: {
    tagline: 'Un moniteur matériel natif pour macOS, honnête sur ce qu’il mesure.',
    product: 'Produit',
    project: 'Projet',
    legal: 'Mentions légales',
    terms: 'Conditions d’utilisation',
    privacy: 'Politique de confidentialité',
    latest: 'Dernière version : {version}',
    noRelease: 'Pas encore de version publique',
    openSource: 'Open source sous licence MIT.',
    trademark: 'Mac et macOS sont des marques d’Apple Inc. iSensa n’est pas affilié à Apple.',
  },
  notFound: {
    title: 'Cette page n’existe pas',
    text: 'L’adresse est peut-être mal saisie, ou la page a été déplacée.',
    home: 'Aller à l’accueil',
  },
  legal: {
    draft: 'Brouillon à faire valider juridiquement. Ce texte décrit le fonctionnement actuel du projet mais n’a pas encore été relu par un avocat.',
    updated: 'Dernière mise à jour : {date}',
    back: 'Retour à l’accueil',
    terms: {
      title: 'Conditions d’utilisation',
      description: 'Les conditions d’utilisation d’iSensa et de son site web.',
      sections: [
        {
          heading: 'À propos d’iSensa',
          body: [
            'iSensa est une application open source qui surveille et diagnostique le matériel des ordinateurs Mac et peut, sur les modèles compatibles, piloter la vitesse des ventilateurs. Elle est développée par des contributeurs indépendants et publiée sur github.com/steinertruthy/isensa.',
          ],
        },
        {
          heading: 'Licence',
          body: [
            'Le code source et les versions publiées sont distribués sous licence MIT. Cette licence autorise l’utilisation, la copie, la modification, la fusion, la publication, la distribution, la sous-licence et la vente de copies du logiciel, à condition de conserver l’avis de copyright et d’autorisation. En cas de divergence entre ces conditions et la licence au sujet du logiciel, la licence prévaut.',
          ],
        },
        {
          heading: 'Utilisation du logiciel',
          body: [
            'Vous pouvez utiliser iSensa à des fins personnelles ou professionnelles. Vous êtes responsable de l’usage que vous en faites, y compris des modifications apportées aux réglages du matériel et des fichiers que vous choisissez de placer dans la Corbeille avec l’analyse Libérer de l’espace.',
          ],
        },
        {
          heading: 'La surveillance et ses limites',
          body: [
            'Les mesures proviennent d’interfaces fournies par macOS et par le matériel du Mac, dont certaines ne sont pas documentées. Leur disponibilité et leur précision varient selon le modèle et la version de macOS, et peuvent changer ou cesser de fonctionner après une mise à jour. iSensa signale les valeurs estimées et déduites, mais aucune mesure ne doit être considérée comme certifiée.',
          ],
        },
        {
          heading: 'Contrôle des ventilateurs et composants privilégiés',
          body: [
            'Le contrôle des ventilateurs est expérimental. Il nécessite l’installation d’un assistant qui s’exécute avec des privilèges d’administrateur, que vous autorisez avec votre mot de passe. L’assistant valide chaque commande, respecte les limites de vitesse indiquées par le matériel et rend les ventilateurs au contrôle automatique lorsque l’app ne répond plus ou qu’une mesure échoue. Modifier le comportement des ventilateurs influe toutefois sur les températures et le bruit ; utilisez-le à vos risques et désinstallez l’assistant quand vous le souhaitez.',
          ],
        },
        {
          heading: 'Absence de garantie',
          body: [
            'Le logiciel est fourni « en l’état », sans garantie d’aucune sorte, expresse ou implicite, y compris les garanties de qualité marchande, d’adéquation à un usage particulier et d’absence de contrefaçon. Dans la mesure permise par la loi applicable, les auteurs et contributeurs ne sont responsables d’aucune réclamation, d’aucun dommage ni d’aucune autre responsabilité découlant du logiciel ou de son utilisation. Certaines juridictions n’autorisent pas ces exclusions ; elles s’appliquent alors dans la mesure permise par la loi.',
          ],
        },
        {
          heading: 'Propriété intellectuelle',
          body: [
            'Le nom iSensa et son icône identifient le projet. Les contributions sont acceptées sous la licence du projet. Mac et macOS sont des marques d’Apple Inc. ; iSensa n’est ni affilié à Apple, ni approuvé, ni soutenu par elle.',
          ],
        },
        {
          heading: 'Modifications des présentes conditions',
          body: [
            'Ces conditions peuvent évoluer avec le projet. Les modifications sont publiées sur cette page et consignées dans l’historique du dépôt, la date de dernière mise à jour figurant ci-dessus.',
          ],
        },
        {
          heading: 'Contact',
          body: ['Les questions sur ces conditions peuvent être posées en ouvrant une issue sur le dépôt GitHub.'],
        },
      ],
    },
    privacy: {
      title: 'Politique de confidentialité',
      description: 'Ce que le site et l’app iSensa font des données.',
      sections: [
        {
          heading: 'En bref',
          body: [
            'L’app iSensa fonctionne entièrement sur votre Mac et n’établit aucune connexion réseau. Ce site n’utilise ni cookies ni outils de mesure d’audience. Les services qui voient vos requêtes sont ceux de GitHub, décrits ci-dessous.',
          ],
        },
        {
          heading: 'Le site web',
          body: [
            'Le site est hébergé par GitHub Pages. Pour afficher la dernière version et les statistiques du dépôt, votre navigateur demande des informations publiques à l’API de GitHub (api.github.com). Les téléchargements sont fournis par GitHub. Comme tout serveur web, GitHub reçoit votre adresse IP et des informations sur votre navigateur avec ces requêtes et les traite conformément à sa déclaration de confidentialité.',
            'Le site mémorise la langue et l’apparence choisies dans le stockage local de votre navigateur. Ces données restent sur votre appareil, ne sont envoyées nulle part et peuvent être effacées à tout moment dans les réglages du navigateur.',
          ],
        },
        {
          heading: 'L’app',
          body: [
            'iSensa lit des informations sur le matériel et le système de votre Mac (utilisation, températures, batterie, stockage…) pour les afficher. Son historique et ses préférences sont stockés uniquement sur votre Mac, dans ~/Library/Application Support/iSensa et dans les préférences de l’app ; vous pouvez les exporter ou les supprimer dans les Réglages.',
            'L’analyse Libérer de l’espace lit la taille et le nom des dossiers et fichiers, jamais leur contenu, et seulement lorsque vous la lancez. macOS peut demander l’autorisation d’accéder à certains dossiers ; vous pouvez la refuser ou la retirer dans les Réglages Système.',
            'Les notifications sont créées localement par macOS. L’app ne contient aucun service de mesure d’audience, de publicité ni de rapport de plantage.',
          ],
        },
        {
          heading: 'Conservation et sécurité',
          body: [
            'L’app conserve l’historique détaillé pendant une courte période et les résumés pendant le nombre de jours choisi dans les Réglages. Les responsables du projet ne conservent rien, puisque rien ne leur est envoyé.',
          ],
        },
        {
          heading: 'Vos droits',
          body: [
            'Le projet ne collectant aucune donnée personnelle, il ne détient rien que vous puissiez consulter, rectifier ou supprimer. Pour les données traitées par GitHub, vous pouvez exercer vos droits auprès de GitHub selon sa déclaration de confidentialité. Selon votre lieu de résidence, des lois comme le RGPD peuvent vous accorder des droits supplémentaires.',
          ],
        },
        {
          heading: 'Modifications',
          body: ['Si le site ou l’app venaient à traiter les données différemment, cette politique serait mise à jour avant la publication de ce changement.'],
        },
        {
          heading: 'Contact',
          body: ['Les questions sur la confidentialité peuvent être posées en ouvrant une issue sur le dépôt GitHub.'],
        },
      ],
    },
  },
};

export default fr;
