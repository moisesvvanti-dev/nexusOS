#!/usr/bin/env bash
set -Eeuo pipefail

mkdir -p out

echo "Procurando arquivos ISO/imagem gerados..."
find . -maxdepth 4 -type f \( -name "*.iso" -o -name "*.hybrid.iso" -o -name "binary*" -o -name "live-image*" \) -print | sort || true

ISO="$(find . -maxdepth 4 -type f \( -name "*.iso" -o -name "*.hybrid.iso" \) | head -n 1 || true)"

if [[ -z "${ISO}" ]]; then
  echo "Nenhum .iso encontrado."
  echo "Listando arquivos principais do build:"
  find . -maxdepth 3 -type f | sort | sed 's#^\./##' | head -n 300
  echo
  echo "Conteúdo de build.log se existir:"
  if [[ -f build.log ]]; then
    tail -n 200 build.log
  fi
  exit 1
fi

echo "ISO encontrada: $ISO"
cp "$ISO" out/NexusOS-Aurora-amd64.iso
ls -lh out/NexusOS-Aurora-amd64.iso
