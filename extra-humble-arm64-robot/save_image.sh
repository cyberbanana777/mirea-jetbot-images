#!/usr/bin/env bash
# Сохранение образа в файл для переноса на другое устройство: ./save_image.sh
set -euo pipefail
cd "$(dirname "$0")"
source .env
sudo docker save "registry.cookcloud.ru/jetbot_mirea/extra-humble-arm64-robot:${VERSION}" -o "extra-humble-arm64-robot-${VERSION}.tar"
sudo chown "$(id -u):$(id -g)" "extra-humble-arm64-robot-${VERSION}.tar"
echo "Сохранено: extra-humble-arm64-robot-${VERSION}.tar"
