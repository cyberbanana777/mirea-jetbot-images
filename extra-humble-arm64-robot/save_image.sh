#!/usr/bin/env bash
# Сохранение образа в файл для переноса на другое устройство: ./save_image.sh
set -euo pipefail
cd "$(dirname "$0")"
sudo docker save "jetbot:extra-humble-arm64-robot" -o "jetbot-extra-humble-arm64-robot.tar"
sudo chown "$(id -u):$(id -g)" "jetbot-extra-humble-arm64-robot.tar"
echo "Сохранено: jetbot-extra-humble-arm64-robot.tar"
