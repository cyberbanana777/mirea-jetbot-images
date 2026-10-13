#!/usr/bin/env bash
# Разовый запуск контейнера без compose: ./start_container.sh
# Рантайм: DOCKER_RUNTIME=nvidia ./start_container.sh (по умолчанию runc)
set -euo pipefail
cd "$(dirname "$0")"
source .env
sudo docker run \
	--runtime "${DOCKER_RUNTIME:-runc}" \
	-it \
	--rm \
	--network host \
	--ipc host \
	--privileged \
	-e HOST_UID="$(id -u)" \
	-e HOST_GID="$(id -g)" \
	-v /run/udev:/run/udev:ro \
	-v /dev:/dev \
	-v "$(pwd)/user_data/developer_ws":/home/ros/developer_ws \
	-v "$(pwd)/user_data/extra_files_to_container":/home/ros/extra_files_to_container \
	-v "$(pwd)/user_data/ros2_custom_config_setup":/home/ros/ros2_custom_config_setup \
	"registry.cookcloud.ru/jetbot_mirea/extra-humble-arm64-robot:${VERSION}"
