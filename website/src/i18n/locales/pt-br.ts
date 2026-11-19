import type { Dictionary } from './en';

const ptBR: Dictionary = {
  meta: {
    title: 'iSensa — Monitor de hardware para macOS',
    description:
      'iSensa é um app gratuito e de código aberto para Mac que mostra leituras ao vivo de CPU, GPU, memória, temperaturas, bateria, ventiladores e armazenamento, explica o que significam e indica de onde vem cada número.',
    ogAlt: 'A janela do iSensa mostrando a Visão geral de um MacBook Pro, com gráficos ao vivo de CPU e GPU.',
  },
  nav: {
    skip: 'Ir para o conteúdo',
    overview: 'Visão geral',
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
    subtitle: 'Veja o que o seu Mac está fazendo e entenda tudo em palavras simples. Um app gratuito, feito para o macOS.',
    download: 'Baixar para macOS',
    github: 'Ver no GitHub',
    openSource: 'Gratuito e de código aberto, sob a Licença MIT.',
    eyebrow: 'Monitoramento · Sensores · Controle',
    howItWorks: 'Veja como funciona',
    detected: 'Sistema detectado: {os}',
    platform: 'Para Macs com Apple silicon e macOS 14 ou posterior',
    screenAlt: 'A Visão geral do iSensa em um MacBook Pro com M3 Pro: um resumo do estado do Mac, gráficos ao vivo de CPU e GPU e blocos de cada componente.',
  },
  overview: {
    eyebrow: 'Visão geral',
    title: 'Uma janela para tudo o que há dentro do seu Mac.',
    text: 'Processador, placa de vídeo, memória, temperatura, bateria, ventiladores, armazenamento e rede: tudo num só lugar, explicado de forma simples, numa janela ou direto da barra de menus.',
    pillars: {
      native: { title: 'Parece parte do seu Mac', text: 'Tem a cara e o jeito dos apps que já vêm no seu Mac, no modo claro e no escuro.' },
      honest: { title: 'Palavras simples, sem jargão', text: 'Cada número vem com uma frase curta, para você saber quando algo merece atenção.' },
      safe: { title: 'Leve para o seu Mac', text: 'Usa pouquíssima energia e desacelera quando você não está olhando.' },
    },
  },
  spectrum: {
    cpu: 'CPU',
    gpu: 'GPU',
    memory: 'Memória',
    thermal: 'Temperatura',
    power: 'Energia',
    battery: 'Bateria',
    fans: 'Ventiladores',
    network: 'Rede',
    storage: 'Armazenamento',
  },
  status: {
    available: 'Disponível',
    experimental: 'Experimental',
    varies: 'Depende do Mac',
  },
  features: {
    eyebrow: 'Recursos',
    whyLabel: 'Por que ajuda',
    title: 'Tudo o que seu Mac está fazendo, explicado.',
    intro: 'Cada parte do seu Mac tem a sua cor, e cada número diz se está tudo normal.',
    items: {
      realtime: {
        title: 'Ao vivo, sem ruído',
        text: 'Veja num relance quanto o seu Mac está trabalhando agora e o que o está ocupando.',
        alt: 'A Visão geral: uma frase de resumo, a onda ao vivo de CPU e GPU e blocos de CPU, GPU, memória, temperatura, energia e ventiladores.',
        label: 'Tempo real',
        why: 'Descubra em segundos o que está deixando o Mac lento, sem abrir o Monitor de Atividade.',
      },
      thermals: {
        title: 'Temperaturas em que você pode confiar',
        text: 'Saiba quão quentes estão o processador, a placa de vídeo, o SSD e a bateria. O iSensa só dá nome a um sensor quando sabe exatamente o que ele mede. O que aparece depende do seu Mac.',
        alt: 'A tela Temperaturas com leituras de CPU, GPU, SSD e bateria e um gráfico de temperatura.',
        label: 'Temperaturas',
        why: 'Saiba se o Mac está só morno ou realmente quente antes de ele reduzir o desempenho.',
      },
      battery: {
        title: 'Saúde da bateria em palavras simples',
        text: 'Carga, saúde, quantos ciclos a bateria já fez e quanta energia o seu carregador realmente entrega.',
        alt: 'A tela Bateria com nível de carga, saúde, ciclos e detalhes do carregamento.',
        label: 'Bateria',
        why: 'Entenda como a bateria está envelhecendo e o que o carregador realmente entrega.',
      },
      fans: {
        title: 'Ventiladores: acompanhe ou assuma o controle',
        text: 'Veja a velocidade de cada ventilador. Em Macs com ventiladores, você também pode escolher ajustes mais silenciosos ou mais frescos. É opcional e experimental, e devolve o controle ao macOS se algo parecer errado.',
        alt: 'A tela Ventiladores com dois ventiladores em controle automático e a opção de instalar o auxiliar.',
        label: 'Ventiladores',
        why: 'Mantenha o Mac silencioso nas chamadas, ou mais frio em renderizações longas, com proteções automáticas.',
      },
      storage: {
        title: 'Descubra o que está enchendo o disco',
        text: 'Veja quanto espaço está ocupado e livre, confira a saúde do SSD e encontre as maiores pastas, arquivos e apps. Só vai para o Lixo o que você escolher.',
        alt: 'A tela Armazenamento com uso do disco, espaço removível, snapshots locais e o acesso a Liberar espaço.',
        label: 'Armazenamento',
        why: 'Recupere gigabytes sem adivinhar quais arquivos podem ser removidos com segurança.',
      },
      history: {
        title: 'Histórico que encontra padrões',
        text: 'Olhe para trás, da última hora ao último mês. O iSensa mostra o que mudou junto, como a temperatura subindo quando o Mac trabalha pesado.',
        alt: 'A tela Histórico com 24 horas de gráficos de CPU, GPU, pressão de memória, temperatura e ventiladores.',
        label: 'Histórico',
        why: 'Veja se a lentidão de ontem foi calor, memória ou disco.',
      },
      settings: {
        title: 'Do seu jeito',
        text: 'Escolha o que aparece na barra de menus e na visão geral, receba um alerta quando algo fica alto por tempo demais e defina a aparência e o idioma.',
        alt: 'A janela de Ajustes no painel Geral.',
        label: 'Ajustes',
        why: 'Mantenha só os números que importam para você, onde você quiser.',
      },
      native: {
        title: 'Feito para o Mac',
        text: 'Modo claro e escuro, dez idiomas, VoiceOver e teclado funcionando como você espera. Quando você não está olhando, o iSensa desacelera para poupar bateria.',
        alt: 'A tela Memória com pressão de memória, uso por tipo e um gráfico de memória.',
        label: 'Nativo',
        why: 'Parece parte do macOS e não atrapalha o seu trabalho.',
      },
    },
  },
  menubar: {
    eyebrow: 'Barra de menus',
    title: 'Seu Mac, direto da barra de menus',
    text: 'Deixe os números que importam ao lado do relógio. Um clique mostra todo o resto, sem abrir janela.',
    points: [
      'Escolha quais números mostrar e em que ordem, como texto ou pequenos gráficos.',
      'Pouco espaço? Junte dois números num só lugar.',
      'Quando só a barra de menus está visível, o iSensa atualiza menos vezes para economizar energia.',
    ],
    statusAlt: 'O iSensa na barra de menus mostrando o uso e a temperatura da CPU.',
    popoverAlt: 'O popover do iSensa com leituras de CPU, GPU, temperatura, memória, bateria, energia, ventiladores e rede.',
  },
  gallery: {
    eyebrow: 'Galeria',
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
      fans: 'Ventiladores',
      storage: 'Armazenamento',
      history: 'Histórico',
      popover: 'Popover da barra de menus',
      settings: 'Ajustes',
    },
  },
  download: {
    eyebrow: 'Download',
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
      chip: { label: 'Processador', value: 'Macs com Apple silicon. Testado em um M3 Pro; em outros Macs, alguns sensores podem aparecer sem um nome amigável.' },
      intel: { label: 'Macs com Intel', value: 'Não são compatíveis com as versões atuais.' },
      space: { label: 'Espaço em disco', value: 'Menos de 20 MB' },
      permissions: {
        label: 'Permissões',
        value: 'Nenhuma para ver as leituras do Mac. Opcionais: notificações para alertas, acesso a pastas para descobrir o que enche o disco e sua senha para ativar o controle dos ventiladores.',
      },
    },
    limitations: 'O que o iSensa consegue mostrar depende do seu Mac. O controle dos ventiladores é experimental e só existe em Macs com ventiladores. Alguns valores são estimativas e aparecem identificados como tal.',
  },
  openSource: {
    eyebrow: 'Código aberto',
    title: 'Código aberto e honesto sobre seus dados',
    text: 'O iSensa é gratuito e de código aberto. Qualquer pessoa pode ver como ele funciona, sugerir mudanças e ajudar a melhorá-lo no GitHub.',
    principles: {
      honest: { title: 'Nada inventado', text: 'Um sensor só ganha nome quando o iSensa tem certeza do que ele é. Estimativas aparecem como estimativas.' },
      local: { title: 'Nada sai do seu Mac', text: 'O iSensa não usa a internet. Seu histórico fica no seu Mac.' },
      safe: { title: 'Cuidado com o hardware', text: 'O controle dos ventiladores é opcional e devolve o controle ao macOS assim que algo parece errado.' },
    },
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
            'O iSensa é um aplicativo de código aberto que monitora e diagnostica o hardware de computadores Mac e, em modelos compatíveis, pode controlar a velocidade dos ventiladores. Ele é desenvolvido por colaboradores independentes e publicado em github.com/steinertruthy/isensa.',
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
          heading: 'Controle dos ventiladores e componentes privilegiados',
          body: [
            'O controle dos ventiladores é experimental. Ele exige instalar um auxiliar que roda com privilégios de administrador, autorizado com a sua senha. O auxiliar valida cada comando, respeita os limites de velocidade informados pelo hardware e devolve os ventiladores ao controle automático quando o app deixa de responder ou uma leitura falha. Mesmo assim, mudar o comportamento dos ventiladores afeta temperaturas e ruído; use por sua conta e risco e desinstale o auxiliar quando quiser.',
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
