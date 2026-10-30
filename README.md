# BookHive — Infraestructura como Código

Sistema web de lectura sincronizada en tiempo real. Este repositorio contiene el PMV de la infraestructura en AWS.

- `terraform/`: infraestructura (módulos `network`, `security`, `data`, `auth`, `compute`, `messaging`, `api`, `backup`).
- `ansible/`: configuración de los servidores EC2 Sync.
- `.github/workflows/`: automatización con GitHub Actions.