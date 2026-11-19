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
| Armazenamento | `URLResourceValues`, `IOBlockStorageDriver` | Sim/Registry | — | ✅ Disponível |
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
* **Volumes somente leitura** (imagens de instalação montadas) foram removidos da lista de capacidade.

## Distribuição

A App Sandbox bloqueia o user client `AppleSMCClient` → **Mac App Store inviável** para o produto completo.
Caminho: Developer ID + Hardened Runtime + notarização + atualização via Sparkle.
`ENABLE_HARDENED_RUNTIME` já está ativo no `project.yml`, mas com assinatura ad-hoc o Xcode o desativa
("Disabling hardened runtime with ad-hoc codesigning"); ele só vale de fato com a assinatura Developer ID. O helper privilegiado
(`SMAppService.daemon` + XPC com `setCodeSigningRequirement`) só registra com assinatura Developer ID.
