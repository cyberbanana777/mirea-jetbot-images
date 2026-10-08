#!/usr/bin/env bash
# Разовый запуск контейнера без compose: ./start_container.sh
# Рантайм: DOCKER_RUNTIME=nvidia ./start_container.sh (по умолчанию runc)
set -euo pipefail
cd "$(dirname "$0")"
sudo docker run \
	--runtime "${DOCKER_RUNTIME:-runc}" \
	-it \
	--rm \
	--network host \
	--ipc host \
	--privileged \
	-v /dev:/dev \
	-v "$(pwd)/src":/developer_ws/src \
	-v "$(pwd)/files_to_container":/files_to_container \
	-v "$(pwd)/ros2_custom_config_setup":/ros2_custom_config_setup \
	"jetbot:extra-humble-arm64-robot"
