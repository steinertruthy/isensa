# Arquitetura — Sensa

Clean Architecture + MVVM + protocolos + injeção por construtor. Swift 6 (strict concurrency), macOS 14+.

```
App (composition root, AppKit lifecycle)
 ├─ SensaFeatures   telas, presenters, settings, barra de menus   (SwiftUI; nunca importa hardware)
 │   └─ SensaDesign tokens, superfícies, componentes, gráficos
 ├─ SensaMonitoring MonitoringEngine (actor) → MetricsStore (@Observable) → MetricSeries
 ├─ SensaInsights   regras de saúde puras e testáveis
 ├─ SensaProviders  provedores reais + descoberta de hardware + catálogo de sensores
 │   ├─ SensaHardware    APIs públicas (sysctl, Mach, IORegistry, IOPowerSources)
 │   └─ SensaPrivateAPI  ⚠️ SMC, HID (isolado; símbolos via dlsym) ── CSensaPrivate (layouts C)
 ├─ SensaDemo       provedores de demonstração (somente via -SensaDemoMode, sempre rotulados)
 └─ SensaCore       domínio puro: modelos, capacidades, contratos (Foundation apenas)
```

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

## Testes

* `swift test` (Packages/SensaKit): 48 testes Swift Testing, incluindo integração real (`.tags(.hardware)`).
* `xcodebuild test`: XCUITest em modo demo (perfis notebook, notebook sem ventoinha, desktop sem bateria).
* `scripts/ci.sh`: lint estrito, cobertura de traduções pt-BR, build sem warnings, todos os testes.
