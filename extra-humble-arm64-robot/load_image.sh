#!/usr/bin/env bash
# Загрузка образа из файла: ./load_image.sh
set -euo pipefail
cd "$(dirname "$0")"
sudo docker load -i "jetbot-extra-humble-arm64-robot.tar"
