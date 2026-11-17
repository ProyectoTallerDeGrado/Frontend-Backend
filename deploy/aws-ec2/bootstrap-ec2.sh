#!/usr/bin/env bash
# Prepara una instancia EC2 Ubuntu 24.04 recién creada (se ejecuta UNA vez, con sudo):
#   curl -fsSL https://raw.githubusercontent.com/<org>/<repo>/main/deploy/aws-ec2/bootstrap-ec2.sh | sudo bash
# o copiándolo con scp. Instala Docker, crea /opt/emprendeu y un swap de 2 GB.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Ejecútalo con sudo." >&2
  exit 1
fi
DEPLOY_USER="${SUDO_USER:-ubuntu}"

apt-get update -y
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
. /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
usermod -aG docker "$DEPLOY_USER"

# Logs de Docker acotados (el disco de la instancia es pequeño).
cat > /etc/docker/daemon.json <<'JSON'
{ "log-driver": "json-file", "log-opts": { "max-size": "10m", "max-file": "3" } }
JSON
systemctl restart docker

# Swap: margen para picos de memoria en una t3.medium (4 GB).
if ! swapon --show | grep -q /swapfile; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

mkdir -p /opt/emprendeu/secrets
chown -R "$DEPLOY_USER":"$DEPLOY_USER" /opt/emprendeu
chmod 700 /opt/emprendeu/secrets

echo "Listo. Cierra la sesión SSH y vuelve a entrar para usar docker sin sudo."
