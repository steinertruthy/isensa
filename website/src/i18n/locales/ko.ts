import type { Dictionary } from './en';

const ko: Dictionary = {
  meta: {
    title: 'iSensa — macOS용 하드웨어 모니터',
    description:
      'iSensa는 CPU, GPU, 메모리, 온도, 배터리, 팬, 저장 공간을 실시간으로 보여 주고, 값의 의미와 각 숫자의 출처를 알려 주는 무료 오픈 소스 Mac 앱입니다.',
    ogAlt: 'MacBook Pro의 개요를 보여 주는 iSensa 윈도우와 실시간 CPU·GPU 그래프.',
  },
  nav: {
    skip: '본문으로 건너뛰기',
    overview: '개요',
    features: '기능',
    gallery: '갤러리',
    download: '다운로드',
    openSource: '오픈 소스',
    github: 'GitHub의 iSensa',
    menu: '메뉴',
    closeMenu: '메뉴 닫기',
    language: '언어',
    theme: '화면 모드',
    themeSystem: '자동',
    themeLight: '라이트',
    themeDark: '다크',
    home: 'iSensa 홈',
  },
  hero: {
    title: 'Mac을 알아보세요.\n구석구석까지.',
    subtitle: 'Mac이 지금 무엇을 하는지 보고, 쉬운 말로 이해하세요. macOS를 위해 만든 무료 앱입니다.',
    download: 'macOS용 다운로드',
    github: 'GitHub에서 보기',
    openSource: 'MIT 라이선스의 무료 오픈 소스입니다.',
    eyebrow: '모니터링 · 센서 · 제어',
    howItWorks: '작동 방식 보기',
    detected: '감지된 시스템: {os}',
    platform: 'Apple 실리콘과 macOS 14 이상을 사용하는 Mac용',
    screenAlt: 'M3 Pro를 탑재한 MacBook Pro의 iSensa 개요 화면: Mac 상태, 실시간 CPU·GPU 그래프와 구성 요소별 타일.',
  },
  overview: {
    eyebrow: '개요',
    title: 'Mac 안의 모든 것을 하나의 윈도우에.',
    text: '프로세서, 그래픽, 메모리, 온도, 배터리, 팬, 저장 공간, 네트워크까지 모두 한곳에서 쉽게 설명해 드립니다. 윈도우에서도, 메뉴 막대에서도.',
    pillars: {
      native: { title: 'Mac의 일부처럼', text: 'Mac에 기본으로 들어 있는 앱처럼 보이고 동작합니다. 라이트 모드와 다크 모드 모두.' },
      honest: { title: '전문 용어 대신 쉬운 말로', text: '모든 숫자에 짧은 설명이 붙어 있어, 무엇에 신경 써야 하는지 바로 알 수 있습니다.' },
      safe: { title: 'Mac에 가볍게', text: '전력을 거의 쓰지 않고, 보고 있지 않을 때는 속도를 줄입니다.' },
    },
  },
  spectrum: {
    cpu: 'CPU',
    gpu: 'GPU',
    memory: '메모리',
    thermal: '온도',
    power: '전력',
    battery: '배터리',
    fans: '팬',
    network: '네트워크',
    storage: '저장 공간',
  },
  status: {
    available: '사용 가능',
    experimental: '실험적',
    varies: 'Mac에 따라 다름',
  },
  features: {
    eyebrow: '기능',
    whyLabel: '이런 점이 좋아요',
    title: 'Mac이 하는 모든 일을 알기 쉽게.',
    intro: 'Mac의 각 부분은 고유한 색을 가지고, 모든 숫자는 정상인지 알려 줍니다.',
    items: {
      realtime: {
        title: '실시간으로, 군더더기 없이',
        text: 'Mac이 지금 얼마나 일하고 있는지, 무엇 때문에 바쁜지 한눈에 확인하세요.',
        alt: '개요 화면: 상태를 요약한 문장, CPU와 GPU의 실시간 파형, CPU·GPU·메모리·온도·전력·팬 타일.',
        label: '실시간',
        why: '활성 상태 보기를 열지 않고도 Mac을 느리게 만드는 원인을 몇 초 만에 찾습니다.',
      },
      thermals: {
        title: '믿을 수 있는 온도',
        text: '프로세서, 그래픽, SSD, 배터리가 얼마나 따뜻한지 알 수 있습니다. iSensa는 무엇을 측정하는지 확실히 아는 센서에만 이름을 붙입니다. 보이는 내용은 Mac에 따라 다릅니다.',
        alt: '온도 화면: CPU, GPU, SSD, 배터리 값과 온도 그래프.',
        label: '온도',
        why: '성능이 제한되기 전에 Mac이 그냥 따뜻한지 정말 뜨거운지 알 수 있습니다.',
      },
      battery: {
        title: '배터리 상태를 쉬운 말로',
        text: '충전량, 상태, 지금까지의 충전 사이클, 그리고 충전기가 실제로 공급하는 전력.',
        alt: '배터리 화면: 충전량, 상태, 사이클 수, 충전 세부 정보.',
        label: '배터리',
        why: '배터리가 어떻게 노화되는지, 충전기가 실제로 얼마나 공급하는지 이해할 수 있습니다.',
      },
      fans: {
        title: '팬: 지켜보거나 직접 조절하거나',
        text: '팬마다 얼마나 빨리 도는지 보여 줍니다. 팬이 있는 Mac에서는 더 조용하거나 더 시원한 설정을 고를 수도 있습니다. 선택 사항인 실험적 기능이며, 문제가 보이면 즉시 macOS에 제어를 돌려줍니다.',
        alt: '팬 화면: 자동 제어로 도는 팬 두 개와 도우미 설치 옵션.',
        label: '팬',
        why: '통화 중에는 조용하게, 긴 렌더링 중에는 시원하게. 자동 보호 장치가 함께합니다.',
      },
      storage: {
        title: '디스크를 채우는 것을 찾아보세요',
        text: '사용 중인 공간과 남은 공간, SSD 상태를 확인하고 가장 큰 폴더, 파일, 앱을 찾으세요. 휴지통으로 가는 것은 직접 고른 항목뿐입니다.',
        alt: '저장 공간 화면: 디스크 사용량, 제거 가능 공간, 로컬 스냅샷, 공간 확보 진입점.',
        label: '저장 공간',
        why: '어떤 파일을 지워도 안전한지 추측하지 않고 기가바이트 단위의 공간을 되찾습니다.',
      },
      history: {
        title: '패턴을 찾아내는 기록',
        text: '지난 1시간부터 지난 한 달까지 돌아볼 수 있습니다. Mac이 열심히 일할 때 온도가 오르는 것처럼, 함께 변한 것을 알려 줍니다.',
        alt: '기록 화면: CPU, GPU, 메모리 압력, 온도, 팬의 24시간 그래프.',
        label: '기록',
        why: '어제 느려진 원인이 열인지, 메모리인지, 디스크인지 확인하세요.',
      },
      settings: {
        title: '내 방식대로',
        text: '메뉴 막대와 개요에 보일 항목을 고르고, 값이 너무 오래 높게 유지되면 알림을 받고, 모양과 언어를 선택하세요.',
        alt: '설정 윈도우의 일반 패널.',
        label: '설정',
        why: '신경 쓰는 숫자만 원하는 곳에 두세요.',
      },
      native: {
        title: 'Mac을 위해 만든',
        text: '라이트와 다크 모드, 10개 언어, VoiceOver와 키보드가 기대한 대로 작동합니다. 보고 있지 않을 때는 배터리를 아끼려고 속도를 줄입니다.',
        alt: '메모리 화면: 메모리 압력, 유형별 사용량, 메모리 그래프.',
        label: '네이티브',
        why: 'macOS의 일부처럼 느껴지고 작업을 방해하지 않습니다.',
      },
    },
  },
  menubar: {
    eyebrow: '메뉴 막대',
    title: '메뉴 막대에서 보는 Mac',
    text: '관심 있는 숫자를 시계 옆에 두세요. 클릭 한 번이면 윈도우를 열지 않고도 나머지를 모두 볼 수 있습니다.',
    points: [
      '보여 줄 숫자와 순서를 텍스트나 작은 그래프로 고르세요.',
      '공간이 부족한가요? 두 숫자를 한자리에 모아 보세요.',
      '메뉴 막대만 보일 때는 업데이트를 줄여 전력을 아낍니다.',
    ],
    statusAlt: '메뉴 막대의 iSensa가 CPU 사용률과 온도를 표시하는 모습.',
    popoverAlt: 'CPU, GPU, 온도, 메모리, 배터리, 전력, 팬, 네트워크 값을 보여 주는 iSensa 팝오버.',
  },
  gallery: {
    eyebrow: '갤러리',
    title: '갤러리',
    intro: 'M3 Pro를 탑재한 MacBook Pro에서 실행 중인 iSensa 화면입니다.',
    previous: '이전 스크린샷',
    next: '다음 스크린샷',
    open: '스크린샷 확대',
    close: '닫기',
    counter: '{total}개 중 {current}',
    items: {
      overview: '개요',
      cpu: 'CPU',
      gpu: 'GPU',
      memory: '메모리',
      battery: '배터리',
      thermals: '온도',
      sensors: '센서',
      fans: '팬',
      storage: '저장 공간',
      history: '기록',
      popover: '메뉴 막대 팝오버',
      settings: '설정',
    },
  },
  download: {
    eyebrow: '다운로드',
    title: 'iSensa 다운로드',
    intro: 'GitHub Releases에 게시되며, 모든 버전의 소스 코드를 함께 제공합니다.',
    loading: 'GitHub에서 최신 버전을 확인하는 중…',
    version: '버전 {version}',
    stable: '정식',
    beta: '베타',
    released: '출시일',
    size: '크기',
    architecture: '아키텍처',
    checksum: 'SHA-256',
    copy: '복사',
    copied: '복사됨',
    notes: '릴리스 노트',
    allReleases: '모든 릴리스',
    source: '소스 코드',
    buttonMac: 'macOS용 다운로드',
    buttonOther: 'macOS용 다운로드 보기',
    noReleaseTitle: '첫 공개 버전을 준비하고 있습니다',
    noReleaseText: '아직 다운로드할 수 있는 버전이 없습니다. 저장소를 팔로우해 출시 소식을 받거나 소스 코드로 iSensa를 빌드하세요.',
    errorText: '지금은 GitHub에 연결할 수 없습니다. 릴리스 페이지에서 모든 버전을 볼 수 있습니다.',
    notMac: 'iSensa는 macOS용입니다. 릴리스를 둘러보거나 소스 코드를 읽어 볼 수는 있습니다.',
    archUnknown: '릴리스 노트 참고',
    installTitle: '설치',
    install: [
      '다운로드한 디스크 이미지를 엽니다.',
      'iSensa를 응용 프로그램 폴더로 드래그합니다.',
      'iSensa를 엽니다. 아직 Apple Developer ID로 서명되지 않아 처음에는 macOS가 확인을 요청합니다. 시스템 설정 › 개인정보 보호 및 보안에서 그래도 열기를 선택하세요.',
    ],
    license: 'MIT 라이선스',
  },
  requirements: {
    title: '시스템 요구 사항',
    items: {
      macos: { label: '시스템', value: 'macOS 14 Sonoma 이상' },
      chip: { label: '프로세서', value: 'Apple 실리콘 Mac. M3 Pro에서 테스트했으며, 다른 Mac에서는 일부 센서가 알기 쉬운 이름 없이 표시될 수 있습니다.' },
      intel: { label: 'Intel 기반 Mac', value: '현재 버전에서는 지원하지 않습니다.' },
      space: { label: '디스크 공간', value: '20MB 미만' },
      permissions: {
        label: '권한',
        value: 'Mac의 수치를 보는 데는 필요 없음. 선택 사항: 알림, 디스크를 채우는 항목을 찾기 위한 폴더 접근, 팬 제어를 켜기 위한 암호.',
      },
    },
    limitations: 'iSensa가 보여 줄 수 있는 내용은 Mac에 따라 다릅니다. 팬 제어는 실험적 기능이며 팬이 있는 Mac에만 있습니다. 일부 값은 추정값이며 그렇게 표시됩니다.',
  },
  openSource: {
    eyebrow: '오픈 소스',
    title: '오픈 소스, 그리고 데이터에 정직하게',
    text: 'iSensa는 무료 오픈 소스입니다. 누구나 GitHub에서 작동 방식을 보고, 변경을 제안하고, 더 좋게 만드는 데 참여할 수 있습니다.',
    principles: {
      honest: { title: '지어낸 것은 없습니다', text: 'iSensa가 정체를 확신할 때만 센서에 이름을 붙입니다. 추정값은 추정값으로 표시합니다.' },
      local: { title: 'Mac 밖으로 나가지 않습니다', text: 'iSensa는 인터넷을 사용하지 않습니다. 기록은 Mac에 남습니다.' },
      safe: { title: '하드웨어를 신중하게', text: '팬 제어는 선택 사항이며, 문제가 보이는 즉시 macOS에 제어를 돌려줍니다.' },
    },
    explore: 'GitHub에서 살펴보기',
    stats: { stars: '스타', forks: '포크', issues: '열린 이슈', release: '최신 릴리스', none: '아직 없음' },
    links: {
      issues: '이슈',
      pulls: '풀 리퀘스트',
      releases: '릴리스',
      docs: '문서',
      contributing: '기여 가이드',
      security: '보안 정책',
      license: '라이선스',
    },
  },
  footer: {
    tagline: '측정하는 것에 정직한 macOS용 네이티브 하드웨어 모니터.',
    product: '제품',
    project: '프로젝트',
    legal: '법적 고지',
    terms: '이용 약관',
    privacy: '개인정보 처리방침',
    latest: '최신 릴리스: {version}',
    noRelease: '아직 공개 버전이 없습니다',
    openSource: 'MIT 라이선스의 오픈 소스입니다.',
    trademark: 'Mac과 macOS는 Apple Inc.의 상표입니다. iSensa는 Apple과 관련이 없습니다.',
  },
  notFound: {
    title: '존재하지 않는 페이지입니다',
    text: '주소가 잘못되었거나 페이지가 이동했을 수 있습니다.',
    home: '홈으로 이동',
  },
  legal: {
    draft: '법률 검토용 초안입니다. 현재 프로젝트가 작동하는 방식을 설명하지만 아직 변호사의 검토를 받지 않았습니다.',
    updated: '최종 업데이트: {date}',
    back: '홈으로 돌아가기',
    terms: {
      title: '이용 약관',
      description: 'iSensa와 웹사이트를 이용하기 위한 조건.',
      sections: [
        {
          heading: 'iSensa 소개',
          body: [
            'iSensa는 Mac 컴퓨터의 하드웨어를 모니터링하고 진단하며, 호환되는 모델에서는 팬 속도를 제어할 수 있는 오픈 소스 애플리케이션입니다. 독립적인 기여자들이 개발하며 github.com/steinertruthy/isensa에 공개되어 있습니다.',
          ],
        },
        {
          heading: '라이선스',
          body: [
            '소스 코드와 공개된 빌드는 MIT 라이선스로 배포됩니다. 저작권 고지와 허가 고지를 유지하는 한 소프트웨어를 사용, 복제, 수정, 병합, 게시, 배포, 재라이선스, 판매할 수 있습니다. 소프트웨어에 관해 본 약관과 라이선스가 다를 경우 라이선스가 우선합니다.',
          ],
        },
        {
          heading: '소프트웨어 이용',
          body: [
            'iSensa는 개인적 또는 업무 목적으로 사용할 수 있습니다. 하드웨어 설정 변경과 공간 확보 분석으로 휴지통에 옮기기로 한 파일을 포함해, 사용 방식에 대한 책임은 사용자에게 있습니다.',
          ],
        },
        {
          heading: '모니터링과 그 한계',
          body: [
            '수치는 macOS와 Mac 하드웨어가 제공하는 인터페이스에서 가져오며, 그중 일부는 공개 문서가 없습니다. 사용 가능 여부와 정확도는 모델과 macOS 버전에 따라 다르고, 업데이트 후 바뀌거나 작동하지 않을 수 있습니다. iSensa는 추정값과 계산값을 표시하지만, 어떤 수치도 공인된 측정값으로 간주해서는 안 됩니다.',
          ],
        },
        {
          heading: '팬 제어와 권한이 있는 구성 요소',
          body: [
            '팬 제어는 실험적 기능입니다. 관리자 권한으로 실행되는 도우미를 설치해야 하며, 사용자가 암호로 허가합니다. 도우미는 모든 명령을 검증하고, 하드웨어가 알려 주는 속도 한계를 지키며, 앱이 응답하지 않거나 수치를 읽지 못하면 팬을 자동 제어로 되돌립니다. 그래도 팬 동작을 바꾸면 온도와 소음에 영향을 주므로 사용에 따른 책임은 사용자에게 있으며, 도우미는 언제든 제거할 수 있습니다.',
          ],
        },
        {
          heading: '보증의 부인',
          body: [
            '소프트웨어는 상품성, 특정 목적 적합성, 비침해에 대한 보증을 포함해 명시적이든 묵시적이든 어떠한 보증 없이 "있는 그대로" 제공됩니다. 관련 법률이 허용하는 범위에서 저자와 기여자는 소프트웨어나 그 사용으로 인해 발생하는 어떠한 청구, 손해, 기타 책임도 지지 않습니다. 이러한 면책을 허용하지 않는 지역에서는 법이 허용하는 범위까지 적용됩니다.',
          ],
        },
        {
          heading: '지식재산',
          body: [
            'iSensa라는 이름과 아이콘은 이 프로젝트를 나타냅니다. 기여는 프로젝트 라이선스에 따라 받습니다. Mac과 macOS는 Apple Inc.의 상표이며, iSensa는 Apple과 제휴하거나 Apple의 승인 또는 후원을 받지 않았습니다.',
          ],
        },
        {
          heading: '약관 변경',
          body: [
            '본 약관은 프로젝트의 발전에 따라 바뀔 수 있습니다. 변경 사항은 이 페이지에 게시되고 저장소 기록에 남으며, 최종 업데이트 날짜는 위에 표시됩니다.',
          ],
        },
        {
          heading: '문의',
          body: ['본 약관에 관한 질문은 GitHub 저장소에 이슈로 남겨 주세요.'],
        },
      ],
    },
    privacy: {
      title: '개인정보 처리방침',
      description: 'iSensa 웹사이트와 앱이 데이터를 다루는 방식.',
      sections: [
        {
          heading: '요약',
          body: [
            'iSensa 앱은 전적으로 Mac 안에서 동작하며 네트워크에 연결하지 않습니다. 이 사이트는 쿠키나 분석 도구를 사용하지 않습니다. 요청을 받는 서비스는 아래에 설명한 GitHub의 서비스입니다.',
          ],
        },
        {
          heading: '웹사이트',
          body: [
            '이 사이트는 GitHub Pages에서 호스팅됩니다. 최신 버전과 저장소 통계를 보여 주기 위해 브라우저가 GitHub API(api.github.com)에 공개 정보를 요청합니다. 다운로드는 GitHub에서 제공합니다. 다른 웹 서버와 마찬가지로 GitHub는 이 요청과 함께 IP 주소와 브라우저 정보를 받으며, GitHub 개인정보 보호정책에 따라 처리합니다.',
            '사이트는 선택한 언어와 화면 모드를 브라우저의 로컬 저장소에 기억합니다. 이 정보는 기기에만 남고 어디로도 전송되지 않으며, 브라우저 설정에서 언제든 지울 수 있습니다.',
          ],
        },
        {
          heading: '앱',
          body: [
            'iSensa는 화면에 표시하기 위해 Mac의 하드웨어와 시스템 정보(사용량, 온도, 배터리, 저장 공간 등)를 읽습니다. 기록과 환경설정은 Mac의 ~/Library/Application Support/iSensa와 앱 환경설정에만 저장되며, 설정에서 내보내거나 삭제할 수 있습니다.',
            '공간 확보 분석은 사용자가 시작했을 때만 폴더와 파일의 크기와 이름을 읽으며, 내용은 읽지 않습니다. macOS가 일부 폴더 접근 권한을 요청할 수 있으며, 거부하거나 시스템 설정에서 철회할 수 있습니다.',
            '알림은 macOS가 로컬에서 만듭니다. 앱에는 분석, 광고, 충돌 보고 서비스가 없습니다.',
          ],
        },
        {
          heading: '보관 기간과 보안',
          body: [
            '앱은 상세 기록을 짧은 기간 동안, 요약을 설정에서 고른 일수 동안 보관합니다. 프로젝트 관리자에게는 아무것도 전송되지 않으므로 관리자가 보관하는 데이터는 없습니다.',
          ],
        },
        {
          heading: '사용자의 권리',
          body: [
            '프로젝트는 개인정보를 수집하지 않으므로 열람, 정정, 삭제할 데이터를 보유하고 있지 않습니다. GitHub가 처리하는 데이터는 GitHub의 개인정보 보호정책에 따라 GitHub에 권리를 행사할 수 있습니다. 거주 지역에 따라 개인정보 보호법 등에서 추가 권리를 보장할 수 있습니다.',
          ],
        },
        {
          heading: '변경',
          body: ['웹사이트나 앱의 데이터 처리 방식이 바뀌면, 그 변경을 공개하기 전에 이 방침을 업데이트합니다.'],
        },
        {
          heading: '문의',
          body: ['개인정보에 관한 질문은 GitHub 저장소에 이슈로 남겨 주세요.'],
        },
      ],
    },
  },
};

export default ko;
