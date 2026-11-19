# iSensa

Monitoramento e diagnóstico de hardware para macOS — nativo, elegante e honesto sobre o que mede.

Site oficial: <https://steinertruthy.github.io/isensa/> · Licença: [MIT](LICENSE) ·
[Como contribuir](CONTRIBUTING.md) · [Segurança](SECURITY.md)

*A native hardware monitor for macOS. Requires macOS 14 Sonoma or later on Apple silicon.*

## Começar

```bash
brew install xcodegen swiftlint
scripts/bootstrap.sh          # gera iSensa.xcodeproj
open iSensa.xcodeproj           # ou: scripts/ci.sh para validar tudo
```

Argumentos úteis (desenvolvimento):

* `-iSensaDemoMode laptopWithFans|fanlessLaptop|desktop` — dados de demonstração rotulados.
* `-iSensaInitialDestination cpu|gpu|memory|battery|thermals|fans|storage|cleanup|network|sensors`.
* `-iSensaOpenPopover YES` — abre o popover da barra de menus ao iniciar.
* `-iSensaSettingsPane general|notifications|history|…` — abre os Ajustes num painel.
* `-hasCompletedOnboarding NO` — mostra as boas-vindas novamente.
* `-iSensaDemoFanHelperInstalled YES` — no modo demo, começa com o auxiliar de ventoinhas (de demonstração) instalado.

Traduções: edite `scripts/localization/<idioma>.txt` e rode `scripts/localization/build-catalogs.py`.

Design: [plano visual e princípios](docs/DESIGN.md).
* `swift run --package-path Packages/iSensaKit isensa-probe smc T F P` — despeja sensores para validação.
* `swift run -c release --package-path Packages/iSensaKit isensa-probe space ~/Library/Caches` — mede pastas como a análise de Liberar espaço (só leitura).

### Controle de ventoinhas (experimental)

Em Ventoinhas › Controle, instale o auxiliar (pede a senha de administrador) e escolha Automático,
Velocidade fixa ou Curva (Silenciosa, Equilibrada, Desempenho ou Personalizada, com pontos arrastáveis). Cada novo build do iSensa muda sua assinatura ad hoc, então o auxiliar precisa ser
atualizado pelo mesmo botão. Para remover manualmente — as ventoinhas voltam ao automático antes de o
auxiliar sair:

```bash
sudo launchctl bootout system/io.github.steinertruthy.iSensa.helper
```

```bash
sudo rm -f /Library/LaunchDaemons/io.github.steinertruthy.iSensa.helper.plist /Library/PrivilegedHelperTools/io.github.steinertruthy.iSensa.helper
```

Para conferir o estado do SMC (somente leitura): `swift run --package-path Packages/iSensaKit isensa-probe smc Ftst F0Md F1Md F0Tg F0Ac F1Ac`.

Site: [website/](website/README.md) (Astro, publicado no GitHub Pages). Capturas e vídeos reais: `scripts/media/capture.sh`.

Documentação: [arquitetura](docs/ARCHITECTURE.md) · [viabilidade e validação](docs/FEASIBILITY.md) · [distribuição](docs/DISTRIBUTION.md).
