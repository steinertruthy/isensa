import type { Dictionary } from './en';

const zhHans: Dictionary = {
  meta: {
    title: 'iSensa — macOS 硬件监视器',
    description:
      'iSensa 是一款免费开源的 Mac 应用，实时显示 CPU、GPU、内存、温度、电池、风扇和存储的读数，解释它们的含义，并标明每个数字的来源。',
    ogAlt: 'iSensa 窗口显示一台 MacBook Pro 的概览，带有实时 CPU 和 GPU 图表。',
  },
  nav: {
    skip: '跳到正文',
    overview: '概览',
    features: '功能',
    gallery: '截图',
    download: '下载',
    openSource: '开源',
    github: 'GitHub 上的 iSensa',
    menu: '菜单',
    closeMenu: '关闭菜单',
    language: '语言',
    theme: '外观',
    themeSystem: '自动',
    themeLight: '浅色',
    themeDark: '深色',
    home: 'iSensa 首页',
  },
  hero: {
    title: '了解你的 Mac，\n每一处细节。',
    subtitle: '看看你的 Mac 正在做什么，用简单的话弄明白。一款为 macOS 打造的免费应用。',
    download: '下载 macOS 版',
    github: '在 GitHub 上查看',
    openSource: '免费开源，采用 MIT 许可证。',
    eyebrow: '监视 · 传感器 · 控制',
    howItWorks: '了解工作方式',
    detected: '检测到的系统：{os}',
    platform: '适用于搭载 Apple 芯片、运行 macOS 14 或更高版本的 Mac',
    screenAlt: 'iSensa 在搭载 M3 Pro 的 MacBook Pro 上的概览屏幕：Mac 的状态、实时 CPU 和 GPU 图表，以及每个组件的卡片。',
  },
  overview: {
    eyebrow: '概览',
    title: '一个窗口，看清 Mac 内部的一切。',
    text: '处理器、图形处理器、内存、温度、电池、风扇、存储和网络，全都集中在一处，用简单的话说明白，在窗口里或直接在菜单栏中。',
    pillars: {
      native: { title: '就像 Mac 的一部分', text: '外观和用法都和 Mac 自带的应用一样，支持浅色和深色。' },
      honest: { title: '说人话，不说术语', text: '每个数字都配有一句简短说明，让你知道什么时候需要留意。' },
      safe: { title: '对 Mac 很轻', text: '耗电极少，你不看的时候还会放慢节奏。' },
    },
  },
  spectrum: {
    cpu: 'CPU',
    gpu: 'GPU',
    memory: '内存',
    thermal: '温度',
    power: '功耗',
    battery: '电池',
    fans: '风扇',
    network: '网络',
    storage: '存储',
  },
  status: {
    available: '可用',
    experimental: '实验性',
    varies: '视 Mac 而定',
  },
  features: {
    eyebrow: '功能',
    whyLabel: '有什么帮助',
    title: '你的 Mac 在做什么，一目了然。',
    intro: 'Mac 的每个部分都有自己的颜色，每个数字都会告诉你是否正常。',
    items: {
      realtime: {
        title: '实时，不嘈杂',
        text: '一眼看出 Mac 此刻有多忙，以及是什么让它忙碌。',
        alt: '概览：一句状态摘要、CPU 和 GPU 的实时波形，以及 CPU、GPU、内存、温度、功耗和风扇的卡片。',
        label: '实时',
        why: '几秒内找出拖慢 Mac 的原因，无需打开活动监视器。',
      },
      thermals: {
        title: '值得信赖的温度',
        text: '了解处理器、图形处理器、SSD 和电池有多热。只有在确切知道传感器测的是什么时，iSensa 才会给它命名。显示的内容取决于你的 Mac。',
        alt: '温度屏幕，显示 CPU、GPU、SSD 和电池读数及温度图表。',
        label: '温度',
        why: '在 Mac 降低性能之前，就知道它只是有点温热还是真的很烫。',
      },
      battery: {
        title: '用简单的话说清电池健康',
        text: '电量、健康状况、电池已经历的循环次数，以及充电器实际提供了多少电量。',
        alt: '电池屏幕，显示电量、健康状况、循环次数和充电详情。',
        label: '电池',
        why: '了解电池的老化情况，以及充电器实际提供了多少电量。',
      },
      fans: {
        title: '风扇：随时查看，也能亲自掌控',
        text: '查看每个风扇转得有多快。在配有风扇的 Mac 上，你还可以选择更安静或更凉爽的设置。这是可选的实验性功能，一旦发现异常就会把控制权交还给 macOS。',
        alt: '风扇屏幕，显示两个处于自动控制的风扇和安装辅助程序的选项。',
        label: '风扇',
        why: '通话时保持安静，长时间渲染时保持凉爽，并有自动保护。',
      },
      storage: {
        title: '找出是什么占满了磁盘',
        text: '查看已用和可用空间，检查 SSD 的健康状况，找出最大的文件夹、文件和应用。只有你选中的才会移到废纸篓。',
        alt: '存储屏幕，显示磁盘用量、可清除空间、本地快照和“释放空间”入口。',
        label: '存储',
        why: '无需猜测哪些文件可以安全删除，就能找回数 GB 空间。',
      },
      history: {
        title: '能发现规律的历史记录',
        text: '回顾从最近一小时到最近一个月的情况。iSensa 会指出哪些变化是同时发生的，比如 Mac 满负荷工作时温度随之上升。',
        alt: '历史屏幕，显示 CPU、GPU、内存压力、温度和风扇的 24 小时图表。',
        label: '历史',
        why: '看看昨天变慢是因为温度、内存还是磁盘。',
      },
      settings: {
        title: '按你的方式',
        text: '选择菜单栏和概览中显示的内容，在某项数值长时间过高时收到提醒，并挑选外观和语言。',
        alt: '设置窗口的“通用”面板。',
        label: '设置',
        why: '只保留你关心的数字，放在你想要的位置。',
      },
      native: {
        title: '为 Mac 而生',
        text: '浅色与深色、十种语言、VoiceOver 和键盘都如你所愿地工作。你不看的时候，iSensa 会放慢节奏来节省电量。',
        alt: '内存屏幕，显示内存压力、按类型划分的用量和内存图表。',
        label: '原生',
        why: '感觉就像 macOS 的一部分，不会打扰你的工作。',
      },
    },
  },
  menubar: {
    eyebrow: '菜单栏',
    title: '在菜单栏里看你的 Mac',
    text: '把你关心的数字放在时钟旁边。点一下就能看到其余一切，无需打开窗口。',
    points: [
      '选择要显示哪些数字以及顺序，以文字或小图表呈现。',
      '空间不够？把两个数字放在同一个位置。',
      '只显示菜单栏时，iSensa 会减少更新次数以节省电量。',
    ],
    statusAlt: '菜单栏中的 iSensa，显示 CPU 使用率和温度。',
    popoverAlt: 'iSensa 弹出窗口，显示 CPU、GPU、温度、内存、电池、功耗、风扇和网络读数。',
  },
  gallery: {
    eyebrow: '截图',
    title: '截图',
    intro: '截取自在搭载 M3 Pro 的 MacBook Pro 上运行的 iSensa。',
    previous: '上一张截图',
    next: '下一张截图',
    open: '放大截图',
    close: '关闭',
    counter: '第 {current} 张，共 {total} 张',
    items: {
      overview: '概览',
      cpu: 'CPU',
      gpu: 'GPU',
      memory: '内存',
      battery: '电池',
      thermals: '温度',
      sensors: '传感器',
      fans: '风扇',
      storage: '存储',
      history: '历史',
      popover: '菜单栏弹出窗口',
      settings: '设置',
    },
  },
  download: {
    eyebrow: '下载',
    title: '下载 iSensa',
    intro: '发布在 GitHub Releases，每个版本都附有源代码。',
    loading: '正在查询 GitHub 上的最新版本…',
    version: '版本 {version}',
    stable: '稳定版',
    beta: '测试版',
    released: '发布日期',
    size: '大小',
    architecture: '架构',
    checksum: 'SHA-256',
    copy: '复制',
    copied: '已复制',
    notes: '版本说明',
    allReleases: '所有版本',
    source: '源代码',
    buttonMac: '下载 macOS 版',
    buttonOther: '查看 macOS 版下载',
    noReleaseTitle: '首个公开版本即将推出',
    noReleaseText: '目前还没有可下载的版本。关注仓库以获知发布时间，或从源代码构建 iSensa。',
    errorText: '暂时无法连接 GitHub。版本页面列出了所有版本。',
    notMac: 'iSensa 专为 macOS 打造。你仍然可以浏览它的版本或阅读源代码。',
    archUnknown: '请参阅版本说明',
    installTitle: '安装',
    install: [
      '打开下载的磁盘映像。',
      '将 iSensa 拖到“应用程序”文件夹。',
      '打开 iSensa。目前版本尚未使用 Apple Developer ID 签名，所以首次打开时 macOS 会要求确认：打开“系统设置”›“隐私与安全性”，然后选择“仍要打开”。',
    ],
    license: 'MIT 许可证',
  },
  requirements: {
    title: '系统要求',
    items: {
      macos: { label: '系统', value: 'macOS 14 Sonoma 或更高版本' },
      chip: { label: '处理器', value: '搭载 Apple 芯片的 Mac。已在 M3 Pro 上测试；在其他 Mac 上，部分传感器可能没有易懂的名称。' },
      intel: { label: '搭载 Intel 的 Mac', value: '当前版本不支持。' },
      space: { label: '磁盘空间', value: '小于 20 MB' },
      permissions: {
        label: '权限',
        value: '查看 Mac 的读数无需任何权限。可选：用于提醒的通知、用于查找磁盘占用的文件夹访问权限，以及开启风扇控制所需的密码。',
      },
    },
    limitations: 'iSensa 能显示的内容取决于你的 Mac。风扇控制为实验性功能，仅适用于配有风扇的 Mac。部分数值为估算值，并会注明。',
  },
  openSource: {
    eyebrow: '开源',
    title: '开源，并如实对待数据',
    text: 'iSensa 免费且开源。任何人都可以在 GitHub 上查看它的工作原理、提出修改建议并帮助改进。',
    principles: {
      honest: { title: '绝不编造', text: '只有 iSensa 确定传感器是什么时，才会给它命名。估算值会标为估算值。' },
      local: { title: '数据不离开你的 Mac', text: 'iSensa 不使用互联网。你的历史记录留在你的 Mac 上。' },
      safe: { title: '审慎对待硬件', text: '风扇控制是可选的，一旦发现异常，就会立即把控制权交还给 macOS。' },
    },
    explore: '在 GitHub 上探索',
    stats: { stars: '星标', forks: '复刻', issues: '未解决议题', release: '最新版本', none: '暂无' },
    links: {
      issues: '议题',
      pulls: '拉取请求',
      releases: '版本',
      docs: '文档',
      contributing: '贡献指南',
      security: '安全策略',
      license: '许可证',
    },
  },
  footer: {
    tagline: '一款如实呈现测量结果的 macOS 原生硬件监视器。',
    product: '产品',
    project: '项目',
    legal: '法律信息',
    terms: '使用条款',
    privacy: '隐私政策',
    latest: '最新版本：{version}',
    noRelease: '尚无公开版本',
    openSource: '以 MIT 许可证开源。',
    trademark: 'Mac 和 macOS 是 Apple Inc. 的商标。iSensa 与 Apple 无关。',
  },
  notFound: {
    title: '此页面不存在',
    text: '地址可能输入有误，或者页面已移动。',
    home: '前往首页',
  },
  legal: {
    draft: '待法律审核的草稿。本文描述了项目目前的运作方式，但尚未经过律师审阅。',
    updated: '最后更新：{date}',
    back: '返回首页',
    terms: {
      title: '使用条款',
      description: '使用 iSensa 及其网站的条件。',
      sections: [
        {
          heading: '关于 iSensa',
          body: [
            'iSensa 是一款开源应用程序，用于监视和诊断 Mac 电脑的硬件，并可在兼容机型上控制风扇转速。它由独立贡献者开发，发布于 github.com/steinertruthy/isensa。',
          ],
        },
        {
          heading: '许可证',
          body: [
            '源代码和已发布的版本均以 MIT 许可证分发。只要保留版权声明和许可声明，该许可证允许使用、复制、修改、合并、发布、分发、再许可和销售本软件的副本。如本条款与许可证在软件方面有出入，以许可证为准。',
          ],
        },
        {
          heading: '软件的使用',
          body: [
            '你可以将 iSensa 用于个人或工作用途。你需对使用方式负责，包括对硬件设置所做的任何更改，以及通过“释放空间”分析选择移到废纸篓的任何文件。',
          ],
        },
        {
          heading: '监视及其局限',
          body: [
            '读数来自 macOS 和 Mac 硬件提供的接口，其中一些没有公开文档。其可用性和精度因机型和 macOS 版本而异，更新后可能变化或失效。iSensa 会标明估算值和推算值，但任何读数都不应视为经过认证的测量结果。',
          ],
        },
        {
          heading: '风扇控制与特权组件',
          body: [
            '风扇控制为实验性功能。它需要安装一个以管理员权限运行的辅助程序，由你用密码授权。辅助程序会验证每条命令，遵守硬件报告的转速限制，并在应用停止响应或读数失败时将风扇交还自动控制。即便如此，改变风扇行为仍会影响温度和噪音；使用风险由你自行承担，你也可以随时卸载辅助程序。',
          ],
        },
        {
          heading: '无担保',
          body: [
            '本软件按“原样”提供，不附带任何明示或暗示的担保，包括但不限于适销性、特定用途适用性和不侵权的担保。在适用法律允许的范围内，作者和贡献者不对因本软件或其使用而产生的任何索赔、损害或其他责任负责。某些司法管辖区不允许此类免责；在这种情况下，它们在法律允许的范围内适用。',
          ],
        },
        {
          heading: '知识产权',
          body: [
            'iSensa 名称及其图标用于标识本项目。贡献内容按照项目许可证接受。Mac 和 macOS 是 Apple Inc. 的商标；iSensa 与 Apple 无关联，也未获得 Apple 的认可或赞助。',
          ],
        },
        {
          heading: '条款变更',
          body: [
            '本条款可能会随项目发展而变更。变更将发布在此页面并记录在仓库历史中，最后更新日期显示在上方。',
          ],
        },
        {
          heading: '联系方式',
          body: ['关于本条款的问题，可以在 GitHub 仓库中提交议题。'],
        },
      ],
    },
    privacy: {
      title: '隐私政策',
      description: 'iSensa 网站和应用如何处理数据。',
      sections: [
        {
          heading: '摘要',
          body: [
            'iSensa 应用完全在你的 Mac 上运行，不建立任何网络连接。本网站不使用 Cookie，也不使用分析工具。能看到你请求的是 GitHub 的服务，详见下文。',
          ],
        },
        {
          heading: '网站',
          body: [
            '本网站由 GitHub Pages 托管。为了显示最新版本和仓库统计信息，你的浏览器会向 GitHub API（api.github.com）请求公开信息。下载内容由 GitHub 提供。与任何网络服务器一样，GitHub 会在这些请求中收到你的 IP 地址和浏览器信息，并依据 GitHub 隐私声明处理。',
            '网站会在浏览器的本地存储中记住你选择的语言和外观。这些信息只保存在你的设备上，不会发送到任何地方，你可以随时在浏览器设置中清除。',
          ],
        },
        {
          heading: '应用',
          body: [
            'iSensa 读取 Mac 的硬件和系统信息（如使用率、温度、电池和存储）以便显示。历史记录和偏好设置只保存在你的 Mac 上，位于 ~/Library/Application Support/iSensa 和应用偏好设置中，你可以在设置中导出或删除。',
            '“释放空间”分析只在你启动时读取文件夹和文件的大小与名称，从不读取其内容。macOS 可能会请求访问某些文件夹的权限；你可以拒绝，或在“系统设置”中撤销。',
            '通知由 macOS 在本地创建。应用不包含任何分析、广告或崩溃报告服务。',
          ],
        },
        {
          heading: '保留与安全',
          body: [
            '应用会在短期内保留详细历史记录，并按设置中选择的天数保留摘要。项目维护者不保存任何数据，因为没有任何数据发送给他们。',
          ],
        },
        {
          heading: '你的权利',
          body: [
            '由于本项目不收集个人数据，它不持有任何可供你访问、更正或删除的数据。对于 GitHub 处理的数据，你可以依据其隐私声明向 GitHub 行使权利。根据你所在的地区，《个人信息保护法》等法律可能赋予你更多权利。',
          ],
        },
        {
          heading: '变更',
          body: ['如果网站或应用开始以不同方式处理数据，本政策将在该变更发布之前更新。'],
        },
        {
          heading: '联系方式',
          body: ['关于隐私的问题，可以在 GitHub 仓库中提交议题。'],
        },
      ],
    },
  },
};

export default zhHans;
