#!/usr/bin/env bash
# Разовый запуск контейнера без compose: ./start_container.sh
# Перед запуском разреши контейнеру окна на экране: xhost +local:
set -euo pipefail
cd "$(dirname "$0")"
sudo docker run \
	-it \
	--rm \
	--network host \
	--ipc host \
	--privileged \
	-e DISPLAY="${DISPLAY:-:0}" \
	-e QT_X11_NO_MITSHM=1 \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
	-v /dev:/dev \
	-v "$(pwd)/src":/developer_ws/src \
	-v "$(pwd)/files_to_container":/files_to_container \
	-v "$(pwd)/ros2_custom_config_setup":/ros2_custom_config_setup \
	"jetbot:extra-humble-amd64-host"
