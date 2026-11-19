import type { Dictionary } from './en';

const zhHant: Dictionary = {
  meta: {
    title: 'iSensa — macOS 硬體監視器',
    description:
      'iSensa 是一款免費開源的 Mac App，即時顯示 CPU、GPU、記憶體、溫度、電池、風扇和儲存空間的讀數，說明它們的意義，並標示每個數字的來源。',
    ogAlt: 'iSensa 視窗顯示一台 MacBook Pro 的概覽，附有即時 CPU 和 GPU 圖表。',
  },
  nav: {
    skip: '跳至內容',
    overview: '概覽',
    features: '功能',
    gallery: '截圖',
    download: '下載',
    openSource: '開放原始碼',
    github: 'GitHub 上的 iSensa',
    menu: '選單',
    closeMenu: '關閉選單',
    language: '語言',
    theme: '外觀',
    themeSystem: '自動',
    themeLight: '淺色',
    themeDark: '深色',
    home: 'iSensa 首頁',
  },
  hero: {
    title: '了解你的 Mac，\n每一處細節。',
    subtitle: '看看你的 Mac 正在做什麼，用簡單的話弄明白。一款為 macOS 打造的免費 App。',
    download: '下載 macOS 版',
    github: '在 GitHub 上查看',
    openSource: '免費且開放原始碼，採用 MIT 授權。',
    eyebrow: '監視 · 感測器 · 控制',
    howItWorks: '了解運作方式',
    detected: '偵測到的系統：{os}',
    platform: '適用於搭載 Apple 晶片、執行 macOS 14 或以上版本的 Mac',
    screenAlt: 'iSensa 在搭載 M3 Pro 的 MacBook Pro 上的概覽畫面：Mac 的狀態、即時 CPU 和 GPU 圖表，以及每個元件的卡片。',
  },
  overview: {
    eyebrow: '概覽',
    title: '一個視窗，看清 Mac 內部的一切。',
    text: '處理器、圖形處理器、記憶體、溫度、電池、風扇、儲存空間和網路，全都集中在一處，用簡單的話說明白，在視窗裡或直接在選單列中。',
    pillars: {
      native: { title: '就像 Mac 的一部分', text: '外觀和用法都和 Mac 內建的 App 一樣，支援淺色和深色。' },
      honest: { title: '說白話，不說術語', text: '每個數字都附有一句簡短說明，讓你知道什麼時候需要留意。' },
      safe: { title: '對 Mac 很輕巧', text: '耗電極少，你不看的時候還會放慢節奏。' },
    },
  },
  spectrum: {
    cpu: 'CPU',
    gpu: 'GPU',
    memory: '記憶體',
    thermal: '溫度',
    power: '耗電',
    battery: '電池',
    fans: '風扇',
    network: '網路',
    storage: '儲存空間',
  },
  status: {
    available: '可用',
    experimental: '實驗性',
    varies: '視 Mac 而定',
  },
  features: {
    eyebrow: '功能',
    whyLabel: '有什麼幫助',
    title: '你的 Mac 在做什麼，一目了然。',
    intro: 'Mac 的每個部分都有自己的顏色，每個數字都會告訴你是否正常。',
    items: {
      realtime: {
        title: '即時，不嘈雜',
        text: '一眼看出 Mac 此刻有多忙，以及是什麼讓它忙碌。',
        alt: '概覽：一句狀態摘要、CPU 和 GPU 的即時波形，以及 CPU、GPU、記憶體、溫度、耗電和風扇的卡片。',
        label: '即時',
        why: '幾秒內找出拖慢 Mac 的原因，無需打開活動監視器。',
      },
      thermals: {
        title: '值得信賴的溫度',
        text: '了解處理器、圖形處理器、SSD 和電池有多熱。只有在確切知道感測器測的是什麼時，iSensa 才會為它命名。顯示的內容取決於你的 Mac。',
        alt: '溫度畫面，顯示 CPU、GPU、SSD 和電池讀數及溫度圖表。',
        label: '溫度',
        why: '在 Mac 降低效能之前，就知道它只是有點溫熱還是真的很燙。',
      },
      battery: {
        title: '用簡單的話說清電池健康度',
        text: '電量、健康度、電池已經歷的循環次數，以及充電器實際提供了多少電力。',
        alt: '電池畫面，顯示電量、健康度、循環次數和充電詳細資訊。',
        label: '電池',
        why: '了解電池的老化情況，以及充電器實際提供了多少電力。',
      },
      fans: {
        title: '風扇：隨時查看，也能親自掌控',
        text: '查看每個風扇轉得有多快。在配有風扇的 Mac 上，你還可以選擇更安靜或更涼爽的設定。這是選用的實驗性功能，一旦發現異常就會把控制權交還給 macOS。',
        alt: '風扇畫面，顯示兩個處於自動控制的風扇和安裝輔助程式的選項。',
        label: '風扇',
        why: '通話時保持安靜，長時間算圖時保持涼爽，並有自動保護。',
      },
      storage: {
        title: '找出是什麼塞滿了磁碟',
        text: '查看已使用和可用空間，檢查 SSD 的健康度，找出最大的檔案夾、檔案和 App。只有你選擇的才會移到垃圾桶。',
        alt: '儲存空間畫面，顯示磁碟用量、可清除空間、本機快照和「釋放空間」入口。',
        label: '儲存空間',
        why: '不必猜測哪些檔案可以安全刪除，就能找回數 GB 空間。',
      },
      history: {
        title: '能發現規律的歷史記錄',
        text: '回顧從最近一小時到最近一個月的情況。iSensa 會指出哪些變化是同時發生的，例如 Mac 全力運作時溫度隨之上升。',
        alt: '歷史記錄畫面，顯示 CPU、GPU、記憶體壓力、溫度和風扇的 24 小時圖表。',
        label: '歷史記錄',
        why: '看看昨天變慢是因為溫度、記憶體還是磁碟。',
      },
      settings: {
        title: '照你的方式',
        text: '選擇選單列和概覽中顯示的內容，在某項數值長時間過高時收到提醒，並挑選外觀和語言。',
        alt: '設定視窗的「一般」面板。',
        label: '設定',
        why: '只保留你在意的數字，放在你想要的位置。',
      },
      native: {
        title: '為 Mac 而生',
        text: '淺色與深色、十種語言、VoiceOver 和鍵盤都如你所願地運作。你不看的時候，iSensa 會放慢節奏來節省電力。',
        alt: '記憶體畫面，顯示記憶體壓力、依類型劃分的用量和記憶體圖表。',
        label: '原生',
        why: '感覺就像 macOS 的一部分，不會打擾你的工作。',
      },
    },
  },
  menubar: {
    eyebrow: '選單列',
    title: '在選單列查看你的 Mac',
    text: '把你在意的數字放在時鐘旁邊。按一下就能看到其餘一切，無需打開視窗。',
    points: [
      '選擇要顯示哪些數字以及順序，以文字或小圖表呈現。',
      '空間不夠？把兩個數字放在同一個位置。',
      '只顯示選單列時，iSensa 會減少更新次數以節省電力。',
    ],
    statusAlt: '選單列中的 iSensa，顯示 CPU 使用率和溫度。',
    popoverAlt: 'iSensa 彈出視窗，顯示 CPU、GPU、溫度、記憶體、電池、耗電、風扇和網路讀數。',
  },
  gallery: {
    eyebrow: '截圖',
    title: '截圖',
    intro: '擷取自在搭載 M3 Pro 的 MacBook Pro 上執行的 iSensa。',
    previous: '上一張截圖',
    next: '下一張截圖',
    open: '放大截圖',
    close: '關閉',
    counter: '第 {current} 張，共 {total} 張',
    items: {
      overview: '概覽',
      cpu: 'CPU',
      gpu: 'GPU',
      memory: '記憶體',
      battery: '電池',
      thermals: '溫度',
      sensors: '感測器',
      fans: '風扇',
      storage: '儲存空間',
      history: '歷史記錄',
      popover: '選單列彈出視窗',
      settings: '設定',
    },
  },
  download: {
    eyebrow: '下載',
    title: '下載 iSensa',
    intro: '發佈於 GitHub Releases，每個版本都附有原始碼。',
    loading: '正在查詢 GitHub 上的最新版本…',
    version: '版本 {version}',
    stable: '穩定版',
    beta: 'Beta 版',
    released: '發佈日期',
    size: '大小',
    architecture: '架構',
    checksum: 'SHA-256',
    copy: '拷貝',
    copied: '已拷貝',
    notes: '版本說明',
    allReleases: '所有版本',
    source: '原始碼',
    buttonMac: '下載 macOS 版',
    buttonOther: '查看 macOS 版下載',
    noReleaseTitle: '首個公開版本即將推出',
    noReleaseText: '目前還沒有可下載的版本。追蹤儲存庫以得知發佈時間，或從原始碼建置 iSensa。',
    errorText: '暫時無法連線至 GitHub。版本頁面列出了所有版本。',
    notMac: 'iSensa 專為 macOS 打造。你仍然可以瀏覽它的版本或閱讀原始碼。',
    archUnknown: '請參閱版本說明',
    installTitle: '安裝',
    install: [
      '打開下載的磁碟映像檔。',
      '將 iSensa 拖到「應用程式」檔案夾。',
      '打開 iSensa。目前版本尚未以 Apple Developer ID 簽署，所以第一次打開時 macOS 會要求確認：打開「系統設定」›「隱私權與安全性」，然後選擇「強制打開」。',
    ],
    license: 'MIT 授權',
  },
  requirements: {
    title: '系統需求',
    items: {
      macos: { label: '系統', value: 'macOS 14 Sonoma 或以上版本' },
      chip: { label: '處理器', value: '搭載 Apple 晶片的 Mac。已在 M3 Pro 上測試；在其他 Mac 上，部分感測器可能沒有易懂的名稱。' },
      intel: { label: '搭載 Intel 的 Mac', value: '目前版本不支援。' },
      space: { label: '磁碟空間', value: '小於 20 MB' },
      permissions: {
        label: '權限',
        value: '查看 Mac 的讀數不需要任何權限。選用：用於提醒的通知、用於找出磁碟佔用的檔案夾取用權限，以及開啟風扇控制所需的密碼。',
      },
    },
    limitations: 'iSensa 能顯示的內容取決於你的 Mac。風扇控制為實驗性功能，僅適用於配有風扇的 Mac。部分數值為估計值，並會註明。',
  },
  openSource: {
    eyebrow: '開放原始碼',
    title: '開放原始碼，並如實對待資料',
    text: 'iSensa 免費且開放原始碼。任何人都可以在 GitHub 上查看它的運作方式、提出修改建議並協助改進。',
    principles: {
      honest: { title: '絕不編造', text: '只有 iSensa 確定感測器是什麼時，才會為它命名。估計值會標示為估計值。' },
      local: { title: '資料不離開你的 Mac', text: 'iSensa 不使用網際網路。你的歷史記錄留在你的 Mac 上。' },
      safe: { title: '審慎對待硬體', text: '風扇控制是選用的，一旦發現異常，就會立即把控制權交還給 macOS。' },
    },
    links: {
      issues: '問題',
      pulls: '提取請求',
      releases: '版本',
      docs: '文件',
      contributing: '貢獻指南',
      security: '安全性政策',
      license: '授權',
    },
  },
  footer: {
    tagline: '一款如實呈現測量結果的 macOS 原生硬體監視器。',
    product: '產品',
    project: '專案',
    legal: '法律資訊',
    terms: '使用條款',
    privacy: '隱私權政策',
    latest: '最新版本：{version}',
    noRelease: '尚無公開版本',
    openSource: '以 MIT 授權開放原始碼。',
    trademark: 'Mac 和 macOS 是 Apple Inc. 的商標。iSensa 與 Apple 無關。',
  },
  notFound: {
    title: '此頁面不存在',
    text: '網址可能輸入錯誤，或頁面已移動。',
    home: '前往首頁',
  },
  legal: {
    draft: '待法律審閱的草稿。本文說明專案目前的運作方式，但尚未經過律師審閱。',
    updated: '最後更新：{date}',
    back: '返回首頁',
    terms: {
      title: '使用條款',
      description: '使用 iSensa 及其網站的條件。',
      sections: [
        {
          heading: '關於 iSensa',
          body: [
            'iSensa 是一款開放原始碼應用程式，用於監視和診斷 Mac 電腦的硬體，並可在相容機型上控制風扇轉速。它由獨立貢獻者開發，發佈於 github.com/steinertruthy/isensa。',
          ],
        },
        {
          heading: '授權',
          body: [
            '原始碼和已發佈的版本皆以 MIT 授權散布。只要保留著作權聲明和授權聲明，此授權允許使用、拷貝、修改、合併、發佈、散布、再授權和販售本軟體的副本。若本條款與授權在軟體方面有出入，以授權為準。',
          ],
        },
        {
          heading: '軟體的使用',
          body: [
            '你可以將 iSensa 用於個人或工作用途。你需對使用方式負責，包括對硬體設定所做的任何變更，以及透過「釋放空間」分析選擇移到垃圾桶的任何檔案。',
          ],
        },
        {
          heading: '監視及其限制',
          body: [
            '讀數來自 macOS 和 Mac 硬體提供的介面，其中部分沒有公開文件。其可用性和精確度因機型和 macOS 版本而異，更新後可能改變或失效。iSensa 會標示估計值和推算值，但任何讀數都不應視為經過認證的測量結果。',
          ],
        },
        {
          heading: '風扇控制與特權元件',
          body: [
            '風扇控制為實驗性功能。它需要安裝一個以管理者權限執行的輔助程式，由你以密碼授權。輔助程式會驗證每個命令，遵守硬體回報的轉速限制，並在 App 停止回應或讀數失敗時將風扇交還自動控制。即便如此，改變風扇行為仍會影響溫度和噪音；使用風險由你自行承擔，你也可以隨時解除安裝輔助程式。',
          ],
        },
        {
          heading: '不提供擔保',
          body: [
            '本軟體按「現況」提供，不附帶任何明示或默示的擔保，包括但不限於適售性、特定用途適用性和不侵權的擔保。在適用法律允許的範圍內，作者和貢獻者不對因本軟體或其使用而產生的任何索賠、損害或其他責任負責。某些司法管轄區不允許此類免責；在此情況下，它們在法律允許的範圍內適用。',
          ],
        },
        {
          heading: '智慧財產權',
          body: [
            'iSensa 名稱及其圖像用於識別本專案。貢獻內容依專案授權接受。Mac 和 macOS 是 Apple Inc. 的商標；iSensa 與 Apple 無關聯，亦未獲 Apple 認可或贊助。',
          ],
        },
        {
          heading: '條款變更',
          body: [
            '本條款可能隨專案發展而變更。變更將發佈於此頁面並記錄在儲存庫歷史中，最後更新日期顯示於上方。',
          ],
        },
        {
          heading: '聯絡方式',
          body: ['關於本條款的問題，可以在 GitHub 儲存庫中提交問題。'],
        },
      ],
    },
    privacy: {
      title: '隱私權政策',
      description: 'iSensa 網站和 App 如何處理資料。',
      sections: [
        {
          heading: '摘要',
          body: [
            'iSensa App 完全在你的 Mac 上執行，不建立任何網路連線。本網站不使用 Cookie，也不使用分析工具。能看到你請求的是 GitHub 的服務，詳見下文。',
          ],
        },
        {
          heading: '網站',
          body: [
            '本網站由 GitHub Pages 託管。為了顯示最新版本和儲存庫統計資料，你的瀏覽器會向 GitHub API（api.github.com）請求公開資訊。下載內容由 GitHub 提供。與任何網頁伺服器一樣，GitHub 會在這些請求中收到你的 IP 位址和瀏覽器資訊，並依據 GitHub 隱私權聲明處理。',
            '網站會在瀏覽器的本機儲存空間中記住你選擇的語言和外觀。這些資訊只保存在你的裝置上，不會傳送到任何地方，你可以隨時在瀏覽器設定中清除。',
          ],
        },
        {
          heading: 'App',
          body: [
            'iSensa 讀取 Mac 的硬體和系統資訊（如使用率、溫度、電池和儲存空間）以便顯示。歷史記錄和偏好設定只保存在你的 Mac 上，位於 ~/Library/Application Support/iSensa 和 App 偏好設定中，你可以在設定中匯出或刪除。',
            '「釋放空間」分析只在你啟動時讀取檔案夾和檔案的大小與名稱，從不讀取其內容。macOS 可能會要求取用某些檔案夾的權限；你可以拒絕，或在「系統設定」中撤銷。',
            '通知由 macOS 在本機建立。App 不包含任何分析、廣告或當機報告服務。',
          ],
        },
        {
          heading: '保留與安全性',
          body: [
            'App 會在短期內保留詳細歷史記錄，並依設定中選擇的天數保留摘要。專案維護者不保存任何資料，因為沒有任何資料傳送給他們。',
          ],
        },
        {
          heading: '你的權利',
          body: [
            '由於本專案不收集個人資料，它不持有任何可供你存取、更正或刪除的資料。對於 GitHub 處理的資料，你可以依據其隱私權聲明向 GitHub 行使權利。依你所在的地區，《個人資料保護法》等法律可能賦予你更多權利。',
          ],
        },
        {
          heading: '變更',
          body: ['如果網站或 App 開始以不同方式處理資料，本政策將在該變更發佈之前更新。'],
        },
        {
          heading: '聯絡方式',
          body: ['關於隱私權的問題，可以在 GitHub 儲存庫中提交問題。'],
        },
      ],
    },
  },
};

export default zhHant;
