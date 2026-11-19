# Arquitetura — Sensa

Clean Architecture + MVVM + protocolos + injeção por construtor. Swift 6 (strict concurrency), macOS 14+.

```
App (composition root, AppKit lifecycle)
 ├─ SensaFeatures   telas, presenters, settings, barra de menus   (SwiftUI; nunca importa hardware)
 │   └─ SensaDesign tokens, superfícies, componentes, gráficos
 ├─ SensaMonitoring MonitoringEngine (actor) → MetricsStore (@Observable) → MetricSeries
 ├─ SensaInsights   regras de saúde e AlertEngine (limiar, duração, histerese, repetição) — puros
 ├─ SensaControl    controle de ventoinhas: curvas, validação, planejador, núcleo de segurança, protocolo XPC — puros
 ├─ SensaPersistence HistoryStore (SQLite do sistema): minuto por 7 dias → hora, retenção, CSV/JSON
 ├─ SensaProviders  provedores reais + descoberta de hardware + catálogo de sensores
 │   ├─ SensaHardware    APIs públicas (sysctl, Mach, IORegistry, IOPowerSources)
 │   └─ SensaPrivateAPI  ⚠️ SMC, HID (isolado; símbolos via dlsym) ── CSensaPrivate (layouts C)
 ├─ SensaDemo       provedores de demonstração (somente via -SensaDemoMode, sempre rotulados)
 └─ SensaCore       domínio puro: modelos, capacidades, contratos (Foundation apenas)

Helper (app.sensa.Sensa.helper, root via launchd) ── SensaControl + SensaPrivateAPI (SMCFanWriter)
```

## Controle de ventoinhas

O app nunca escreve no SMC. Ele decide *o quê* (`FanControlPlanner`, no `FanControlCoordinator`) e envia
alvos por XPC ao helper privilegiado, que decide *se* é seguro (`FanSafetyController`) e só então escreve
(`SMCFanWriter`, que aceita apenas `Ftst`, `F{n}Md` e `F{n}Tg`).

Segurança, sem depender do app:

| Situação | Comportamento |
|---|---|
| Pedido do app | validado contra limites lidos do hardware na hora; velocidade presa em [mín, máx]; nunca 0 rpm |
| App encerra, trava ou para de responder | conexão cai ou o *lease* de 10 s expira → automático |
| Pressão térmica séria/crítica (macOS) | automático; manual recusado até 30 s de condição normal |
| Helper inicia (boot, crash) ou recebe SIGTERM | automático, mesmo sem override conhecido |
| Falha de escrita | automático |
| App: sem leitura de temperatura recente, limites inválidos, muito quente para velocidade fixa | automático |

Restaurar = gravar em cada `F{n}Md` o modo encontrado quando o helper iniciou (3 no M3; 0 em gerações
anteriores), depois `Ftst = 0`, e confirmar por leitura que nenhuma ventoinha ficou em manual.

Instalação sem Developer ID: o app gera um script (`HelperInstallScript`) executado com
`do shell script … with administrator privileges` (o usuário digita a senha). O script copia o helper para
`/Library/PrivilegedHelperTools`, **verifica o cdhash já no local de root** e cria o job do launchd
(`RunAtLoad`, `KeepAlive` em falha, Mach service). O helper aceita conexões só do build do Sensa cujo
cdhash está fixado no job; o app só conversa com o helper idêntico ao embutido. Com Developer ID, troca-se
por `SMAppService` e requisitos por Team ID.

## Fluxo de dados

1. `HardwareDiscovery` identifica o Mac → `HardwareProfile`.
2. `ProductionProviders` monta os provedores que existem neste Mac + capacidades estáticas.
3. `MonitoringEngine` sonda (`probe`) cada provedor → estados de capacidade; amostra por tier
   (rápido/médio/lento) em tarefas separadas, provedores em paralelo, backoff exponencial em falha.
4. Eventos (`AsyncStream`) → `MetricsStore` no MainActor: snapshot agregado + séries com buffer circular.
5. Views observam o store; cada `MetricSeries` é um objeto observável próprio (gráficos isolados).

## Eficiência

* Intervalos por demanda: janela/popover visível → 1 s; só barra de menus → 3 s (configurável 2–10 s);
  tela dormindo → 30 s. Na bateria os intervalos aumentam 1,5×. Suspensão do sistema pausa tudo.
* Demanda inicial é decidida antes da primeira amostra (abrir direto na barra de menus não amostra a 1 s).
* Provedores declaram `minimumDemand`: processos, frequências, energia por componente e Wi-Fi só são lidos com
  janela ou popover visível. `prepare(for:)` permite reduzir detalhe — o provedor de sensores lê só os sensores
  agregados (~60 chaves em vez de ~275, sem HID) quando apenas a barra de menus está visível.
* Barra de menus desenhada com AppKit (`StatusItemRenderer`, imagem template com desenho preguiçoso), sem o
  `ImageRenderer` do SwiftUI; redesenha só quando o `MenuBarLabelModel` muda.
* `Task.sleep(tolerance:)` permite coalescência de wake-ups.

Medido em Release no Mac15,6 (média de ~60 s):

| Modo | CPU | Memória |
|---|---|---|
| Só barra de menus, 3 s | 0,43 % | 17 MB |
| Só barra de menus, 5 s | 0,30 % | 16 MB |
| Janela aberta na visão geral, 1 s | ~9,5 % | ~200 MB (otimização prevista na Etapa 6) |

## Proveniência e honestidade

Toda leitura carrega `Provenance` (`hardware`, `system`, `derived`, `estimated`, `demo`). Sensores só recebem
nome quando um catálogo os valida no modelo; temperaturas agregadas usam apenas mapeamentos verificados.

## Serviços do app

O `AppEnvironment` (composition root) cria e injeta, via `sensaEnvironment(...)`, os serviços que a interface usa
apenas por protocolos: `HistoryReading` (SensaCore), `NotificationDelivering` e `LaunchAtLoginControlling`
(Features), `AlertCoordinator` e `Feedback` (sons/hápticos). A navegação da janela é um `AppNavigation` observável,
para que Ajustes e barra de menus possam abrir uma tela.

## Localização

10 idiomas (en, pt-BR, es, fr, de, it, ja, ko, zh-Hans, zh-Hant) em String Catalogs nativos.
Fonte da verdade: `scripts/localization/keys.json` + um arquivo `<idioma>.txt` (`número|tradução`) por idioma;
`build-catalogs.py` gera os `.xcstrings` e valida placeholders. O idioma pode ser escolhido em Ajustes › Geral
(`AppleLanguages` por app, aplicado após reiniciar).

## Testes

* `swift test` (Packages/SensaKit): 48 testes Swift Testing, incluindo integração real (`.tags(.hardware)`).
* `xcodebuild test`: XCUITest em modo demo (perfis notebook, notebook sem ventoinha, desktop sem bateria).
* `scripts/ci.sh`: lint estrito, cobertura de traduções pt-BR, build sem warnings, todos os testes.
