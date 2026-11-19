# Viabilidade técnica — Sensa

Validado em **MacBook Pro 14" Nov 2023 (`Mac15,6`), Apple M3 Pro, macOS 26.6.2** em 2026-11-18.

| Recurso | Interface | Pública? | Privilégio | Estado no Mac15,6 |
|---|---|---|---|---|
| Uso de CPU total/por núcleo, P/E | `host_processor_info`, `hw.perflevel*` | Sim | — | ✅ Disponível (5P + 6E) |
| Uso de GPU | `IOAccelerator.PerformanceStatistics` | Registry | — | ✅ Disponível |
| Memória, swap, pressão | `host_statistics64`, `vm.swapusage`, `kern.memorystatus_*` | Sim | — | ✅ Disponível |
| Bateria | IOPowerSources + `AppleSmartBattery` | Sim/Registry | — | ✅ Saúde 92 % confere com Informações do Sistema |
| Estado térmico | `ProcessInfo.thermalState`, `notify` | Sim | — | ✅ Disponível |
| Temperaturas | SMC (`T*`, 230 chaves plausíveis) + HID (45 serviços) | **Privada** | — | 🧪 Experimental |
| Potência total | SMC `PSTR` | **Privada** | — | 🧪 Experimental (≈5 W repouso, ≈38 W sob carga GPU) |
| Ventoinhas (leitura) | SMC `FNum`, `F{n}Ac/Mn/Mx/Tg/Md` | **Privada** | — | 🧪 2 ventoinhas, 2317–6800 rpm; param em repouso |
| Ventoinhas (escrita) | SMC `Ftst`, `F{n}Md`, `F{n}Tg` via helper root | **Privada** | Root (senha de administrador) | 🧪 Experimental; validado neste Mac (curva, queda do app, repouso) |
| Armazenamento | `URLResourceValues`, `IOBlockStorageDriver` | Sim/Registry | — | ✅ Disponível (espaço livre/purgável, IOPS, latência) |
| Atividade de disco por app | `proc_pid_rusage` (`ri_diskio_*`) | Sim | — | ✅ Processos do usuário; serviços do sistema só nos totais |
| Estrutura APFS e FileVault | `diskutil info/apfs list -plist` | Sim (ferramenta do sistema) | — | ✅ Validado neste Mac |
| Snapshots locais | `tmutil listlocalsnapshots /` | Sim (ferramenta do sistema) | — | ✅ Validado neste Mac |
| Rede | `NET_RT_IFLIST2` (`if_data64`) | Sim | — | ✅ Disponível |
| Frequências CPU/GPU | IOReport (residência) × tabelas DVFS do `pmgr` | **Privada** | — | 🧪 Verificado: E 2748, P 4056, GPU 1380 MHz sob carga |
| Energia por componente | IOReport `Energy Model` | **Privada** | — | 🧪 CPU 6,5 W (carga CPU), GPU 13,4 W (carga Metal) |
| Top processos | `libproc` (`proc_pid_rusage`) | Sim | — | ✅ CPU e memória; ~1/3 dos processos (outros usuários) inacessíveis |
| Energia por processo | `ri_billed_energy` | Sim | — | ❌ Sempre 0 no macOS 26 — não exibido |
| SMART NVMe | `IONVMeSMARTInterface` (header público) | Sim | — | ✅ 1 % usado, 100 % de reserva, 690 h |
| Wi-Fi | CoreWLAN | Sim | Localização (só nome da rede) | ✅ RSSI, ruído, taxa, canal, padrão |
| Limite de carga | Ajuste nativo do macOS 26 | — | — | ➖ Não implementado de propósito |

## Validação de sensores (sensa-probe)

`swift run --package-path Packages/SensaKit sensa-probe smc T F P` e `sensa-probe hid` despejam todas as chaves.
Mapeamentos marcados como **verificados** foram confirmados por teste diferencial:

* Carga de CPU (11 threads, 25 s): chaves `Tp*` +8–11 °C, `Te*` +6–9 °C, `Tg*` +5 °C.
* Carga de GPU (kernel Metal, 25 s, ~43 % de uso): `Tg*` +20–22 °C, `Tp*` +13 °C.

Conclusão: `Tp*` = núcleos de desempenho, `Te*` = núcleos de eficiência, `Tg*` = GPU (verificados em `Mac15,6`).
`Ts*`, `Th*`, `Tf*` respondem a ambas as cargas e permanecem **desconhecidos** (exibidos com a chave original).
Os sensores HID `PMU tdie*` não responderam à carga de CPU e ficam como "inferidos" (die do SoC).

## Achados importantes

* **Modo das ventoinhas no automático, neste Mac**: `F{n}Md = 3` (com `F{n}St = 3`) quando o macOS as mantém
  paradas, e `F{n}Md = 0` (com `F{n}St = 5`) quando ele as faz girar — observado em 19/11 sem nenhuma escrita
  do Sensa (ventoinhas ligaram sob carga do CI e ficaram no mínimo, 2.317 rpm, enquanto o Mac esfriava).
  Só `1` significa manual; o Sensa trata qualquer outro valor como automático.
* **Escrita de modo manual no M3 Pro (macOS 26) devolve `0x82` na primeira tentativa** — o `thermalmonitord`
  mantém as ventoinhas em modo de sistema (3). Sequência adotada: tentar `F{n}Md = 1`; se `0x82`, gravar
  `Ftst = 1` e repetir a cada 1 s por até 12 s (a liberação leva ~3–6 s segundo outros projetos).
* **Devolver ao automático no M3 Pro**: gravar `F{n}Md = 3` também devolve `0x82`; o que devolve o controle é
  `Ftst = 0` — o gerenciador térmico do macOS volta a colocar as ventoinhas em modo 3 sozinho, em alguns
  segundos (verificado neste Mac). O helper tenta o modo original (necessário em gerações anteriores), limpa
  `Ftst` e confirma por leitura em até 10 s. Há relato (não confirmado no M3) de limite de
  ~100 escritas de ventoinha por boot; por isso o helper nunca regrava valores iguais e o app não repete
  tentativas recusadas sozinho.
* **Validação em hardware (19/11/2026, Mac15,6, macOS 26.6)**:
  * Curva Desempenho: modo manual em ~3–7 s após abrir o app; alvo em degraus de 10% (40% → 50% sob carga em
    todos os núcleos, de volta a 40% sem carga); rotação real a ±2% do alvo.
  * `kill -9` no app em modo manual: o auxiliar detecta a conexão perdida e as ventoinhas voltam ao automático
    (`Ftst = 0`, modo 3) em **2,6 s**; o macOS para as ventoinhas ~3 s depois, por estar frio.
  * Vários ciclos manual/automático na mesma sessão sem recusa — o limite por boot, se existir, não foi atingido.
  * Com a média dos sensores como entrada, a curva Desempenho ficou em 50% sob carga (média 57–61 °C, núcleo
    mais quente 73–80 °C). Com o núcleo mais quente suavizado (constante de 8 s), foi a 70–80% na mesma carga.
    O alvo mudou a cada 30–40 s, entre 70% e 80%, sem oscilar a cada leitura, embora o valor bruto variasse
    64–85 °C em segundos. Depois da carga, desceu 10% por atualização.
  * O núcleo mais quente também oscila 58–83 °C com o Spotlight indexando (sensores `Tp3X`, `Tp1S`, `Tp1K`:
    núcleos ativos, não um sensor defeituoso).
  * **Calibração das curvas** (núcleo mais quente suavizado, ventoinhas com o macOS): uso leve (~33% de CPU)
    73–78 °C; todos os núcleos ocupados por 2,5 min 83–90 °C — e o macOS manteve as ventoinhas no mínimo
    (~2.300 rpm) nos dois casos. Os primeiros limites (Equilibrada 65 °C, Silenciosa 75 °C) tirariam as ventoinhas
    do macOS até em uso leve; as curvas foram recalibradas: Silenciosa devolve ao macOS abaixo de 90 °C,
    Equilibrada abaixo de 82 °C, Desempenho fica em ~30% em uso leve e ~70% com todos os núcleos ocupados.
  * **Curvas prontas após a recalibração** (mesmo dia; núcleo mais quente suavizado neste dia: 78–83 °C com
    todos os núcleos ocupados, mais frio que na calibração):
    * Desempenho, uso leve: assumiu em ~4 s a 30%, subiu em degraus até 60% (≈5.000 rpm) conforme a
      temperatura de controle passava de 72 para 82 °C e segurou 60% ao esfriar (histerese); rotação real a ±2%.
    * Equilibrada, todos os núcleos ocupados: com o macOS na maior parte dos 140 s; assumiu duas vezes ao
      chegar a 82 °C (10%, 2.765 rpm) e devolveu ao macOS abaixo de 79 °C após 8–12 s cada vez — alternância
      a cada ~minuto. **Corrigido** com a espera de 60 s antes de devolver: no novo teste (3 min 40 s com todos os
      núcleos ocupados e depois sem carga), o Sensa assumiu uma vez aos 60 s, variou 0–40% (até ~4.100 rpm com a
      temperatura de controle em 88 °C) e devolveu uma única vez, ~67 s depois de a carga acabar.
    * Silenciosa, todos os núcleos ocupados: ficou com o macOS o tempo todo (máximo bruto 88,7 °C, suavizado
      ~83 °C). O trecho acima de 90 °C não foi alcançado em hardware; usa o mesmo cálculo das outras curvas.
    * Em todos os casos o retorno ao Automático deixou `Ftst = 0` e o modo 0 nas duas ventoinhas.
  * Repouso de 17 s em modo manual: as ventoinhas voltaram ao macOS e pararam; ao acordar, o Sensa retomou
    o controle sozinho.
* **`BatteryHealth` (IOPS) é enganoso**: retorna "Check Battery" enquanto Informações do Sistema mostra
  Condition: Normal. Usa-se `BatteryHealthCondition` (vazio = normal).
* As ventoinhas ficam em 0 rpm em repouso — o app explica isso como comportamento normal.

## Achados da Etapa 3

* **Estados de desempenho:** os nomes `V<n>P<m>` (CPU) e `P<n>` (GPU) indexam a tabela DVFS. Sob carga total,
  os clusters atingem exatamente o máximo da tabela (2748/4056/1380 MHz), o que valida o mapeamento.
  Estados fora da tabela desativam a frequência em vez de serem estimados.
* **Contadores de rede são truncados para apps:** o macOS entrega `ifi_ibytes/obytes` com 32 bits e passos de
  1 KiB (en0: `netstat` = 397.879.015.395 B; Sensa = 2.742.023.168 = valor mod 2³² arredondado a 1024).
  Por isso o cálculo de taxa trata a volta em 4 GiB e os totais desde a inicialização não são exibidos.
  Túneis (`utun*`) não entram na soma para não contar o tráfego de VPN duas vezes.
* **SMART no Apple silicon:** a capacidade fica no `IOEmbeddedNVMeBlockDevice`, não no controlador, e o
  plug-in precisa permanecer vivo durante a leitura.
* **Volumes somente leitura** ficam fora da lista de volumes; imagens de disco montadas aparecem num cartão próprio.

## Achados do Armazenamento (19/11/2026, Mac15,6, macOS 26.6)

* **Espaço purgável:** `volumeAvailableCapacityForImportantUsage` (o que o Finder mostra) − `volumeAvailableCapacity`
  (livre de fato). Neste Mac: 17,84 GB disponíveis = 14,62 GB livres + 3,22 GB purgáveis. Volumes somente leitura
  informam 0 para "uso importante"; para eles vale o valor simples.
* **`volumeIsEncrypted` não indica o FileVault:** é falso em `/` (o volume de sistema selado) com o FileVault ligado.
  O estado vem do volume de dados em `diskutil apfs list -plist` (`FileVault = true`), conferido com `fdesetup status`.
* **Contêiner APFS:** 494 GB compartilhados por Sistema (16,6 GB), Dados (429 GB), Preboot (16,3 GB), VM (14 GB:
  swap e imagem de repouso), Recuperação e Atualização. `diskutil` responde em ~0,1 s sem privilégios; o Sensa
  consulta a cada 5 minutos e uma vez por volume montado.
* **Snapshots:** `tmutil listlocalsnapshots /` lista os do grupo de volumes, inclusive os de atualização do macOS
  (`com.apple.os.update-…`; 3 neste Mac, nenhum do Time Machine). O tamanho de cada um não é informado sem privilégios.
* **IOPS e latência:** `IOBlockStorageDriver` › `Statistics` traz `Operations` e `Total Time` (ns) de leitura e
  escrita; a latência média é Δtempo ÷ Δoperações (neste Mac, desde o boot: ~0,41 ms por leitura, ~53 µs por escrita).
  `Latency Time` fica sempre 0 e não é usado.
* **Atividade por app:** `ri_diskio_bytesread/byteswritten` funcionam para processos do usuário (ex.:
  `corespotlightd`); `mds_stores`, `backupd` e outros serviços root ficam de fora e aparecem só no total.
* **Imagens de disco:** o `BusProtocol` do `diskutil info` ("Disk Image") as separa dos volumes; neste Mac havia 9
  montadas (instaladores esquecidos). Ejetar usa `NSWorkspace.unmountAndEjectDevice` e não apaga o arquivo.
* **Teste de velocidade:** arquivo temporário com `F_NOCACHE` (sem cache de memória) e `F_FULLFSYNC` ao fim da
  escrita; validado com 64 MB nos testes de hardware. Só roda quando a pessoa inicia.
* **Liberar espaço — desempenho:** a primeira versão (`contentsOfDirectory` + `URLResourceValues` por arquivo) levou
  74 s para 889 mil arquivos (/Applications, ~/Library/Developer e ~/Library/Caches); com `fts` e objetos só para
  itens ≥ 1 MB, 26,5 s, contra ~24 s do `du -skx` nas mesmas pastas. Os tamanhos são idênticos entre as duas versões e
  ficam a 0,2–1,2 % do `du` (unidades decimais × KiB).
* **Pastas protegidas:** sem Acesso Total ao Disco, 9 pastas de `~/Library/Caches` (Safari, HomeKit, CloudKit…)
  não podem ser lidas; aparecem como "sem acesso", não como zero. Desktop, Documentos, Downloads e dados de outros
  apps disparam o pedido de permissão do próprio macOS na primeira análise.
* **Último uso de apps:** `kMDItemLastUsedDate` (Spotlight) funciona sem privilégios; apps sem registro ficam fora da
  sugestão de apps não usados.
* **Não implementado, por honestidade:** vida útil restante do SSD (a Apple não publica o TBW) e velocidade do
  link USB/Thunderbolt (nenhum disco externo disponível para validar a leitura do IORegistry). O aviso de disco
  removido sem ejetar já é feito pelo próprio macOS.

## Distribuição

A App Sandbox bloqueia o user client `AppleSMCClient` → **Mac App Store inviável** para o produto completo.
Caminho: Developer ID + Hardened Runtime + notarização + atualização via Sparkle.
`ENABLE_HARDENED_RUNTIME` já está ativo no `project.yml`, mas com assinatura ad-hoc o Xcode o desativa
("Disabling hardened runtime with ad-hoc codesigning"); ele só vale de fato com a assinatura Developer ID. O helper privilegiado
(`SMAppService.daemon` + XPC com `setCodeSigningRequirement`) só registra com assinatura Developer ID.
