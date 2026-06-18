# NexusOS Clean-Room Development Policy

## Goal
Build the future NexusOS Proprietary Core without copying Linux code or any other operating-system source code.

## Rules
1. Do not paste code from Linux, BSD, ReactOS, Wine, Chromium, Brave, GNU libc, musl, UEFI samples, StackOverflow, blogs, or random repositories.
2. Use public hardware specifications, CPU manuals, UEFI/ACPI/PCI specs, and original implementation work.
3. Keep every proprietary source file under `nexus-core/` with a header stating it is original NexusOS code.
4. If learning from documentation, write code from understanding, not by translating source.
5. Keep third-party compatibility layers separate from proprietary core.
6. Maintain a contribution log for each file when more developers join.
7. Before claiming “100% proprietary OS”, remove the live-build/Debian boot path from the final product image.

## Repository boundary
- `config/`, `.github/`, `local-builder/`: current Linux-based prototype ISO.
- `nexus-core/`: clean-room proprietary OS core work.
- `docs/`: architecture, legal boundary and migration plan.

## Allowed references
- Intel/AMD architecture manuals.
- UEFI specification.
- ACPI specification.
- PCI/USB specifications.
- Your own tests and experiments.

## Not allowed
- Copying Linux drivers, syscall code, schedulers, filesystems, kernel headers, Wine internals, Chromium internals, or ReactOS code into `nexus-core/`.
