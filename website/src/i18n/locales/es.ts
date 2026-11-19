import type { Dictionary } from './en';

const es: Dictionary = {
  meta: {
    title: 'iSensa — Monitor de hardware para macOS',
    description:
      'iSensa es una app gratuita y de código abierto para Mac que muestra lecturas en vivo de CPU, GPU, memoria, temperaturas, batería, ventiladores y almacenamiento, explica qué significan e indica de dónde sale cada número.',
    ogAlt: 'La ventana de iSensa con el Resumen de un MacBook Pro y gráficos en vivo de CPU y GPU.',
  },
  nav: {
    skip: 'Ir al contenido',
    features: 'Funciones',
    gallery: 'Galería',
    download: 'Descargar',
    openSource: 'Código abierto',
    github: 'iSensa en GitHub',
    menu: 'Menú',
    closeMenu: 'Cerrar menú',
    language: 'Idioma',
    theme: 'Apariencia',
    themeSystem: 'Automática',
    themeLight: 'Clara',
    themeDark: 'Oscura',
    home: 'Inicio de iSensa',
  },
  hero: {
    title: 'Conoce tu Mac.\nAl detalle.',
    subtitle: 'Lecturas precisas, explicaciones claras y un control cuidadoso del hardware, en una app nativa hecha para macOS.',
    download: 'Descargar para macOS',
    github: 'Ver en GitHub',
    openSource: 'Gratis y de código abierto, con licencia MIT.',
    videoLabel: 'iSensa en un MacBook Pro: las pantallas Resumen, Temperaturas, Historial y CPU con lecturas en vivo.',
    pause: 'Pausar vídeo',
    play: 'Reproducir vídeo',
  },
  tour: {
    title: 'Un minuto con iSensa',
    text: 'Grabado en un MacBook Pro de 14 pulgadas con M3 Pro. Cada valor en pantalla es una lectura en vivo de ese Mac; nada se preparó ni se añadió en la edición.',
    play: 'Ver el recorrido',
    label: 'Recorrido por iSensa: Resumen, CPU, GPU, Temperaturas, Batería, Ventiladores, Memoria, Historial, Ajustes y el panel de la barra de menús.',
    unsupported: 'Tu navegador no puede reproducir este vídeo.',
    download: 'Descargar el vídeo (MP4)',
  },
  status: {
    available: 'Disponible',
    experimental: 'Experimental',
    varies: 'Depende del Mac',
  },
  features: {
    title: 'Todo lo que hace tu Mac, explicado.',
    intro: 'Cada componente conserva un color en todas partes, y cada número viene con una frase que dice si es normal.',
    items: {
      realtime: {
        title: 'En vivo, sin ruido',
        text: 'CPU, GPU, memoria, energía y red se actualizan cada segundo. Los núcleos de rendimiento y de eficiencia se muestran por separado, y la memoria se juzga por la presión, como lo hace macOS, no por lo llena que parece.',
        alt: 'El Resumen: una frase de estado, la onda en vivo de CPU y GPU y bloques de CPU, GPU, memoria, temperatura, energía y ventiladores.',
      },
      thermals: {
        title: 'Temperaturas en las que confiar',
        text: 'iSensa lee los sensores térmicos del Mac y solo nombra un sensor después de verificarlo en ese modelo. Lo que no puede identificar conserva su clave original en lugar de un nombre inventado. Los sensores disponibles dependen del Mac.',
        alt: 'La pantalla Temperaturas con lecturas de CPU, GPU, SSD y batería y un gráfico de temperatura.',
      },
      battery: {
        title: 'La salud de la batería, en palabras claras',
        text: 'Carga, salud, ciclos, capacidad de diseño y de carga completa, voltaje, corriente, la potencia del cargador y el tiempo restante que informa macOS.',
        alt: 'La pantalla Batería con nivel de carga, salud, ciclos y detalles de la carga.',
      },
      fans: {
        title: 'Ventiladores: obsérvalos y toma el control cuando quieras',
        text: 'RPM y rango de cada ventilador. En los Mac con ventiladores, un control experimental ofrece velocidades fijas y curvas. Necesita un pequeño asistente que se instala con tu contraseña de administrador y devuelve los ventiladores a macOS en cuanto algo parece ir mal.',
        alt: 'La pantalla Ventiladores con dos ventiladores en control automático y la opción de instalar el asistente.',
      },
      storage: {
        title: 'Un almacenamiento que explica por qué está lleno',
        text: 'Espacio usado, purgable y libre, velocidad del disco, la salud del SSD según la propia unidad y un análisis Liberar espacio que encuentra las carpetas, archivos y apps más grandes y lleva a la Papelera lo que elijas.',
        alt: 'La pantalla Almacenamiento con uso del disco, espacio purgable, instantáneas locales y el acceso a Liberar espacio.',
      },
      history: {
        title: 'Un historial que encuentra patrones',
        text: 'Treinta días de lecturas guardados en tu Mac, de la última hora al último mes. Compara periodos, exporta en CSV o JSON y lee notas breves sobre lo que cambió a la vez.',
        alt: 'La pantalla Historial con 24 horas de gráficos de CPU, GPU, presión de memoria, temperatura y ventiladores.',
      },
      settings: {
        title: 'A tu manera',
        text: 'Elige los indicadores de la barra de menús y su orden, los bloques del resumen, las unidades, la frecuencia de actualización, alertas con umbrales que deben mantenerse antes de avisarte, la apariencia y el idioma.',
        alt: 'La ventana de Ajustes en el panel General.',
      },
      native: {
        title: 'Nativo de principio a fin',
        text: 'Hecho con SwiftUI y AppKit para macOS 14 o posterior, en modo claro y oscuro, en diez idiomas, con etiquetas para VoiceOver y navegación por teclado. Mide menos cuando su ventana está oculta y se detiene mientras el Mac duerme.',
        alt: 'La pantalla Memoria con presión de memoria, uso por tipo y un gráfico de memoria.',
      },
    },
  },
  menubar: {
    title: 'Tu Mac, desde la barra de menús',
    text: 'Ten los números que te importan junto al reloj, como texto o pequeños gráficos. Un clic abre el panorama completo; la ventana sigue cerrada.',
    points: [
      'Elige los indicadores, su orden y si cada uno muestra un gráfico.',
      'Apila dos indicadores en una columna cuando la barra de menús esté llena.',
      'Cuando solo se ve la barra de menús, iSensa se actualiza con menos frecuencia para ahorrar energía.',
    ],
    statusAlt: 'iSensa en la barra de menús con el uso y la temperatura de la CPU.',
    popoverAlt: 'El panel de iSensa con lecturas de CPU, GPU, temperatura, memoria, batería, energía, ventiladores y red.',
  },
  gallery: {
    title: 'Galería',
    intro: 'Pantallas capturadas de iSensa en un MacBook Pro con M3 Pro.',
    previous: 'Captura anterior',
    next: 'Captura siguiente',
    open: 'Ampliar captura',
    close: 'Cerrar',
    counter: '{current} de {total}',
    items: {
      overview: 'Resumen',
      cpu: 'CPU',
      gpu: 'GPU',
      memory: 'Memoria',
      battery: 'Batería',
      thermals: 'Temperaturas',
      sensors: 'Sensores',
      fans: 'Ventiladores',
      storage: 'Almacenamiento',
      history: 'Historial',
      popover: 'Panel de la barra de menús',
      settings: 'Ajustes',
    },
  },
  download: {
    title: 'Descarga iSensa',
    intro: 'Publicado en GitHub Releases, con el código fuente de cada versión.',
    loading: 'Consultando la última versión en GitHub…',
    version: 'Versión {version}',
    stable: 'Estable',
    beta: 'Beta',
    released: 'Publicada',
    size: 'Tamaño',
    architecture: 'Arquitectura',
    checksum: 'SHA-256',
    copy: 'Copiar',
    copied: 'Copiado',
    notes: 'Notas de la versión',
    allReleases: 'Todas las versiones',
    source: 'Código fuente',
    buttonMac: 'Descargar para macOS',
    buttonOther: 'Ver descargas para macOS',
    noReleaseTitle: 'La primera versión pública está en camino',
    noReleaseText: 'Todavía no hay una versión para descargar. Sigue el repositorio para saber cuándo llega, o compila iSensa desde el código fuente.',
    errorText: 'No se pudo contactar con GitHub en este momento. La página de versiones las tiene todas.',
    notMac: 'iSensa está hecho para macOS. Aun así puedes ver sus versiones o leer su código fuente.',
    archUnknown: 'Consulta las notas de la versión',
    installTitle: 'Instalación',
    install: [
      'Abre la imagen de disco descargada.',
      'Arrastra iSensa a la carpeta Aplicaciones.',
      'Abre iSensa. Las versiones aún no están firmadas con un Developer ID de Apple, así que la primera vez macOS pide confirmación: abre Ajustes del Sistema › Privacidad y seguridad y elige Abrir igualmente.',
    ],
    license: 'Licencia MIT',
  },
  requirements: {
    title: 'Requisitos',
    items: {
      macos: { label: 'Sistema', value: 'macOS 14 Sonoma o posterior' },
      chip: { label: 'Procesador', value: 'Apple silicon. Validado en un M3 Pro; en otros chips algunos sensores pueden aparecer con su nombre original.' },
      intel: { label: 'Mac con Intel', value: 'No compatibles con las versiones actuales.' },
      space: { label: 'Espacio en disco', value: 'Menos de 20 MB' },
      permissions: {
        label: 'Permisos',
        value: 'Ninguno para monitorizar. Opcionales: notificaciones para las alertas, acceso a carpetas para el análisis Liberar espacio y tu contraseña de administrador para instalar el asistente de ventiladores.',
      },
    },
    limitations: 'Los sensores y controles disponibles dependen del modelo de Mac. El control de ventiladores es experimental y solo existe en los Mac con ventiladores. Las frecuencias y la potencia se derivan de contadores del sistema y se indican como tales.',
  },
  openSource: {
    title: 'Código abierto y honesto con sus datos',
    text: 'iSensa es software libre. Cada lectura, cada regla y cada palabra en pantalla se puede leer, cuestionar y mejorar en GitHub.',
    principles: {
      honest: { title: 'Sin nombres inventados', text: 'Un sensor solo recibe nombre cuando se ha verificado en ese modelo. Los valores estimados y derivados lo indican.' },
      local: { title: 'Nada sale de tu Mac', text: 'La app no realiza conexiones de red. El historial se queda en un archivo de tu Mac.' },
      safe: { title: 'Cuidado con el hardware', text: 'El control de ventiladores se valida dos veces, tiene sus propios límites de seguridad y devuelve los ventiladores a macOS ante cualquier fallo.' },
    },
    explore: 'Explorar en GitHub',
    stats: { stars: 'Estrellas', forks: 'Forks', issues: 'Issues abiertas', release: 'Última versión', none: 'Ninguna todavía' },
    links: {
      issues: 'Issues',
      pulls: 'Pull requests',
      releases: 'Versiones',
      docs: 'Documentación',
      contributing: 'Guía de contribución',
      security: 'Política de seguridad',
      license: 'Licencia',
    },
  },
  footer: {
    tagline: 'Un monitor de hardware nativo para macOS, honesto con lo que mide.',
    product: 'Producto',
    project: 'Proyecto',
    legal: 'Legal',
    terms: 'Términos de uso',
    privacy: 'Política de privacidad',
    latest: 'Última versión: {version}',
    noRelease: 'Aún no hay versión pública',
    openSource: 'Código abierto con licencia MIT.',
    trademark: 'Mac y macOS son marcas comerciales de Apple Inc. iSensa no está afiliado a Apple.',
  },
  notFound: {
    title: 'Esta página no existe',
    text: 'Puede que la dirección esté mal escrita o que la página se haya movido.',
    home: 'Ir a la página de inicio',
  },
  legal: {
    draft: 'Borrador pendiente de revisión jurídica. Este texto describe cómo funciona el proyecto hoy, pero todavía no lo ha revisado un abogado.',
    updated: 'Última actualización: {date}',
    back: 'Volver a la página de inicio',
    terms: {
      title: 'Términos de uso',
      description: 'Las condiciones para usar iSensa y su sitio web.',
      sections: [
        {
          heading: 'Sobre iSensa',
          body: [
            'iSensa es una aplicación de código abierto que monitoriza y diagnostica el hardware de los ordenadores Mac y, en los modelos compatibles, puede controlar la velocidad de los ventiladores. La desarrollan colaboradores independientes y se publica en github.com/steinertruthy/isensa.',
          ],
        },
        {
          heading: 'Licencia',
          body: [
            'El código fuente y las versiones publicadas se distribuyen con la licencia MIT. La licencia permite usar, copiar, modificar, fusionar, publicar, distribuir, sublicenciar y vender copias del software, siempre que se conserve el aviso de copyright y de permiso. Si estos términos y la licencia difieren sobre el software, prevalece la licencia.',
          ],
        },
        {
          heading: 'Uso del software',
          body: [
            'Puedes usar iSensa con fines personales o profesionales. Eres responsable de cómo lo usas, incluido cualquier cambio que hagas en los ajustes del hardware y cualquier archivo que decidas llevar a la Papelera con el análisis Liberar espacio.',
          ],
        },
        {
          heading: 'La monitorización y sus límites',
          body: [
            'Las lecturas proceden de interfaces que ofrecen macOS y el hardware del Mac, algunas sin documentar. Su disponibilidad y precisión varían según el modelo y la versión de macOS, y pueden cambiar o dejar de funcionar tras una actualización. iSensa indica los valores estimados y derivados, pero ninguna lectura debe considerarse una medición certificada.',
          ],
        },
        {
          heading: 'Control de ventiladores y componentes con privilegios',
          body: [
            'El control de ventiladores es experimental. Requiere instalar un asistente que se ejecuta con privilegios de administrador, que autorizas con tu contraseña. El asistente valida cada orden, respeta los límites de velocidad que informa el hardware y devuelve los ventiladores al control automático si la app deja de responder o falla una lectura. Aun así, cambiar el comportamiento de los ventiladores afecta a las temperaturas y al ruido; úsalo bajo tu responsabilidad y desinstala el asistente cuando quieras.',
          ],
        },
        {
          heading: 'Sin garantía',
          body: [
            'El software se ofrece «tal cual», sin garantía de ningún tipo, expresa o implícita, incluidas las garantías de comerciabilidad, idoneidad para un fin concreto y no infracción. En la medida en que lo permita la ley aplicable, los autores y colaboradores no son responsables de ninguna reclamación, daño u otra responsabilidad derivada del software o de su uso. Algunas jurisdicciones no permiten estas exclusiones; en ese caso, se aplican en la medida que permita la ley.',
          ],
        },
        {
          heading: 'Propiedad intelectual',
          body: [
            'El nombre iSensa y su icono identifican el proyecto. Las contribuciones se aceptan con la licencia del proyecto. Mac y macOS son marcas comerciales de Apple Inc.; iSensa no está afiliado, respaldado ni patrocinado por Apple.',
          ],
        },
        {
          heading: 'Cambios en estos términos',
          body: [
            'Estos términos pueden cambiar a medida que evoluciona el proyecto. Los cambios se publican en esta página y quedan registrados en el historial del repositorio, con la fecha de la última actualización indicada arriba.',
          ],
        },
        {
          heading: 'Contacto',
          body: ['Las dudas sobre estos términos pueden plantearse como una issue en el repositorio de GitHub.'],
        },
      ],
    },
    privacy: {
      title: 'Política de privacidad',
      description: 'Qué hacen con los datos el sitio web y la app iSensa.',
      sections: [
        {
          heading: 'Resumen',
          body: [
            'La app iSensa funciona por completo en tu Mac y no realiza conexiones de red. Este sitio no usa cookies ni herramientas de análisis. Los servicios que sí ven tus solicitudes son los de GitHub, descritos a continuación.',
          ],
        },
        {
          heading: 'El sitio web',
          body: [
            'El sitio está alojado en GitHub Pages. Para mostrar la última versión y las estadísticas del repositorio, tu navegador solicita información pública a la API de GitHub (api.github.com). Las descargas las sirve GitHub. Como cualquier servidor web, GitHub recibe tu dirección IP y los datos de tu navegador con estas solicitudes y los trata según la Declaración de privacidad general de GitHub.',
            'El sitio recuerda el idioma y la apariencia que elegiste en el almacenamiento local del navegador. Eso se queda en tu dispositivo, no se envía a ningún sitio y puedes borrarlo cuando quieras desde los ajustes del navegador.',
          ],
        },
        {
          heading: 'La app',
          body: [
            'iSensa lee información del hardware y del sistema de tu Mac (como el uso, las temperaturas, la batería y el almacenamiento) para mostrarla. Su historial y sus preferencias se guardan solo en tu Mac, en ~/Library/Application Support/iSensa y en las preferencias de la app, y puedes exportarlos o borrarlos en Ajustes.',
            'El análisis Liberar espacio lee tamaños y nombres de carpetas y archivos, nunca su contenido, y solo cuando lo inicias. macOS puede pedir permiso para acceder a algunas carpetas; puedes negarlo o revocarlo en Ajustes del Sistema.',
            'Las notificaciones las crea macOS de forma local. La app no contiene servicios de análisis, publicidad ni informes de errores.',
          ],
        },
        {
          heading: 'Conservación y seguridad',
          body: [
            'La app conserva el historial detallado durante un periodo corto y los resúmenes durante el número de días elegido en Ajustes. Los responsables del proyecto no guardan nada, porque no se les envía nada.',
          ],
        },
        {
          heading: 'Tus derechos',
          body: [
            'Como el proyecto no recopila datos personales, no tiene nada que puedas consultar, corregir o eliminar. Para los datos que trata GitHub, puedes ejercer tus derechos ante GitHub según su declaración de privacidad. Según dónde vivas, leyes como el RGPD pueden concederte derechos adicionales.',
          ],
        },
        {
          heading: 'Cambios',
          body: ['Si el sitio o la app empiezan a tratar los datos de otra forma, esta política se actualizará antes de publicar ese cambio.'],
        },
        {
          heading: 'Contacto',
          body: ['Las dudas sobre privacidad pueden plantearse como una issue en el repositorio de GitHub.'],
        },
      ],
    },
  },
};

export default es;
