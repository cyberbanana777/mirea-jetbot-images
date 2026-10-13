#!/usr/bin/env bash
# Разовый запуск контейнера без compose: ./start_container.sh
# Перед запуском разреши контейнеру окна на экране: xhost +local:
set -euo pipefail
cd "$(dirname "$0")"
source .env
sudo docker run \
	-it \
	--rm \
	--network host \
	--ipc host \
	--privileged \
	-e HOST_UID="$(id -u)" \
	-e HOST_GID="$(id -g)" \
	-e DISPLAY="${DISPLAY:-:0}" \
	-e QT_X11_NO_MITSHM=1 \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
	-v /dev:/dev \
	-v "$(pwd)/user_data/developer_ws":/home/ros/developer_ws \
	-v "$(pwd)/user_data/extra_files_to_container":/home/ros/extra_files_to_container \
	-v "$(pwd)/user_data/ros2_custom_config_setup":/home/ros/ros2_custom_config_setup \
	"registry.cookcloud.ru/jetbot_mirea/extra-humble-amd64-host:${VERSION}"
