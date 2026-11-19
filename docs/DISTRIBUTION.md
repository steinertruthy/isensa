# Distribuição — iSensa

Hoje o iSensa é assinado **ad hoc** (sem Team ID). Ele roda neste Mac e o controle de ventoinhas funciona,
mas não pode ser distribuído: o Gatekeeper bloqueia apps sem Developer ID em outros Macs, e cada build muda
o cdhash fixado no auxiliar. Este guia lista o que muda quando houver uma conta Apple Developer.

A Mac App Store continua fora: a App Sandbox bloqueia o user client do SMC (sensores) e o auxiliar root.
A distribuição é independente: Developer ID + Hardened Runtime + notarização.

## 1. Assinatura

Em `project.yml` (configurações base):

```yaml
CODE_SIGN_IDENTITY: "Developer ID Application"
CODE_SIGN_STYLE: Manual
DEVELOPMENT_TEAM: <TEAM_ID>
ENABLE_HARDENED_RUNTIME: YES
OTHER_CODE_SIGN_FLAGS: --timestamp
```

* O alvo `iSensaUITests` pode voltar a usar Hardened Runtime (hoje desligado só por causa da assinatura ad hoc).
* O auxiliar (`iSensaHelper`) é assinado com o mesmo Team ID e mantém `--identifier io.github.steinertruthy.iSensa.helper`.
* Nenhum entitlement novo é necessário: o app não é sandboxed e não usa JIT nem bibliotecas de terceiros.

## 2. Auxiliar de ventoinhas: de senha de administrador para `SMAppService`

Com Developer ID, a instalação passa a ser a da Apple: o usuário aprova o auxiliar em
Ajustes do Sistema › Geral › Itens de Início, sem script de shell.

1. Mover o plist do launchd para o bundle, em `Contents/Library/LaunchDaemons/io.github.steinertruthy.iSensa.helper.plist`,
   com `BundleProgram` = `Contents/Library/LaunchServices/io.github.steinertruthy.iSensa.helper`, `MachServices`,
   `RunAtLoad` e `KeepAlive` (`SuccessfulExit = false`) — os mesmos valores de `HelperInstallScript.launchDaemon`,
   **sem** `--client-cdhash`.
2. Instalar com `SMAppService.daemon(plistName:)` → `register()`; tratar `.requiresApproval` abrindo
   `SMAppService.openSystemSettingsLoginItems()` (o estado `FanHelperState` ganha "aprovação pendente").
   Remover com `unregister()`; o auxiliar recebe SIGTERM e devolve as ventoinhas ao automático.
3. Trocar os requisitos de assinatura fixados por cdhash por requisitos de Team ID, que sobrevivem a
   atualizações:
   * no auxiliar: `anchor apple generic and identifier "io.github.steinertruthy.iSensa" and certificate leaf[subject.OU] = "<TEAM_ID>"`;
   * no app: o mesmo, com `identifier "io.github.steinertruthy.iSensa.helper"`.
4. Remover `HelperInstallScript` e o caminho `NSAppleScript` de `XPCFanControlService`; manter o
   `FanSafetyController` e o `SMCFanWriter` sem mudanças — a segurança não depende do método de instalação.
5. Migração: na primeira execução da versão assinada, se existir `/Library/LaunchDaemons/io.github.steinertruthy.iSensa.helper.plist`
   instalado pelo script, pedir para removê-lo (uma última vez com senha) antes de registrar o novo.

## 3. Notarização

```bash
xcodebuild -project iSensa.xcodeproj -scheme iSensa -configuration Release -archivePath build/iSensa.xcarchive archive
```

```bash
xcodebuild -exportArchive -archivePath build/iSensa.xcarchive -exportOptionsPlist scripts/ExportOptions.plist -exportPath build/export
```

```bash
ditto -c -k --keepParent build/export/iSensa.app build/iSensa.zip
```

```bash
xcrun notarytool submit build/iSensa.zip --keychain-profile isensa-notary --wait
```

```bash
xcrun stapler staple build/export/iSensa.app
```

`ExportOptions.plist`: `method = developer-id`, `teamID = <TEAM_ID>`, `signingStyle = manual`.
O perfil `isensa-notary` é criado uma vez com `xcrun notarytool store-credentials` (senha específica de app).
Distribuir como `.dmg` assinado e notarizado (`hdiutil create`, `codesign`, `notarytool`, `stapler`).

## 4. Atualizações (Sparkle 2)

* Adicionar o Sparkle 2 via Swift Package Manager no alvo do app (única dependência externa; avaliar antes).
* Gerar o par de chaves EdDSA (`generate_keys`); a pública vai em `SUPublicEDKey` no Info.plist, a privada
  fica fora do repositório.
* `SUFeedURL` aponta para um appcast HTTPS; cada versão é publicada com `generate_appcast`.
* Ao atualizar, o app instala o auxiliar novo se a versão do protocolo (`FanHelper.protocolVersion`) mudar —
  o estado `needsUpdate` já cobre isso.
* Ajustes › Avançado ganha "Procurar atualizações automaticamente" (desligado até haver appcast real — sem
  opções fictícias).

## 5. CI

* Segredos: certificado Developer ID (.p12 em base64 + senha), chave da API do App Store Connect para o
  `notarytool`, chave privada do Sparkle.
* Novo job de release (por tag): importar o certificado num keychain temporário, `archive`, exportar,
  notarizar, grampear, gerar o DMG e o appcast.
* O job atual (`scripts/ci.sh`) continua igual; os testes de interface precisam de um runner com
  Automation Mode liberado.

## Checklist antes da primeira versão pública

- [ ] Team ID configurado e build Release assinado com Developer ID
- [ ] Auxiliar migrado para `SMAppService` e requisitos por Team ID
- [ ] Notarização e grampo verificados com `spctl --assess --type execute -vv iSensa.app`
- [ ] Controle de ventoinhas validado de novo em hardware, com o build assinado (curva, lease, sono e despertar)
- [ ] Sparkle com appcast real e teste de atualização de uma versão para a seguinte
- [ ] README com requisitos (macOS 14+), privacidade e como remover o auxiliar

## Publicar uma versão hoje (sem Developer ID)

1. Atualize `CFBundleShortVersionString` em `project.yml` (versão semântica: `0.2.0`, `0.2.0-beta.1`).
2. `scripts/release/make-dmg.sh` gera `build/release/iSensa-<versão>-arm64.dmg` (Release, Apple Silicon, assinatura ad hoc) e o `.sha256`.
3. Publique no GitHub com a tag `v<versão>` e anexe o `.dmg` e o `.sha256`:
   `gh release create v<versão> build/release/iSensa-<versão>-arm64.dmg{,.sha256} --title "iSensa <versão>" --notes-file notas.md`
   (`--prerelease` para betas).

Depois disso, sem nenhum outro passo:
- o site oferece o novo `.dmg` no botão de download (lê a API de Releases do GitHub);
- o app instalado encontra a versão na verificação diária (ou em **iSensa › Procurar Atualizações…**), avisa com uma notificação
  e mostra o aviso no popover da barra de menus e em **Ajustes › Sobre o iSensa**. O aviso só aparece quando a versão já tem
  um instalador anexado, e cada versão é anunciada uma única vez.

A atualização ainda é manual (baixar e arrastar para Aplicativos). A instalação automática com Sparkle depende de assinatura
Developer ID; ver acima.
