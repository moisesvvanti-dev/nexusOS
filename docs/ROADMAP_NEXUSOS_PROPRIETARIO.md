# Roadmap NexusOS Proprietário

Este roadmap transforma o NexusOS em produto próprio, sem vender a ideia falsa de que um ISO Debian customizado já é um kernel proprietário completo.

## Fase 1 — Separação clean-room proprietária
Status: iniciado neste repositório.

- [x] Identidade Prism 12 original.
- [x] Ícones e wallpaper próprios.
- [x] Licença proprietária para o novo core.
- [x] Política clean-room proibindo cópia de Linux/outros OS.
- [x] Diretório `nexus-core/` separado do protótipo Debian.
- [x] Kernel scaffold freestanding original em C.
- [x] Build check do core sem libc/Linux headers.
- [x] `nexus-browser` Chromium-based/Brave-inspired sem telemetria por padrão no protótipo.
- [x] Políticas gerenciadas para privacidade do browser no protótipo.
- [x] `nexus-exe` como Nexus EXE Runtime inicial no protótipo.
- [x] `nexus-watchdog` para reparos visuais básicos em tempo real no protótipo.
- [x] `nexus-hardware-profile` para modo low-RAM/no-GPU no protótipo.

## Fase 2 — Kernel proprietário mínimo

Meta: bootar o NexusOS Core sem Linux.

Tarefas:
1. Criar loader UEFI clean-room.
2. Passar mapa de memória/framebuffer/ACPI para `nx_kernel_main`.
3. Implementar console framebuffer próprio.
4. Implementar PMM/VMM inicial.
5. Implementar IDT/GDT/interrupções/timer.
6. Implementar scheduler cooperativo inicial.
7. Gerar imagem bootável própria.

## Fase 3 — EXE como subsistema de primeira classe

Meta: usuário clicar em `.exe` e parecer nativo.

Tarefas:
1. Implementar loader PE/COFF próprio em `nexus-core/nrt/`.
2. Implementar registry virtual e filesystem virtual.
3. Implementar APIs Win32 essenciais de forma original, sem copiar Wine/ReactOS.
4. Criar banco de perfis por app em `/usr/share/nexusos/exe-profiles/*.yaml` no protótipo.
5. Criar sandbox por app.
6. Criar reparo automático quando runtime/DLL/config quebrar.

## Fase 4 — Browser proprietário real

Meta: deixar de ser apenas wrapper e virar fork real.

Tarefas:
1. Escolher base: Chromium puro ou Brave open-source sem marca Brave.
2. Remover endpoints de telemetria no código-fonte.
3. Embutir bloqueador de anúncios e listas locais.
4. Implementar anti-fingerprint controlado: Canvas, WebGL, AudioContext, ClientRects, UA, timezone e fontes.
5. Criar UI própria Nexus Browser.
6. Assinar builds próprios.

## Fase 5 — IA nativa transacional

Meta: IA que corrige, mas com segurança.

Tarefas:
1. Toda correção automática deve criar snapshot/backup antes.
2. IA só executa ações permitidas por políticas locais.
3. Watchdog coleta logs, classifica falha e escolhe reparo.
4. Reparos comuns: painel, compositor, rede, áudio, flatpak, wineprefix, permissões.
5. Se reparo falhar, rollback automático.
6. Interface visual mostra o que foi reparado.

## Fase 6 — Universal Device

Meta: rodar no máximo de máquinas possível.

Perfis:
- `amd64-full`: PCs modernos.
- `amd64-lowram`: 1GB RAM, sem compositor, apps leves.
- `amd64-nogpu`: renderização software, sem efeitos.
- `arm64-sbc`: Raspberry Pi e similares.
- `arm64-mobile`: celulares/desktops ARM, precisa port específico.

Importante: celular ARM não inicializa ISO amd64. É necessário build ARM64 separado, bootloader compatível e drivers por dispositivo.

## Critério de produto

O NexusOS só deve ser anunciado como “sistema proprietário” quando estes pontos existirem:

- marca visual própria;
- shell/browser/runtime próprios;
- instalador próprio ou fortemente personalizado;
- update server próprio;
- assinatura de pacotes/imagens;
- documentação legal/licenciamento;
- política clara para componentes open-source usados internamente.
