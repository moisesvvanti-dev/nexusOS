# NexusOS Proprietary Architecture

## Objetivo atualizado
O objetivo final agora é o **NexusOS Proprietary Core**: um sistema operacional proprietário, escrito em clean-room, sem copiar código do Linux.

O repositório passa a ter duas partes bem separadas:

1. **Protótipo Linux atual** — `config/`, `local-builder/`, `.github/`.
   - Serve para testar visual, UX, scripts, browser wrapper, EXE runtime e IA rapidamente.
   - Usa Debian/live-build e pacotes open-source.
   - Não deve ser vendido como “100% proprietário”.

2. **Núcleo proprietário clean-room** — `nexus-core/`.
   - Código original do futuro OS.
   - Sem Linux kernel, sem headers Linux, sem copiar BSD/ReactOS/Wine/Chromium.
   - Licenciado como proprietário em `LICENSE-PROPRIETARY.md`.

## Verdade técnica importante

- Não é possível transformar Debian/Linux em sistema 100% proprietário apenas mudando nome, tema e scripts.
- Para ser realmente proprietário sem copiar Linux, é necessário criar kernel, HAL, drivers, runtime, shell, instalador e atualizador próprios.
- Isso é um projeto grande de engenharia de OS; começa com um kernel mínimo e evolui por módulos.
- Rodar `.exe` “nativamente” exige implementar um runtime compatível com PE/Win32/DirectX/registro/DLLs ou usar camada legalmente separada. Copiar Windows, Wine ou ReactOS não é permitido no core proprietário.
- Rodar em “qualquer dispositivo” exige ports separados: amd64, ARM64, dispositivos móveis, drivers e bootloaders por família.

## Componentes proprietários planejados

### 1. Nexus Proprietary Kernel
Local: `nexus-core/kernel/`

Responsável por:
- boot contract;
- memória;
- scheduler;
- processos/threads;
- IPC;
- objetos/handles;
- syscalls Nexus;
- segurança e permissões.

### 2. Nexus HAL
Futura localização: `nexus-core/hal/`

Responsável por:
- CPU;
- interrupções;
- timers;
- ACPI;
- PCI;
- framebuffer;
- SMP;
- energia/suspensão.

### 3. Nexus Driver Model
Futura localização: `nexus-core/drivers/`

Responsável por drivers próprios ou adaptadores legalmente isolados:
- armazenamento;
- teclado/mouse/touch;
- rede;
- áudio;
- GPU/framebuffer;
- USB.

### 4. Nexus EXE Runtime
Futura localização: `nexus-core/nrt/`

Objetivo: rodar `.exe` como experiência nativa Nexus.

Camadas necessárias:
- loader PE/COFF original;
- mapeador de DLLs;
- APIs Win32 compatíveis implementadas de forma original;
- bridge gráfica;
- bridge áudio;
- filesystem virtual;
- registry virtual;
- sandbox por app.

### 5. Nexus Browser
Futura localização: `nexus-core/browser/` ou repositório separado.

Objetivo: browser proprietário, sem telemetria, sem fingerprinting agressivo, com bloqueador nativo.

Caminho realista:
- curto prazo: wrapper Chromium endurecido no protótipo Linux;
- médio prazo: fork com patchset próprio e marca Nexus;
- longo prazo: shell/browser engine controlado pelo NexusOS.

### 6. Nexus AI Core
Futura localização: `nexus-core/ai/`

Objetivo:
- diagnosticar falhas;
- aplicar reparos transacionais;
- fazer rollback se falhar;
- auxiliar o usuário no sistema inteiro;
- rodar localmente quando hardware permitir;
- usar modo leve em 1GB RAM.

### 7. Nexus Universal Device Layer
Objetivo:
- perfis para PC moderno;
- perfil 1GB RAM;
- perfil sem GPU;
- perfil ARM64;
- perfil mobile/touch.

## Política clean-room obrigatória
Ver `docs/CLEAN_ROOM_POLICY.md`.

Nenhum arquivo em `nexus-core/` deve copiar código Linux ou de outro OS.
