# Despliegue en AWS (EC2 + Docker Compose + GitHub Actions)

Fecha: 2026-11-17

## 1. Arquitectura

```
Internet ──HTTPS──► EC2 (IP elástica) ── Caddy :80/:443 (certificados Let's Encrypt automáticos)
                                           ├─ emprendeu.<IP>.sslip.io ─► web  (Next.js :3000) ─┐
                                           └─ api.<IP>.sslip.io ───────► api  (FastAPI :8000) ◄─┘ red interna
                                                                          ├─ db (PostgreSQL 17 + pgvector, sin puerto público)
                                                                          ├─ ollama (solo embeddings de la base de conocimiento)
                                                                          └─ alerts-job · reminders-job · wellbeing-report
```

- **Una sola instancia EC2** con Docker Compose (`deploy/aws-ec2/docker-compose.yml`). Es más simple y barato que ECS
  y reutiliza el compose que ya existía.
- **HTTPS sin comprar un dominio**: [sslip.io](https://sslip.io) traduce `cualquier-cosa.3.4.5.6.sslip.io` a la IP
  `3.4.5.6`, y Caddy pide el certificado solo. Para usar un dominio propio después, basta con cambiar
  `WEB_DOMAIN` y `API_DOMAIN` en el `.env` y crear los registros A.
- **La web habla con la API por la red interna** (`API_URL=http://api:8000/api/v1`). El celular usa
  `https://api.<IP>.sslip.io/api/v1`.
- **Coach IA**: corre en el celular. En el servidor solo hay Ollama con el modelo de **embeddings**
  (`nomic-embed-text`, unos 300 MB), que se necesita para subir documentos a la base de conocimiento. El chat del
  coach en el servidor y el análisis de ánimo con el modelo quedan desactivados (`AI_SENTIMENT_MODEL=false`).
  El chatbot de ayuda de la web usa Gemini (`GEMINI_API_KEY`).
- **Despliegue continuo** (`.github/workflows/deploy.yml`): cada push a `main` que toque el backend, la web o
  `deploy/` sigue estos pasos:
  1. Corre las pruebas de backend y web.
  2. Construye y publica las imágenes en GHCR (`ghcr.io/proyectotallerdegrado/emprendeu-api` y `-web`, etiquetadas
     con el SHA y con `latest`).
  3. Copia el compose a la instancia por SSH y ejecuta `deploy.sh`, que descarga las imágenes, migra la base y
     reinicia los servicios.
  4. Comprueba que responden por HTTPS.

  También se puede lanzar a mano desde *Actions → deploy → Run workflow*.

## 2. Crear la instancia (lo haces tú en la consola de AWS)

1. **EC2 → Launch instance**:
   - **AMI**: Ubuntu Server 24.04 LTS (x86_64).
   - **Tipo**: `t3.medium` (2 vCPU, 4 GB). Con menos memoria, Next, PostgreSQL y Ollama no caben con holgura.
   - **Key pair**: crea uno nuevo (`emprendeu-deploy`, formato `.pem`) y guárdalo. Es el que usará GitHub Actions.
   - **Disco**: 30 GB gp3.
   - **Security group** (entrantes):

     | Puerto | Origen | Para qué |
     |---|---|---|
     | 22 (SSH) | `0.0.0.0/0` (lo usa GitHub Actions) | Despliegue |
     | 80 (HTTP) | `0.0.0.0/0` | Let's Encrypt y la redirección a HTTPS |
     | 443 (TCP y UDP) | `0.0.0.0/0` | Web y API |

     No abras el 5432 (base) ni el 8000/3000: todo entra por Caddy.
2. **Elastic IP**: *EC2 → Elastic IPs → Allocate* y luego *Associate* con la instancia. Anota la IP, por ejemplo
   `3.4.5.6`.

> Las IPs de GitHub Actions cambian, por eso el puerto 22 queda abierto. Lo protege que solo se entra con la clave
> (Ubuntu no permite contraseñas por SSH).

## 3. Preparar la instancia (una vez)

```bash
# desde tu PC
scp -i emprendeu-deploy.pem deploy/aws-ec2/bootstrap-ec2.sh ubuntu@3.4.5.6:~
ssh -i emprendeu-deploy.pem ubuntu@3.4.5.6
sudo bash bootstrap-ec2.sh      # instala Docker, crea /opt/emprendeu y 2 GB de swap
exit                            # vuelve a entrar para usar docker sin sudo
```

Crea el `.env` de producción. Es el único lugar donde viven los secretos:

```bash
scp -i emprendeu-deploy.pem deploy/aws-ec2/.env.example ubuntu@3.4.5.6:/opt/emprendeu/.env
ssh -i emprendeu-deploy.pem ubuntu@3.4.5.6
nano /opt/emprendeu/.env
```

Completa estos valores:

| Variable | Valor |
|---|---|
| `WEB_DOMAIN` | `emprendeu.3.4.5.6.sslip.io` (con tu IP) |
| `API_DOMAIN` | `api.3.4.5.6.sslip.io` |
| `ACME_EMAIL` | Tu correo, para avisos de Let's Encrypt |
| `POSTGRES_PASSWORD` | Genérala con `openssl rand -base64 32 \| tr -d '/+='` |
| `JWT_SECRET` | Genérala con `openssl rand -base64 48 \| tr -d '/+='` |
| `GEMINI_API_KEY` | La clave de la API de Gemini |
| `SMTP_*` | Tu proveedor de correo (opcional; sin él no se envían códigos de recuperación) |
| `FCM_CREDENTIALS_FILE` | Solo si usas push: sube el JSON de Firebase a `/opt/emprendeu/secrets/firebase.json` y descomenta la línea |

**Datos de demostración**: para la defensa o las pruebas, pon `ENVIRONMENT=staging` y `SEED_DEMO_DATA=true` antes del
**primer** despliegue. El seed solo corre con la base vacía y se niega con `ENVIRONMENT=production`. En producción
real, deja `ENVIRONMENT=production` y crea el administrador a mano:

```bash
cd /opt/emprendeu
docker compose run --rm api python -m emprendeu.modules.users.cli create-admin --email tu@correo --nombre "Tu Nombre"
```

## 4. Configurar GitHub (una vez)

En el repositorio, *Settings → Secrets and variables → Actions*:

| Tipo | Nombre | Valor |
|---|---|---|
| Secret | `EC2_HOST` | La IP elástica, `3.4.5.6` |
| Secret | `EC2_USER` | `ubuntu` |
| Secret | `EC2_SSH_KEY` | Todo el contenido de `emprendeu-deploy.pem`, incluidas las líneas `BEGIN/END` |
| Variable | `WEB_DOMAIN` | `emprendeu.3.4.5.6.sslip.io` |
| Variable | `API_DOMAIN` | `api.3.4.5.6.sslip.io` |

Los paquetes de GHCR del repositorio se publican con el `GITHUB_TOKEN` del workflow (permiso `packages: write`). Si
la organización bloquea la creación de paquetes, ve a *Organization → Settings → Packages* y permite que los
repositorios publiquen.

**Primer despliegue**: haz merge a `main`, o ve a *Actions → deploy → Run workflow*. Al terminar, el job
`deploy` muestra la URL. La primera vez tarda más porque Let's Encrypt emite los certificados y Ollama descarga
el modelo de embeddings.

## 5. App móvil apuntando al servidor

```bash
cd Frontend/app_emprendeu
flutter build apk --release --dart-define=API_BASE_URL=https://api.3.4.5.6.sslip.io/api/v1
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`. En release, Android exige HTTPS, que es lo que
da Caddy.

## 6. Operación

Todos estos comandos se ejecutan en la instancia, dentro de `cd /opt/emprendeu`.

| Tarea | Comando |
|---|---|
| Ver estado | `docker compose ps` |
| Logs de la API | `docker compose logs -f api` (o `web`, `caddy`, `reminders-job`) |
| Volver a una versión anterior | `IMAGE_TAG=<sha> ./deploy.sh` (el SHA está en *Actions* o en GHCR; antes hay que hacer `docker login ghcr.io` con un token con `read:packages`) |
| Respaldo de la base | `docker compose exec -T db pg_dump -U emprendeu emprendeu \| gzip > backup-$(date +%F).sql.gz` |
| Restaurar | `gunzip -c backup.sql.gz \| docker compose exec -T db psql -U emprendeu emprendeu` |
| Reiniciar todo | `docker compose up -d` |

Conviene un respaldo diario con `crontab -e`, copiado a S3 si quieres que sobreviva a la instancia:

```
0 3 * * * cd /opt/emprendeu && docker compose exec -T db pg_dump -U emprendeu emprendeu | gzip > /opt/emprendeu/backup-$(date +\%u).sql.gz
```

**Persistencia**: los volúmenes `dbdata` (base), `uploads` (documentos), `caddy_data` (certificados) y `ollama`
(modelo) sobreviven a los despliegues. Si se borra la instancia, se pierden. Para protegerlos, crea un snapshot del
disco EBS o copia los respaldos a S3.

**Costo aproximado** (us-east-1, bajo demanda):

| Recurso | Costo al mes |
|---|---|
| `t3.medium` | ~30 USD |
| 30 GB gp3 | ~2,4 USD |
| IP elástica asociada | ~3,6 USD |

## 7. Archivos

| Archivo | Para qué |
|---|---|
| `deploy/aws-ec2/docker-compose.yml` | Servicios de producción: Caddy, db, migrate, seed, api, web, ollama, tareas. Red con subred fija `172.30.0.0/24`, de la que la API acepta `X-Forwarded-For` |
| `deploy/aws-ec2/Caddyfile` | Proxy inverso y HTTPS para los dos dominios |
| `deploy/aws-ec2/.env.example` | Plantilla del `.env` de la instancia |
| `deploy/aws-ec2/deploy.sh` | Descarga las imágenes, migra, levanta y espera a que la API esté sana |
| `deploy/aws-ec2/bootstrap-ec2.sh` | Prepara Ubuntu una sola vez: Docker, swap, `/opt/emprendeu` |
| `Frontend/emprendeu/Dockerfile` | Imagen de la web (`output: "standalone"` en `next.config.ts`) |
| `.github/workflows/deploy.yml` | Pruebas, imágenes en GHCR y despliegue por SSH |
| `.github/workflows/backend.yml`, `web.yml` | También son reutilizables (`workflow_call`) |
