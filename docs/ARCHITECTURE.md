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

* Intervalos por demanda: janela/popover visível → 1 s; só barra de menus → 3 s; tela dormindo → 30 s.
* Na bateria os intervalos aumentam 1,5×. Suspensão do sistema pausa tudo; ao acordar, re-sonda.
* `Task.sleep(tolerance:)` permite coalescência de wake-ups.
* O rótulo da barra de menus só é re-renderizado quando o texto exibido muda.

## Proveniência e honestidade

Toda leitura carrega `Provenance` (`hardware`, `system`, `derived`, `estimated`, `demo`). Sensores só recebem
nome quando um catálogo os valida no modelo; temperaturas agregadas usam apenas mapeamentos verificados.

## Testes

* `swift test` (Packages/SensaKit): 48 testes Swift Testing, incluindo integração real (`.tags(.hardware)`).
* `xcodebuild test`: XCUITest em modo demo (perfis notebook, notebook sem ventoinha, desktop sem bateria).
* `scripts/ci.sh`: lint estrito, cobertura de traduções pt-BR, build sem warnings, todos os testes.
