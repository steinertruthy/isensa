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
* `-SensaInitialDestination cpu|gpu|memory|battery|thermals|fans|storage|network|sensors`.
* `-SensaOpenPopover YES` — abre o popover da barra de menus ao iniciar.
* `swift run --package-path Packages/SensaKit sensa-probe smc T F P` — despeja sensores para validação.

Documentação: [arquitetura](docs/ARCHITECTURE.md) · [viabilidade e validação](docs/FEASIBILITY.md).
