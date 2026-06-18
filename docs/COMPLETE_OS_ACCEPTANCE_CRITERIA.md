# NexusOS Complete OS Acceptance Criteria

Este documento define o que significa “NexusOS completo no nível de um sistema moderno como Windows 11”, sem copiar Windows/Linux.

## Regra principal
O NexusOS só deve ser chamado de sistema operacional completo quando todos os blocos abaixo existirem de forma funcional, testável e instalável.

## 1. Boot e instalação
- [ ] `EFI/BOOT/BOOTX64.EFI` clean-room funcional.
- [ ] Boot em UEFI real e VM.
- [ ] Instalador particiona disco com confirmação segura.
- [ ] Partição EFI, sistema, dados e recovery.
- [ ] Recovery inicia sem sistema principal.
- [ ] Assinatura/verificação de integridade da mídia.

## 2. Kernel proprietário
- [ ] Inicialização sem Linux.
- [ ] Mapa de memória e alocador físico.
- [ ] Memória virtual.
- [ ] Interrupções e timer.
- [ ] Scheduler.
- [ ] Processos e threads.
- [ ] Syscalls Nexus.
- [ ] IPC.
- [ ] Segurança/permissões.

## 3. Drivers essenciais
- [ ] Framebuffer/VESA/UEFI GOP inicial.
- [ ] Teclado e mouse.
- [ ] Armazenamento SATA/NVMe/USB mínimo.
- [ ] Rede básica.
- [ ] Áudio básico.
- [ ] Energia/desligar/reiniciar.
- [ ] Perfil sem GPU.
- [ ] Perfil 1GB RAM.

## 4. Sistema de arquivos e apps
- [ ] FS próprio ou driver legalmente permitido.
- [ ] Gerenciador de arquivos.
- [ ] Configurações do sistema.
- [ ] Terminal Nexus.
- [ ] Instalador de apps/pacotes.
- [ ] Atualizador do sistema.

## 5. Interface nível consumidor
- [ ] Shell gráfico próprio.
- [ ] Launcher/menu.
- [ ] Barra/painel.
- [ ] Janelas, compositor ou fallback 2D.
- [ ] Notificações.
- [ ] Tema claro/escuro.
- [ ] Acessibilidade.
- [ ] Modo touch/mobile.

## 6. Nexus Browser
- [ ] Browser abre sites modernos.
- [ ] Sem telemetria por padrão.
- [ ] Bloqueador de anúncios/rastreadores.
- [ ] Anti-fingerprint configurável.
- [ ] Integração com IA local.

## 7. EXE Runtime
- [ ] Loader PE/COFF.
- [ ] Win32 APIs essenciais.
- [ ] Registry virtual.
- [ ] Filesystem virtual.
- [ ] Gráficos/áudio/input bridge.
- [ ] Perfis por aplicativo.
- [ ] Sandbox.

## 8. IA nativa e autocorreção
- [ ] Watchdog do sistema.
- [ ] Logs estruturados.
- [ ] Detecção de falha visual/funcional.
- [ ] Reparo transacional com backup.
- [ ] Rollback automático.
- [ ] Modo IA local completo em hardware forte.
- [ ] Modo regras leve em 1GB RAM.

## 9. Qualidade de produto
- [ ] Boot em VM limpa.
- [ ] Instalação em disco vazio.
- [ ] Atualização sem quebrar boot.
- [ ] Recovery testado.
- [ ] Testes automatizados por subsistema.
- [ ] Documentação de licença e clean-room.

Enquanto estes itens não estiverem completos, o projeto deve ser descrito como preview/protótipo com core proprietário em desenvolvimento.
