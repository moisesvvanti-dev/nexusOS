#!/bin/bash
###############################################################################
# NexusOS Create Installation Media
# Creates bootable USB from ISO
###############################################################################

set -euo pipefail

ISO_PATH="${1:-}"
USB_DEVICE="${2:-}"
DEVICE_NAME=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${BLUE}[*]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script precisa ser executado como root (use sudo)"
        exit 1
    fi
}

show_usage() {
    cat << 'EOF'
NexusOS Create Installation Media

Usage:
    sudo ./create-nexus-install-media.sh [ISO_PATH] [USB_DEVICE]

Examples:
    # Interactive mode
    sudo ./create-nexus-install-media.sh
    
    # Direct mode
    sudo ./create-nexus-install-media.sh NexusOS-12.0.0-Aurora-amd64.iso /dev/sdb

EOF
}

select_iso() {
    log "Selecionando ISO..."
    
    if [ -z "$ISO_PATH" ]; then
        local isos=()
        while IFS= read -r -d '' iso; do
            isos+=("$iso")
        done < <(find . -maxdepth 2 -name "*.iso" -print0 2>/dev/null)
        
        if [ ${#isos[@]} -eq 0 ]; then
            log_error "Nenhuma ISO encontrada no diretório atual"
            exit 1
        fi
        
        echo "ISOs disponíveis:"
        select iso in "${isos[@]}"; do
            if [ -n "$iso" ]; then
                ISO_PATH="$iso"
                break
            fi
        done
    fi
    
    if [ ! -f "$ISO_PATH" ]; then
        log_error "ISO não encontrada: $ISO_PATH"
        exit 1
    fi
    
    log_success "ISO selecionada: $ISO_PATH"
    log "Tamanho: $(du -h "$ISO_PATH" | cut -f1)"
}

select_usb_device() {
    log "Selecionando dispositivo USB..."
    
    echo ""
    echo "Dispositivos de armazenamento disponíveis:"
    lsblk -o NAME,SIZE,TYPE,MODEL | grep -E "disk|rom"
    echo ""
    
    if [ -z "$USB_DEVICE" ]; then
        read -p "Digite o dispositivo (ex: sdb): " DEVICE_NAME
        USB_DEVICE="/dev/$DEVICE_NAME"
    fi
    
    if [ ! -b "$USB_DEVICE" ]; then
        log_error "Dispositivo não encontrado: $USB_DEVICE"
        exit 1
    fi
    
    log_warning "Dispositivo: $USB_DEVICE"
    log_warning "ATENÇÃO: Todos os dados serão apagados!"
    read -p "Continuar? (yes/nao): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log "Operação cancelada"
        exit 0
    fi
}

verify_checksum() {
    log "Verificando checksum..."
    
    local iso_dir=$(dirname "$ISO_PATH")
    local iso_name=$(basename "$ISO_PATH")
    local checksum_file="$iso_dir/${iso_name}.sha256"
    
    if [ -f "$checksum_file" ]; then
        cd "$iso_dir"
        if sha256sum -c "${iso_name}.sha256" 2>/dev/null; then
            log_success "Checksum verificado!"
        else
            log_error "Checksum falhou!"
            exit 1
        fi
        cd - > /dev/null
    else
        log_warning "Checksum não encontrado, pulando verificação"
    fi
}

create_bootable_media() {
    log "Criando mídia inicializável..."
    
    # Unmount any mounted partitions
    log "Desmontando partições..."
    for partition in "${USB_DEVICE}"*; do
        if [ -b "$partition" ]; then
            umount "$partition" 2>/dev/null || true
        fi
    done
    
    # Write ISO to USB using dd
    log "Copiando ISO para USB (isso pode levar alguns minutos)..."
    
    dd if="$ISO_PATH" of="$USB_DEVICE" bs=4M status=progress oflag=sync
    
    # Sync to ensure all data is written
    sync
    
    log_success "Mídia criada com sucesso!"
}

verify_bootable() {
    log "Verificando inicialização..."
    
    # Check if USB is bootable by checking forEFI/boot folders
    if mount "$USB_DEVICE"1 /mnt 2>/dev/null; then
        if [ -d "/mnt/EFI/BOOT" ] || [ -d "/mnt/boot" ]; then
            log_success "Mídia inicializável verificada!"
        fi
        umount /mnt 2>/dev/null || true
    else
        # Try as raw device
        if file "$USB_DEVICE" | grep -q "ISO"; then
            log_success "Mídia parece ser inicializável"
        fi
    fi
}

main() {
    check_root
    
    log_section "NexusOS Create Install Media"
    
    select_iso
    select_usb_device
    verify_checksum
    create_bootable_media
    verify_bootable
    
    log_section "Concluído!"
    log ""
    log_success "NexusOS está pronto para uso!"
    log ""
    log "Próximos passos:"
    log "1. Remova o USB com segurança"
    log "2. Insira em um computador"
    log "3. Configure o BIOS/UEFI para boot via USB"
    log "4. Inicie o NexusOS Aurora"
}

main "$@"