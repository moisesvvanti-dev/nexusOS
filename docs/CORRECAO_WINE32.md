# Correção wine32

Erro:

```text
Package wine32 is not available
E: Package 'wine32' has no installation candidate
```

Motivo:
- `wine32` exige arquitetura i386 habilitada dentro do chroot.
- Para manter o build estável no GitHub Actions amd64, a V11 remove `wine32`.

Suporte EXE mantido:
- wine
- wine64
- winetricks
- lutris
- dosbox

Depois que o sistema estiver instalado, você pode habilitar 32-bit manualmente:

```bash
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install wine32
```
