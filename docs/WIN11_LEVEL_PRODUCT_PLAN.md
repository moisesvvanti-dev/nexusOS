# NexusOS Win11-Level Product Plan Without Windows Limitations

## Objective
Criar uma experiência polida de sistema operacional no nível de sistemas modernos, mas com identidade NexusOS, privacidade, IA local, compatibilidade EXE e suporte a hardware fraco.

## Verdade técnica
Um OS no nível Windows 11 exige milhões de linhas ao longo do tempo: kernel, drivers, gráficos, instalador, shell, modelo de apps, browser, update system, segurança e runtime de compatibilidade. Este repositório agora contém a estrutura correta e o início clean-room, mas ainda não é um OS completo nesse nível.

## Subsistemas necessários

### Kernel/Core
- bootloader UEFI;
- memória;
- scheduler;
- processos/threads;
- syscalls;
- driver model;
- storage/network/graphics/power.

### Mídia de instalação
- `install-media/EFI/BOOT/` para UEFI;
- `install-media/boot/` para config;
- `install-media/sources/` para payload;
- `install-media/drivers/` para hardware;
- `install-media/recovery/` para reparo;
- `install-media/nexus/setup/` para instalação.

### EXE support
- PE loader;
- APIs Win32 originais;
- bridge gráfica/áudio/input;
- registry/filesystem virtual;
- sandbox;
- perfis por app.

### IA repair
- watchdog;
- logs;
- ações limitadas por política;
- snapshots;
- rollback;
- modo leve para 1GB RAM.

## Entrega atual
- core proprietário clean-room em `nexus-core/`;
- layout de mídia estilo instalador moderno em `install-media/`;
- gerador `tools/create-nexus-install-media.sh`;
- protótipo ISO em `config/` para testar UX enquanto o core amadurece.
