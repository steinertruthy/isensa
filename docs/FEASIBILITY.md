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
| Ventoinhas (escrita) | SMC via helper root | **Privada** | Root + Developer ID | 🔒 Bloqueado (sem Team ID) |
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

* **Modo automático das ventoinhas é `F{n}Md = 3` neste Mac** (não 0 como em Intel). O helper deve gravar o
  modo original e restaurá-lo — nunca presumir 0.
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
