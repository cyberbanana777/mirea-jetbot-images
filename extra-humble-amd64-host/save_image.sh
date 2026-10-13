#!/usr/bin/env bash
# Сохранение образа в файл для переноса на другое устройство: ./save_image.sh
set -euo pipefail
cd "$(dirname "$0")"
source .env
sudo docker save "registry.cookcloud.ru/jetbot_mirea/extra-humble-amd64-host:${VERSION}" -o "extra-humble-amd64-host-${VERSION}.tar"
sudo chown "$(id -u):$(id -g)" "extra-humble-amd64-host-${VERSION}.tar"
echo "Сохранено: extra-humble-amd64-host-${VERSION}.tar"
