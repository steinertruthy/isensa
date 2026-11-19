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
    subtitle: '精确的读数、清楚的解释和审慎的硬件控制，尽在一款为 macOS 打造的原生应用。',
    download: '下载 macOS 版',
    github: '在 GitHub 上查看',
    openSource: '免费开源，采用 MIT 许可证。',
    videoLabel: '在 MacBook Pro 上运行的 iSensa：概览、温度、历史和 CPU 屏幕，显示实时读数。',
    pause: '暂停视频',
    play: '播放视频',
  },
  tour: {
    title: 'iSensa 一分钟',
    text: '录制于一台搭载 M3 Pro 的 14 英寸 MacBook Pro。屏幕上的每个数值都是那台 Mac 的实时读数，没有任何摆拍或后期添加。',
    play: '播放导览',
    label: 'iSensa 导览：概览、CPU、GPU、温度、电池、风扇、内存、历史、设置和菜单栏弹出窗口。',
    unsupported: '你的浏览器无法播放此视频。',
    download: '下载视频（MP4）',
  },
  status: {
    available: '可用',
    experimental: '实验性',
    varies: '视 Mac 而定',
  },
  features: {
    title: '你的 Mac 在做什么，一目了然。',
    intro: '每个组件在各处都保持同一种颜色，每个数字都附有一句话，告诉你是否正常。',
    items: {
      realtime: {
        title: '实时，不嘈杂',
        text: 'CPU、GPU、内存、功耗和网络每秒更新。性能核心和能效核心分开显示，内存按压力来判断，和 macOS 的做法一致，而不是看它显得有多满。',
        alt: '概览：一句状态摘要、CPU 和 GPU 的实时波形，以及 CPU、GPU、内存、温度、功耗和风扇的卡片。',
      },
      thermals: {
        title: '值得信赖的温度',
        text: 'iSensa 读取 Mac 的温度传感器，只有在该机型上验证过的传感器才会被命名。无法识别的传感器保留原始键名，而不是猜一个名字。可用的传感器取决于 Mac 机型。',
        alt: '温度屏幕，显示 CPU、GPU、SSD 和电池读数及温度图表。',
      },
      battery: {
        title: '用简单的话说清电池健康',
        text: '电量、健康状况、循环次数、设计容量和满充容量、电压、电流、充电器功率，以及 macOS 报告的剩余时间。',
        alt: '电池屏幕，显示电量、健康状况、循环次数和充电详情。',
      },
      fans: {
        title: '风扇：随时查看，需要时亲自掌控',
        text: '显示每个风扇的转速和范围。在配有风扇的 Mac 上，实验性控制提供固定转速和曲线。它需要用管理员密码安装一个小型辅助程序，一旦出现异常就会把风扇交还给 macOS。',
        alt: '风扇屏幕，显示两个处于自动控制的风扇和安装辅助程序的选项。',
      },
      storage: {
        title: '说得清为什么满了的存储',
        text: '已用、可清除和可用空间，磁盘速度，由硬盘自身报告的 SSD 健康状况，以及“释放空间”分析：找出最大的文件夹、文件和应用，把你选中的移到废纸篓。',
        alt: '存储屏幕，显示磁盘用量、可清除空间、本地快照和“释放空间”入口。',
      },
      history: {
        title: '能发现规律的历史记录',
        text: '在 Mac 上保存三十天的读数，可查看最近一小时到最近一个月。比较不同时段，导出为 CSV 或 JSON，并阅读关于同步变化的简短说明。',
        alt: '历史屏幕，显示 CPU、GPU、内存压力、温度和风扇的 24 小时图表。',
      },
      settings: {
        title: '按你的方式',
        text: '选择菜单栏指示器及其顺序、概览卡片、单位、刷新频率、需持续一段时间才会提醒的阈值警报、外观和语言。',
        alt: '设置窗口的“通用”面板。',
      },
      native: {
        title: '彻头彻尾的原生体验',
        text: '使用 SwiftUI 和 AppKit 为 macOS 14 及更高版本打造，支持浅色和深色模式、十种语言、VoiceOver 标签和键盘导航。窗口隐藏时降低采样频率，Mac 睡眠时暂停。',
        alt: '内存屏幕，显示内存压力、按类型划分的用量和内存图表。',
      },
    },
  },
  menubar: {
    title: '在菜单栏里看你的 Mac',
    text: '把关心的数字放在时钟旁边，以文字或小图表显示。点按一下就能看到全貌，窗口保持关闭。',
    points: [
      '选择指示器、它们的顺序，以及是否显示图表。',
      '菜单栏拥挤时，可将两个指示器叠放在一列中。',
      '只显示菜单栏时，iSensa 会降低刷新频率以节省电量。',
    ],
    statusAlt: '菜单栏中的 iSensa，显示 CPU 使用率和温度。',
    popoverAlt: 'iSensa 弹出窗口，显示 CPU、GPU、温度、内存、电池、功耗、风扇和网络读数。',
  },
  gallery: {
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
      chip: { label: '处理器', value: 'Apple 芯片。已在 M3 Pro 上验证；在其他芯片上，部分传感器可能以原始名称显示。' },
      intel: { label: '搭载 Intel 的 Mac', value: '当前版本不支持。' },
      space: { label: '磁盘空间', value: '小于 20 MB' },
      permissions: {
        label: '权限',
        value: '监视无需任何权限。可选：用于警报的通知、用于“释放空间”分析的文件夹访问权限，以及安装风扇辅助程序所需的管理员密码。',
      },
    },
    limitations: '可用的传感器和控制取决于 Mac 机型。风扇控制为实验性功能，仅适用于配有风扇的 Mac。频率和功耗由系统计数器推算得出，并会注明。',
  },
  openSource: {
    title: '开源，并如实对待数据',
    text: 'iSensa 是自由软件。每个读数、每条规则和屏幕上的每个字都可以在 GitHub 上阅读、质疑和改进。',
    principles: {
      honest: { title: '不编造名称', text: '传感器只有在该机型上验证后才会被命名。估算值和推算值都会注明。' },
      local: { title: '数据不离开你的 Mac', text: '应用不建立任何网络连接。历史记录保存在你 Mac 上的一个文件中。' },
      safe: { title: '审慎对待硬件', text: '风扇控制经过双重验证，拥有独立的安全上限，出现任何故障都会把风扇交还给 macOS。' },
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
