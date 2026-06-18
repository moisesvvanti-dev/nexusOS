# Correção do erro `/usr/bin/env`

Erro anterior:

```text
chroot: failed to run command ‘/usr/bin/env’: No such file or directory
```

Correções na V3:

- remove hooks `.hook.chroot`
- usa apenas `hooks/normal`
- adiciona `coreutils`, `bash`, `dash`, `usr-is-merged`
- troca shebangs internos para `/bin/bash`
- desativa Debian Installer para reduzir dependências problemáticas
