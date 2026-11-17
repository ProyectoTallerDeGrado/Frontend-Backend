#!/usr/bin/env bash
# Despliega (o vuelve a desplegar) una versión ya publicada en GHCR.
#   ./deploy.sh            -> la etiqueta IMAGE_TAG del entorno o `latest`
#   IMAGE_TAG=<sha> ./deploy.sh   -> volver a una versión anterior
# Lo llama GitHub Actions por SSH; también sirve a mano en la instancia.
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -f .env ]; then
  echo "Falta /opt/emprendeu/.env (copia .env.example y complétalo)." >&2
  exit 1
fi
mkdir -p secrets

export IMAGE_TAG="${IMAGE_TAG:-latest}"
echo "Desplegando la versión ${IMAGE_TAG}..."

docker compose pull --quiet
# Migraciones antes de reemplazar la API; si fallan, la versión anterior sigue arriba.
docker compose up -d db
docker compose run --rm migrate
docker compose up -d --remove-orphans

# Espera a que la API responda dentro de la red.
for _ in $(seq 1 30); do
  if docker compose exec -T api python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=4).status == 200 else 1)" 2>/dev/null; then
    echo "API sana."
    docker image prune -f >/dev/null
    exit 0
  fi
  sleep 3
done
echo "La API no respondió a tiempo. Revisa: docker compose logs api" >&2
exit 1
