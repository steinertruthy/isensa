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
    subtitle: 'Des mesures précises, des explications claires et un contrôle prudent du matériel, dans une app native conçue pour macOS.',
    download: 'Télécharger pour macOS',
    github: 'Voir sur GitHub',
    openSource: 'Gratuit et open source, sous licence MIT.',
    eyebrow: 'Surveillance · Capteurs · Contrôle',
    howItWorks: 'Voir comment ça marche',
    detected: 'Système détecté : {os}',
    platform: 'macOS 14 ou ultérieur sur Apple silicon',
    screenAlt: 'La Vue d’ensemble d’iSensa sur un MacBook Pro M3 Pro : l’état du Mac, les graphiques CPU et GPU en direct et une tuile par composant.',
  },
  overview: {
    eyebrow: 'Aperçu',
    title: 'Une fenêtre pour tout ce qui se passe dans votre Mac.',
    text: 'iSensa lit le processeur, la carte graphique, la mémoire, les températures, la batterie, les ventilateurs, le stockage et le réseau, et transforme chaque mesure en information compréhensible d’un coup d’œil, dans la fenêtre ou depuis la barre des menus.',
    pillars: {
      native: { title: 'Natif et léger', text: 'SwiftUI et AppKit, en clair et en sombre, avec des mesures qui ralentissent quand personne ne regarde.' },
      honest: { title: 'Honnête sur les données', text: 'Un capteur n’est nommé qu’une fois vérifié. Les estimations sont signalées. Rien n’est inventé pour remplir l’écran.' },
      safe: { title: 'Prudent avec le matériel', text: 'Le contrôle des ventilateurs est facultatif et expérimental, validé deux fois et rendu à macOS à la moindre défaillance.' },
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
    intro: 'Chaque composant garde une couleur partout, et chaque chiffre est accompagné d’une phrase qui dit s’il est normal.',
    items: {
      realtime: {
        title: 'En direct, sans le bruit',
        text: 'Le processeur, la carte graphique, la mémoire, l’énergie et le réseau se mettent à jour chaque seconde. Les cœurs de performance et d’efficacité sont présentés séparément, et la mémoire est jugée par sa pression, comme le fait macOS, et non par son taux de remplissage apparent.',
        alt: 'La Vue d’ensemble : une phrase de synthèse, l’onde en direct du CPU et du GPU et des tuiles CPU, GPU, mémoire, température, énergie et ventilateurs.',
        label: 'Temps réel',
        why: 'Repérez en quelques secondes ce qui ralentit le Mac, sans ouvrir le Moniteur d’activité.',
      },
      thermals: {
        title: 'Des températures fiables',
        text: 'iSensa lit les capteurs thermiques du Mac et ne nomme un capteur qu’après l’avoir vérifié sur ce modèle. Ce qu’il ne sait pas identifier garde sa clé d’origine plutôt qu’un nom deviné. Les capteurs disponibles dépendent du Mac.',
        alt: 'L’écran Températures avec les mesures du CPU, du GPU, du SSD et de la batterie et un graphique de température.',
        label: 'Températures',
        why: 'Sachez si le Mac est simplement tiède ou vraiment chaud avant qu’il ne bride ses performances.',
      },
      battery: {
        title: 'La santé de la batterie, en termes simples',
        text: 'Charge, santé, nombre de cycles, capacité nominale et capacité à pleine charge, tension, courant, puissance du chargeur et temps restant indiqué par macOS.',
        alt: 'L’écran Batterie avec le niveau de charge, la santé, le nombre de cycles et les détails de recharge.',
        label: 'Batterie',
        why: 'Comprenez comment la batterie vieillit et ce que fournit réellement le chargeur.',
      },
      fans: {
        title: 'Ventilateurs : observez-les, prenez la main si vous le souhaitez',
        text: 'Vitesse et plage de chaque ventilateur. Sur les Mac équipés de ventilateurs, un contrôle expérimental propose des vitesses fixes et des courbes. Il nécessite un petit assistant installé avec votre mot de passe administrateur et rend les ventilateurs à macOS dès que quelque chose semble anormal.',
        alt: 'L’écran Ventilateurs avec deux ventilateurs en contrôle automatique et l’option d’installer l’assistant.',
        label: 'Ventilateurs',
        why: 'Gardez un Mac silencieux pendant les appels, ou plus frais pendant les longs rendus, avec des protections automatiques.',
      },
      storage: {
        title: 'Un stockage qui explique pourquoi il est plein',
        text: 'Espace utilisé, purgeable et libre, vitesse du disque, santé du SSD fournie par le disque lui-même et une analyse Libérer de l’espace qui trouve les plus gros dossiers, fichiers et apps et place dans la Corbeille ce que vous choisissez.',
        alt: 'L’écran Stockage avec l’utilisation du disque, l’espace purgeable, les instantanés locaux et l’accès à Libérer de l’espace.',
        label: 'Stockage',
        why: 'Récupérez des gigaoctets sans deviner quels fichiers peuvent être supprimés sans risque.',
      },
      history: {
        title: 'Un historique qui révèle les tendances',
        text: 'Trente jours de mesures conservées sur votre Mac, de la dernière heure au dernier mois. Comparez des périodes, exportez en CSV ou JSON et lisez de courtes notes sur ce qui a varié ensemble.',
        alt: 'L’écran Historique avec 24 heures de graphiques CPU, GPU, pression mémoire, température et ventilateurs.',
        label: 'Historique',
        why: 'Voyez si le ralentissement d’hier venait de la chaleur, de la mémoire ou du disque.',
      },
      settings: {
        title: 'À votre façon',
        text: 'Choisissez les indicateurs de la barre des menus et leur ordre, les tuiles de la vue d’ensemble, les unités, la fréquence d’actualisation, des alertes avec des seuils qui doivent durer avant de vous prévenir, l’apparence et la langue.',
        alt: 'La fenêtre Réglages sur le panneau Général.',
        label: 'Réglages',
        why: 'Gardez seulement les chiffres qui comptent, là où vous les voulez.',
      },
      native: {
        title: 'Natif de bout en bout',
        text: 'Conçu avec SwiftUI et AppKit pour macOS 14 et versions ultérieures, en clair et en sombre, en dix langues, avec des libellés VoiceOver et la navigation au clavier. Il mesure moins souvent quand sa fenêtre est masquée et se met en pause pendant la veille du Mac.',
        alt: 'L’écran Mémoire avec la pression mémoire, l’utilisation par type et un graphique de mémoire.',
        label: 'Natif',
        why: 'Il s’intègre à macOS et ne gêne pas votre travail.',
      },
    },
  },
  menubar: {
    eyebrow: 'Barre des menus',
    title: 'Votre Mac, depuis la barre des menus',
    text: 'Gardez les chiffres qui comptent à côté de l’horloge, en texte ou en petits graphiques. Un clic ouvre la vue complète ; la fenêtre reste fermée.',
    points: [
      'Choisissez les indicateurs, leur ordre et s’ils affichent un graphique.',
      'Empilez deux indicateurs dans une colonne quand la barre des menus est encombrée.',
      'Quand seule la barre des menus est visible, iSensa s’actualise moins souvent pour économiser l’énergie.',
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
      chip: { label: 'Processeur', value: 'Apple silicon. Validé sur un M3 Pro ; sur d’autres puces, certains capteurs peuvent apparaître sous leur nom brut.' },
      intel: { label: 'Mac Intel', value: 'Non pris en charge par les versions actuelles.' },
      space: { label: 'Espace disque', value: 'Moins de 20 Mo' },
      permissions: {
        label: 'Autorisations',
        value: 'Aucune pour la surveillance. Facultatives : les notifications pour les alertes, l’accès aux dossiers pour l’analyse Libérer de l’espace et votre mot de passe administrateur pour installer l’assistant des ventilateurs.',
      },
    },
    limitations: 'Les capteurs et commandes disponibles dépendent du modèle de Mac. Le contrôle des ventilateurs est expérimental et n’existe que sur les Mac équipés de ventilateurs. Les fréquences et la puissance sont déduites de compteurs du système et signalées comme telles.',
  },
  openSource: {
    eyebrow: 'Open source',
    title: 'Open source, et honnête sur ses données',
    text: 'iSensa est un logiciel libre. Chaque mesure, chaque règle et chaque mot affiché peut être lu, discuté et amélioré sur GitHub.',
    principles: {
      honest: { title: 'Aucun nom inventé', text: 'Un capteur n’est nommé qu’une fois vérifié sur ce modèle. Les valeurs estimées et déduites le précisent.' },
      local: { title: 'Rien ne quitte votre Mac', text: 'L’app n’établit aucune connexion réseau. L’historique reste dans un fichier sur votre Mac.' },
      safe: { title: 'Prudent avec le matériel', text: 'Le contrôle des ventilateurs est validé deux fois, a ses propres limites de sécurité et rend les ventilateurs à macOS à la moindre défaillance.' },
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
