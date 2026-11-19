# Sensa

Monitoramento e diagnóstico de hardware para macOS — nativo, elegante e honesto sobre o que mede.

## Começar

```bash
brew install xcodegen swiftlint
scripts/bootstrap.sh          # gera Sensa.xcodeproj
open Sensa.xcodeproj           # ou: scripts/ci.sh para validar tudo
```

Argumentos úteis (desenvolvimento):

* `-SensaDemoMode laptopWithFans|fanlessLaptop|desktop` — dados de demonstração rotulados.
* `-SensaInitialDestination cpu|gpu|memory|battery|thermals|fans|storage|cleanup|network|sensors`.
* `-SensaOpenPopover YES` — abre o popover da barra de menus ao iniciar.
* `-SensaSettingsPane general|notifications|history|…` — abre os Ajustes num painel.
* `-hasCompletedOnboarding NO` — mostra as boas-vindas novamente.
* `-SensaDemoFanHelperInstalled YES` — no modo demo, começa com o auxiliar de ventoinhas (de demonstração) instalado.

Traduções: edite `scripts/localization/<idioma>.txt` e rode `scripts/localization/build-catalogs.py`.

Design: [plano visual e princípios](docs/DESIGN.md).
* `swift run --package-path Packages/SensaKit sensa-probe smc T F P` — despeja sensores para validação.
* `swift run -c release --package-path Packages/SensaKit sensa-probe space ~/Library/Caches` — mede pastas como a análise de Liberar espaço (só leitura).

### Controle de ventoinhas (experimental)

Em Ventoinhas › Controle, instale o auxiliar (pede a senha de administrador) e escolha Automático,
Velocidade fixa ou Curva (Silenciosa, Equilibrada, Desempenho ou Personalizada, com pontos arrastáveis). Cada novo build do Sensa muda sua assinatura ad hoc, então o auxiliar precisa ser
atualizado pelo mesmo botão. Para remover manualmente — as ventoinhas voltam ao automático antes de o
auxiliar sair:

```bash
sudo launchctl bootout system/app.sensa.Sensa.helper
```

```bash
sudo rm -f /Library/LaunchDaemons/app.sensa.Sensa.helper.plist /Library/PrivilegedHelperTools/app.sensa.Sensa.helper
```

Para conferir o estado do SMC (somente leitura): `swift run --package-path Packages/SensaKit sensa-probe smc Ftst F0Md F1Md F0Tg F0Ac F1Ac`.

Documentação: [arquitetura](docs/ARCHITECTURE.md) · [viabilidade e validação](docs/FEASIBILITY.md) · [distribuição](docs/DISTRIBUTION.md).
