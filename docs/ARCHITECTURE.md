# Arquitetura — iSensa

Clean Architecture + MVVM + protocolos + injeção por construtor. Swift 6 (strict concurrency), macOS 14+.

```
App (composition root, AppKit lifecycle)
 ├─ iSensaFeatures   telas, presenters, settings, barra de menus   (SwiftUI; nunca importa hardware)
 │   └─ iSensaDesign tokens, superfícies, componentes, gráficos
 ├─ iSensaMonitoring MonitoringEngine (actor) → MetricsStore (@Observable) → MetricSeries
 ├─ iSensaInsights   regras de saúde e AlertEngine (limiar, duração, histerese, repetição) — puros
 ├─ iSensaControl    controle de ventoinhas: curvas, validação, planejador, núcleo de segurança, protocolo XPC — puros
 ├─ iSensaPersistence HistoryStore (SQLite do sistema): minuto por 7 dias → hora, retenção, CSV/JSON
 ├─ iSensaProviders  provedores reais + descoberta de hardware + catálogo de sensores
 │   ├─ iSensaHardware    APIs públicas (sysctl, Mach, IORegistry, IOPowerSources)
 │   └─ iSensaPrivateAPI  ⚠️ SMC, HID (isolado; símbolos via dlsym) ── CiSensaPrivate (layouts C)
 ├─ iSensaDemo       provedores de demonstração (somente via -iSensaDemoMode, sempre rotulados)
 └─ iSensaCore       domínio puro: modelos, capacidades, contratos (Foundation apenas)

Helper (io.github.steinertruthy.iSensa.helper, root via launchd) ── iSensaControl + iSensaPrivateAPI (SMCFanWriter)
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
| App: sem leitura de temperatura recente, limites inválidos, muito quente para velocidade fixa (≥ 90 °C; volta abaixo de 87 °C) | automático |

Temperatura de controle: o **núcleo de CPU mais quente** (máximo dos sensores `Tp*`/`Te*` identificados), não a
média — o calor se acumula num ponto do chip, e a média dilui um cluster quente entre os frios (no M3 Pro sob carga:
média 57–61 °C, núcleo mais quente 73–80 °C). Como o máximo oscila ~10 °C em segundos, o `TemperatureSmoother`
aplica uma média móvel exponencial de constante 8 s antes do planejador: um pico de uma amostra move o valor
~3 °C, uma subida sustentada passa quase inteira em ~16 s. Depois disso valem os degraus de 10%, a histerese de
3 °C e a descida máxima de 10% por atualização. Enquanto o iSensa controla, a devolução ao macOS na zona
silenciosa só acontece depois de **60 s seguidos** abaixo da faixa de histerese: sob carga constante no limite,
a primeira velocidade baixa esfria a CPU alguns graus em segundos, e devolver na hora alternava entre iSensa e
macOS a cada minuto. As salvaguardas (pressão térmica, leitura ausente, escolha do usuário) continuam devolvendo
na hora. A interface continua mostrando a média como "temperatura da CPU";
o gráfico da curva mostra a temperatura de controle. As curvas prontas foram calibradas no M3 Pro (uso leve
73–78 °C, todos os núcleos ocupados 83–90 °C, ambos com o macOS mantendo as ventoinhas no mínimo); ver
[viabilidade](FEASIBILITY.md).

Curva personalizada (`FanMode.custom`): o usuário arrasta os pontos no gráfico ou ajusta pelos botões (teclado e
VoiceOver). As regras ficam em `FanCurve` (`moving`, `enforcingSafety`) e valem também para preferências
antigas ou editadas à mão: a velocidade nunca cai quando a temperatura sobe, o último ponto é sempre velocidade
máxima, no máximo a 98 °C, e os pontos ficam a pelo menos 3 °C entre si. O helper continua validando cada alvo.

Restaurar = gravar em cada `F{n}Md` o modo encontrado quando o helper iniciou (3 no M3; 0 em gerações
anteriores), depois `Ftst = 0`, e confirmar por leitura que nenhuma ventoinha ficou em manual.

Instalação sem Developer ID: o app gera um script (`HelperInstallScript`) executado com
`do shell script … with administrator privileges` (o usuário digita a senha). O script copia o helper para
`/Library/PrivilegedHelperTools`, **verifica o cdhash já no local de root** e cria o job do launchd
(`RunAtLoad`, `KeepAlive` em falha, Mach service). O helper aceita conexões só do build do iSensa cujo
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

## Armazenamento

O `StorageProvider` junta três fontes com cadências diferentes: taxas e operações a cada amostra (contadores do
`IOBlockStorageDriver`), volumes a cada 30 s (`URLResourceValues`; `diskutil info` só na primeira vez que um volume
aparece) e, a cada 5 minutos, o contêiner APFS (`diskutil apfs list`) e os snapshots (`tmutil`). As ferramentas
rodam pelo `CommandRunner`: caminho absoluto, sem shell, com limite de tempo e saída lida como dados.

A tendência (`StorageTrend`, iSensaInsights) usa o histórico de `disk.used` (regressão linear, mínimo de 2 dias,
previsão só até 1 ano e acima de 100 MB/dia) e de `disk.ssd.written` (contador SMART, escritas por dia). O alerta
`storageFillingFast` compara o espaço livre com o maior valor visto nos últimos 30 minutos. O teste de velocidade
(`DiskSpeedTesting`) e o ejetar entram pelos `StorageServices`; no modo demonstração os dois são simulados.

## Liberar espaço

A análise roda só quando a pessoa pede (`SpaceAnalysis`, que vive a sessão inteira). O `DiskUsageScanner` mede a
pasta pessoal e as pastas de Aplicativos: os dois primeiros níveis em paralelo e, abaixo disso, `fts` (físico, sem
sair do volume, como o `du`), criando objetos só para itens de 1 MB ou mais — o resto vira contagem. Pacotes (apps,
bibliotecas) contam como um item só; iCloud Drive e `CloudStorage` não são percorridos. Do resultado saem as
categorias (`SpaceCategory`) e as sugestões (`CleanupSuggestions`, regras puras), e o `InstalledApps` lista os apps
com o último uso registrado pelo Spotlight e os arquivos que deixam na Biblioteca (só pelo identificador exato).

Remoção: sempre para o Lixo (`FileManager.trashItem`), depois de uma revisão com uma caixa por item, e a última
remoção pode ser desfeita. A `RemovalPolicy` é conferida de novo imediatamente antes de mover cada item: só a pasta
pessoal e os apps das pastas de Aplicativos; nunca as pastas essenciais (a própria pasta pessoal, Documentos,
Biblioteca e suas pastas de primeiro nível…), arquivos de configuração, partes de um app, apps do sistema, o próprio
iSensa, apps abertos (e as pastas com o nome deles) nem dados que outros apps gerenciam (Mail, Mensagens, Chaves,
bibliotecas de Fotos e Música, nuvem). Simuladores, Docker, backups de iPhone e o Lixo só ganham instruções.

## Serviços do app

O `AppEnvironment` (composition root) cria e injeta, via `iSensaEnvironment(...)`, os serviços que a interface usa
apenas por protocolos: `HistoryReading` (iSensaCore), `NotificationDelivering` e `LaunchAtLoginControlling`
(Features), `AlertCoordinator` e `Feedback` (sons/hápticos). A navegação da janela é um `AppNavigation` observável,
para que Ajustes e barra de menus possam abrir uma tela.

## Localização

10 idiomas (en, pt-BR, es, fr, de, it, ja, ko, zh-Hans, zh-Hant) em String Catalogs nativos.
Fonte da verdade: `scripts/localization/keys.json` + um arquivo `<idioma>.txt` (`número|tradução`) por idioma;
`build-catalogs.py` gera os `.xcstrings` e valida placeholders. O idioma pode ser escolhido em Ajustes › Geral
(`AppleLanguages` por app, aplicado após reiniciar).

## Testes

* `swift test` (Packages/iSensaKit): 48 testes Swift Testing, incluindo integração real (`.tags(.hardware)`).
* `xcodebuild test`: XCUITest em modo demo (perfis notebook, notebook sem ventoinha, desktop sem bateria).
* `scripts/ci.sh`: lint estrito, cobertura de traduções pt-BR, build sem warnings, todos os testes.
