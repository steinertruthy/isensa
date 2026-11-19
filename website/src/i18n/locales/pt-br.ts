import type { Dictionary } from './en';

const ptBR: Dictionary = {
  meta: {
    title: 'iSensa — Monitor de hardware para macOS',
    description:
      'iSensa é um app gratuito e de código aberto para Mac que mostra leituras ao vivo de CPU, GPU, memória, temperaturas, bateria, ventoinhas e armazenamento, explica o que significam e indica de onde vem cada número.',
    ogAlt: 'A janela do iSensa mostrando a Visão geral de um MacBook Pro, com gráficos ao vivo de CPU e GPU.',
  },
  nav: {
    skip: 'Ir para o conteúdo',
    features: 'Recursos',
    gallery: 'Galeria',
    download: 'Download',
    openSource: 'Código aberto',
    github: 'iSensa no GitHub',
    menu: 'Menu',
    closeMenu: 'Fechar menu',
    language: 'Idioma',
    theme: 'Aparência',
    themeSystem: 'Automática',
    themeLight: 'Clara',
    themeDark: 'Escura',
    home: 'Página inicial do iSensa',
  },
  hero: {
    title: 'Conheça seu Mac.\nEm cada detalhe.',
    subtitle: 'Leituras precisas, explicações claras e controle cuidadoso do hardware, em um app nativo feito para o macOS.',
    download: 'Baixar para macOS',
    github: 'Ver no GitHub',
    openSource: 'Gratuito e de código aberto, sob a Licença MIT.',
    videoLabel: 'O iSensa rodando em um MacBook Pro: as telas Visão geral, Temperaturas, Histórico e CPU com leituras ao vivo.',
    pause: 'Pausar vídeo',
    play: 'Reproduzir vídeo',
  },
  tour: {
    title: 'Um minuto com o iSensa',
    text: 'Gravado em um MacBook Pro de 14 polegadas com M3 Pro. Cada valor na tela é uma leitura ao vivo daquele Mac; nada foi encenado nem acrescentado na edição.',
    play: 'Assistir ao tour',
    label: 'Tour pelo iSensa: Visão geral, CPU, GPU, Temperaturas, Bateria, Ventoinhas, Memória, Histórico, Ajustes e o popover da barra de menus.',
    unsupported: 'Seu navegador não consegue reproduzir este vídeo.',
    download: 'Baixar o vídeo (MP4)',
  },
  status: {
    available: 'Disponível',
    experimental: 'Experimental',
    varies: 'Depende do Mac',
  },
  features: {
    title: 'Tudo o que seu Mac está fazendo, explicado.',
    intro: 'Cada componente mantém uma cor em todo lugar, e cada número vem com uma frase que diz se está normal.',
    items: {
      realtime: {
        title: 'Ao vivo, sem ruído',
        text: 'CPU, GPU, memória, energia e rede se atualizam a cada segundo. Os núcleos de desempenho e de eficiência aparecem separados, e a memória é avaliada pela pressão, como o macOS avalia, e não pelo quanto parece cheia.',
        alt: 'A Visão geral: uma frase de resumo, a onda ao vivo de CPU e GPU e blocos de CPU, GPU, memória, temperatura, energia e ventoinhas.',
      },
      thermals: {
        title: 'Temperaturas em que você pode confiar',
        text: 'O iSensa lê os sensores térmicos do Mac e só dá nome a um sensor depois de verificá-lo naquele modelo. O que ele não consegue identificar mantém a chave original em vez de um nome inventado. Os sensores disponíveis dependem do Mac.',
        alt: 'A tela Temperaturas com leituras de CPU, GPU, SSD e bateria e um gráfico de temperatura.',
      },
      battery: {
        title: 'Saúde da bateria em palavras simples',
        text: 'Carga, saúde, ciclos, capacidade de projeto e de carga completa, tensão, corrente, a potência do carregador e o tempo restante informado pelo macOS.',
        alt: 'A tela Bateria com nível de carga, saúde, ciclos e detalhes do carregamento.',
      },
      fans: {
        title: 'Ventoinhas: acompanhe e, se quiser, assuma o controle',
        text: 'RPM e faixa de cada ventoinha. Em Macs com ventoinhas, um controle experimental oferece velocidades fixas e curvas. Ele precisa de um pequeno auxiliar instalado com sua senha de administrador e devolve as ventoinhas ao macOS sempre que algo parece errado.',
        alt: 'A tela Ventoinhas com duas ventoinhas em controle automático e a opção de instalar o auxiliar.',
      },
      storage: {
        title: 'Armazenamento que explica por que está cheio',
        text: 'Espaço usado, removível e livre, velocidade do disco, saúde do SSD informada pela própria unidade e uma análise Liberar espaço que encontra as maiores pastas, arquivos e apps e move para o Lixo o que você escolher.',
        alt: 'A tela Armazenamento com uso do disco, espaço removível, snapshots locais e o acesso a Liberar espaço.',
      },
      history: {
        title: 'Histórico que encontra padrões',
        text: 'Trinta dias de leituras guardados no seu Mac, da última hora ao último mês. Compare períodos, exporte em CSV ou JSON e leia notas curtas sobre o que mudou junto.',
        alt: 'A tela Histórico com 24 horas de gráficos de CPU, GPU, pressão de memória, temperatura e ventoinhas.',
      },
      settings: {
        title: 'Do seu jeito',
        text: 'Escolha os indicadores da barra de menus e a ordem deles, os blocos da visão geral, as unidades, a frequência de atualização, alertas com limites que precisam durar antes de avisar, a aparência e o idioma.',
        alt: 'A janela de Ajustes no painel Geral.',
      },
      native: {
        title: 'Nativo por inteiro',
        text: 'Feito com SwiftUI e AppKit para o macOS 14 ou posterior, em modo claro e escuro, em dez idiomas, com rótulos para o VoiceOver e navegação por teclado. Lê menos quando a janela está oculta e pausa enquanto o Mac dorme.',
        alt: 'A tela Memória com pressão de memória, uso por tipo e um gráfico de memória.',
      },
    },
  },
  menubar: {
    title: 'Seu Mac, direto da barra de menus',
    text: 'Deixe os números que importam ao lado do relógio, como texto ou pequenos gráficos. Um clique abre o panorama completo; a janela continua fechada.',
    points: [
      'Escolha os indicadores, a ordem e se cada um mostra um gráfico.',
      'Empilhe dois indicadores em uma coluna quando a barra de menus estiver cheia.',
      'Quando só a barra de menus está visível, o iSensa atualiza com menos frequência para economizar energia.',
    ],
    statusAlt: 'O iSensa na barra de menus mostrando o uso e a temperatura da CPU.',
    popoverAlt: 'O popover do iSensa com leituras de CPU, GPU, temperatura, memória, bateria, energia, ventoinhas e rede.',
  },
  gallery: {
    title: 'Galeria',
    intro: 'Telas capturadas do iSensa rodando em um MacBook Pro com M3 Pro.',
    previous: 'Captura anterior',
    next: 'Próxima captura',
    open: 'Ampliar captura',
    close: 'Fechar',
    counter: '{current} de {total}',
    items: {
      overview: 'Visão geral',
      cpu: 'CPU',
      gpu: 'GPU',
      memory: 'Memória',
      battery: 'Bateria',
      thermals: 'Temperaturas',
      sensors: 'Sensores',
      fans: 'Ventoinhas',
      storage: 'Armazenamento',
      history: 'Histórico',
      popover: 'Popover da barra de menus',
      settings: 'Ajustes',
    },
  },
  download: {
    title: 'Baixe o iSensa',
    intro: 'Publicado no GitHub Releases, com o código-fonte de cada versão.',
    loading: 'Consultando a versão mais recente no GitHub…',
    version: 'Versão {version}',
    stable: 'Estável',
    beta: 'Beta',
    released: 'Lançamento',
    size: 'Tamanho',
    architecture: 'Arquitetura',
    checksum: 'SHA-256',
    copy: 'Copiar',
    copied: 'Copiado',
    notes: 'Notas da versão',
    allReleases: 'Todas as versões',
    source: 'Código-fonte',
    buttonMac: 'Baixar para macOS',
    buttonOther: 'Ver downloads para macOS',
    noReleaseTitle: 'A primeira versão pública está a caminho',
    noReleaseText: 'Ainda não há uma versão para baixar. Acompanhe o repositório para saber quando ela chegar, ou compile o iSensa a partir do código-fonte.',
    errorText: 'Não foi possível acessar o GitHub agora. A página de versões tem todas elas.',
    notMac: 'O iSensa é feito para o macOS. Você ainda pode ver as versões publicadas ou ler o código-fonte.',
    archUnknown: 'Veja as notas da versão',
    installTitle: 'Instalação',
    install: [
      'Abra a imagem de disco baixada.',
      'Arraste o iSensa para a pasta Aplicativos.',
      'Abra o iSensa. As versões ainda não são assinadas com um Developer ID da Apple, então na primeira vez o macOS pede confirmação: abra Ajustes do Sistema › Privacidade e Segurança e escolha Abrir Mesmo Assim.',
    ],
    license: 'Licença MIT',
  },
  requirements: {
    title: 'Requisitos',
    items: {
      macos: { label: 'Sistema', value: 'macOS 14 Sonoma ou posterior' },
      chip: { label: 'Processador', value: 'Apple silicon. Validado em um M3 Pro; em outros chips, alguns sensores podem aparecer com o nome original.' },
      intel: { label: 'Macs com Intel', value: 'Não são compatíveis com as versões atuais.' },
      space: { label: 'Espaço em disco', value: 'Menos de 20 MB' },
      permissions: {
        label: 'Permissões',
        value: 'Nenhuma para monitorar. Opcionais: notificações para alertas, acesso a pastas para a análise Liberar espaço e sua senha de administrador para instalar o auxiliar das ventoinhas.',
      },
    },
    limitations: 'Os sensores e controles disponíveis dependem do modelo do Mac. O controle das ventoinhas é experimental e só existe em Macs com ventoinhas. Frequências e potência são derivadas de contadores do sistema e identificadas como tal.',
  },
  openSource: {
    title: 'Código aberto e honesto sobre seus dados',
    text: 'O iSensa é software livre. Cada leitura, cada regra e cada palavra na tela podem ser lidas, questionadas e melhoradas no GitHub.',
    principles: {
      honest: { title: 'Nenhum nome inventado', text: 'Um sensor só ganha nome quando é verificado naquele modelo. Valores estimados e derivados dizem isso.' },
      local: { title: 'Nada sai do seu Mac', text: 'O app não faz conexões de rede. O histórico fica em um arquivo no seu Mac.' },
      safe: { title: 'Cuidado com o hardware', text: 'O controle das ventoinhas é validado duas vezes, tem limites de segurança próprios e devolve as ventoinhas ao macOS em qualquer falha.' },
    },
    explore: 'Explorar no GitHub',
    stats: { stars: 'Estrelas', forks: 'Forks', issues: 'Issues abertas', release: 'Última versão', none: 'Nenhuma ainda' },
    links: {
      issues: 'Issues',
      pulls: 'Pull requests',
      releases: 'Versões',
      docs: 'Documentação',
      contributing: 'Guia de contribuição',
      security: 'Política de segurança',
      license: 'Licença',
    },
  },
  footer: {
    tagline: 'Um monitor de hardware nativo para macOS, honesto sobre o que mede.',
    product: 'Produto',
    project: 'Projeto',
    legal: 'Legal',
    terms: 'Termos de Uso',
    privacy: 'Política de Privacidade',
    latest: 'Última versão: {version}',
    noRelease: 'Nenhuma versão pública ainda',
    openSource: 'Código aberto sob a Licença MIT.',
    trademark: 'Mac e macOS são marcas registradas da Apple Inc. O iSensa não tem vínculo com a Apple.',
  },
  notFound: {
    title: 'Esta página não existe',
    text: 'O endereço pode estar errado, ou a página mudou de lugar.',
    home: 'Ir para a página inicial',
  },
  legal: {
    draft: 'Rascunho para revisão jurídica. Este texto descreve como o projeto funciona hoje, mas ainda não foi revisado por um advogado.',
    updated: 'Última atualização: {date}',
    back: 'Voltar à página inicial',
    terms: {
      title: 'Termos de Uso',
      description: 'As condições para usar o iSensa e o seu site.',
      sections: [
        {
          heading: 'Sobre o iSensa',
          body: [
            'O iSensa é um aplicativo de código aberto que monitora e diagnostica o hardware de computadores Mac e, em modelos compatíveis, pode controlar a velocidade das ventoinhas. Ele é desenvolvido por colaboradores independentes e publicado em github.com/steinertruthy/isensa.',
          ],
        },
        {
          heading: 'Licença',
          body: [
            'O código-fonte e as versões publicadas são distribuídos sob a Licença MIT. A licença permite usar, copiar, modificar, mesclar, publicar, distribuir, sublicenciar e vender cópias do software, desde que o aviso de copyright e de permissão seja mantido. Quando estes termos e a licença divergirem sobre o software, prevalece a licença.',
          ],
        },
        {
          heading: 'Uso do software',
          body: [
            'Você pode usar o iSensa para fins pessoais ou profissionais. Você é responsável pela forma como o utiliza, incluindo qualquer mudança que fizer nos ajustes do hardware e qualquer arquivo que escolher mover para o Lixo com a análise Liberar espaço.',
          ],
        },
        {
          heading: 'Monitoramento e seus limites',
          body: [
            'As leituras vêm de interfaces fornecidas pelo macOS e pelo hardware do Mac, algumas delas não documentadas. A disponibilidade e a precisão variam conforme o modelo e a versão do macOS, e podem mudar ou deixar de funcionar após atualizações. O iSensa identifica valores estimados e derivados, mas nenhuma leitura deve ser tratada como medição certificada.',
          ],
        },
        {
          heading: 'Controle das ventoinhas e componentes privilegiados',
          body: [
            'O controle das ventoinhas é experimental. Ele exige instalar um auxiliar que roda com privilégios de administrador, autorizado com a sua senha. O auxiliar valida cada comando, respeita os limites de velocidade informados pelo hardware e devolve as ventoinhas ao controle automático quando o app deixa de responder ou uma leitura falha. Mesmo assim, mudar o comportamento das ventoinhas afeta temperaturas e ruído; use por sua conta e risco e desinstale o auxiliar quando quiser.',
          ],
        },
        {
          heading: 'Ausência de garantias',
          body: [
            'O software é fornecido “no estado em que se encontra”, sem garantia de qualquer tipo, expressa ou implícita, incluindo garantias de comercialização, adequação a uma finalidade específica e não violação. Na medida permitida pela lei aplicável, os autores e colaboradores não se responsabilizam por qualquer reclamação, dano ou outra responsabilidade decorrente do software ou do seu uso. Algumas jurisdições não permitem essas exclusões; nesse caso, elas se aplicam até onde a lei permite.',
          ],
        },
        {
          heading: 'Propriedade intelectual',
          body: [
            'O nome iSensa e o seu ícone identificam o projeto. As contribuições são aceitas sob a licença do projeto. Mac e macOS são marcas registradas da Apple Inc.; o iSensa não tem vínculo com a Apple nem é endossado ou patrocinado por ela.',
          ],
        },
        {
          heading: 'Alterações destes termos',
          body: [
            'Estes termos podem mudar conforme o projeto evolui. As mudanças são publicadas nesta página e registradas no histórico do repositório, com a data da última atualização indicada acima.',
          ],
        },
        {
          heading: 'Contato',
          body: ['Dúvidas sobre estes termos podem ser enviadas como uma issue no repositório do GitHub.'],
        },
      ],
    },
    privacy: {
      title: 'Política de Privacidade',
      description: 'O que o site e o app iSensa fazem com dados.',
      sections: [
        {
          heading: 'Resumo',
          body: [
            'O app iSensa funciona inteiramente no seu Mac e não faz conexões de rede. Este site não usa cookies nem ferramentas de análise. Os serviços que recebem as suas solicitações são os do GitHub, descritos abaixo.',
          ],
        },
        {
          heading: 'O site',
          body: [
            'O site é hospedado pelo GitHub Pages. Para mostrar a versão mais recente e as estatísticas do repositório, o seu navegador solicita informações públicas à API do GitHub (api.github.com). Os downloads são servidos pelo GitHub. Como qualquer servidor web, o GitHub recebe o seu endereço IP e dados do navegador nessas solicitações e os trata conforme a Declaração de Privacidade do GitHub.',
            'O site guarda o idioma e a aparência que você escolheu no armazenamento local do navegador. Isso fica no seu dispositivo, não é enviado a lugar algum e pode ser apagado a qualquer momento nos ajustes do navegador.',
          ],
        },
        {
          heading: 'O app',
          body: [
            'O iSensa lê informações do hardware e do sistema do seu Mac (como uso, temperaturas, bateria e armazenamento) para exibi-las. O histórico e as preferências ficam apenas no seu Mac, em ~/Library/Application Support/iSensa e nas preferências do app, e você pode exportá-los ou apagá-los nos Ajustes.',
            'A análise Liberar espaço lê tamanhos e nomes de pastas e arquivos, nunca o conteúdo deles, e só quando você a inicia. O macOS pode pedir permissão para acessar algumas pastas; você pode recusar ou revogar nos Ajustes do Sistema.',
            'As notificações são criadas localmente pelo macOS. O app não contém serviços de análise, publicidade ou relatórios de falhas.',
          ],
        },
        {
          heading: 'Retenção e segurança',
          body: [
            'O app guarda o histórico detalhado por um período curto e os resumos pelo número de dias escolhido nos Ajustes. Nada é guardado pelos mantenedores do projeto, porque nada é enviado a eles.',
          ],
        },
        {
          heading: 'Seus direitos',
          body: [
            'Como o projeto não coleta dados pessoais, não há nada em poder dele para acessar, corrigir ou apagar. Para dados tratados pelo GitHub, você pode exercer seus direitos junto ao GitHub, conforme a declaração de privacidade dele. Dependendo de onde você mora, leis como a LGPD ou o GDPR podem garantir direitos adicionais.',
          ],
        },
        {
          heading: 'Alterações',
          body: ['Se o site ou o app passarem a tratar dados de outra forma, esta política será atualizada antes de essa mudança ser publicada.'],
        },
        {
          heading: 'Contato',
          body: ['Dúvidas sobre privacidade podem ser enviadas como uma issue no repositório do GitHub.'],
        },
      ],
    },
  },
};

export default ptBR;
