#!/usr/bin/env bash
# Сохранение образа в файл для переноса на другое устройство: ./save_image.sh
set -euo pipefail
cd "$(dirname "$0")"
sudo docker save "jetbot:extra-humble-amd64-host" -o "jetbot-extra-humble-amd64-host.tar"
sudo chown "$(id -u):$(id -g)" "jetbot-extra-humble-amd64-host.tar"
echo "Сохранено: jetbot-extra-humble-amd64-host.tar"
