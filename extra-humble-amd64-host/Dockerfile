# Extra, хост: ROS2 Humble на ПК (amd64) + mirea_jetbot_full + Gazebo + Nav2
# registry.cookcloud.ru/jetbot_mirea/extra-humble-amd64-host
#
# Стационарный компьютер: симуляция в Gazebo, SLAM и навигация (Nav2), RViz, Tk-GUI настройки ПИД.
# Драйверы реального робота работают в образе extra-humble-arm64-robot.
# Строится на ros2-base-humble-amd64 (ROS2 Humble, CycloneDDS 0.10, DDS-конфиг, баннер,
# сетевые утилиты, пользователь ros, entrypoint с подгонкой UID/GID).
# Репозиторий mirea_jetbot_full клонируется на коммит REPO_COMMIT и собирается в /jetbot_ws.
#
# Сборка: ./build_image.sh [коммит]   (по умолчанию коммит из .env)

ARG BASE_IMAGE=registry.cookcloud.ru/base_images/ros2-base-humble-amd64:v1.0.1
FROM ${BASE_IMAGE}

# Зависимости из init_scripts/install_dependensies_host.bash репозитория (пакетами apt вместо pip),
# плюс rviz2, compressed-image-transport, python3-tk (Tk-GUI ПИД), mesa-utils и x11-apps (glxinfo, xeyes).
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ros-humble-slam-toolbox \
    ros-humble-nav2-map-server ros-humble-navigation2 ros-humble-nav2-bringup \
    ros-humble-xacro ros-humble-robot-state-publisher ros-humble-joint-state-publisher \
    ros-humble-rviz2 \
    ros-humble-gazebo-ros-pkgs ros-humble-gazebo-ros ros-humble-gazebo-plugins ros-humble-gazebo-dev \
    gazebo libgazebo-dev \
    ros-humble-teleop-twist-keyboard \
    ros-humble-compressed-image-transport ros-humble-image-transport ros-humble-camera-info-manager \
    python3-serial python3-matplotlib python3-pil python3-pil.imagetk python3-tk \
    mesa-utils x11-apps \
    && rm -rf /var/lib/apt/lists/*

# Исходники на нужном коммите. ARG после apt: смена коммита не пересобирает пакеты.
# Клонирование частичное и без docs/ и esp_firmware/ (PDF и прошивки не нужны).
ARG REPO_URL=https://github.com/cyberbanana777/mirea_jetbot_full
ARG REPO_COMMIT
ARG BUILD_JOBS=2
RUN mkdir -p /jetbot_ws/src && chown -R ros:ros /jetbot_ws
USER ros
WORKDIR /jetbot_ws
RUN test -n "${REPO_COMMIT}" || { echo "ОШИБКА: не задан REPO_COMMIT (--build-arg REPO_COMMIT=<хеш>)" >&2; exit 1; } && \
    git clone --filter=blob:none --no-checkout "${REPO_URL}" /tmp/jetbot_repo && \
    cd /tmp/jetbot_repo && \
    git sparse-checkout init --no-cone && \
    git sparse-checkout set '/*' '!/docs/' '!/esp_firmware/' && \
    git checkout --detach "${REPO_COMMIT}" && \
    git rev-parse HEAD > /jetbot_ws/COMMIT && \
    echo "Репозиторий на коммите: $(cat /jetbot_ws/COMMIT)" && \
    mkdir -p /jetbot_ws/src/mirea_jetbot_full && \
    cp -a /tmp/jetbot_repo/. /jetbot_ws/src/mirea_jetbot_full/ && \
    rm -rf /jetbot_ws/src/mirea_jetbot_full/.git /tmp/jetbot_repo
LABEL jetbot.repo.url="${REPO_URL}" jetbot.repo.commit="${REPO_COMMIT}"

# Сборка (папки с COLCON_IGNORE colcon пропускает сам)
RUN bash -c 'set -eo pipefail; source /opt/ros/humble/setup.bash; cd /jetbot_ws; \
    export MAKEFLAGS="-j${BUILD_JOBS}"; \
    colcon build --parallel-workers "${BUILD_JOBS}" --cmake-args -DCMAKE_BUILD_TYPE=Release'

# jetbot_mirea_description подключает /usr/share/gazebo/setup.sh; без проверки это обрывает entrypoint (set -e)
RUN find /jetbot_ws/install -type f -name 'jetbot_mirea_description_model_path.*' \
        -exec sed -i 's#^source /usr/share/gazebo/setup.sh#if [ -f /usr/share/gazebo/setup.sh ]; then . /usr/share/gazebo/setup.sh; fi#' {} +

# Проверка: обязательных пакетов нет в окружении — образ не соберётся; необязательных — только предупреждение
RUN bash -c 'set -eo pipefail; source /opt/ros/humble/setup.bash; source /jetbot_ws/install/setup.bash; \
    for p in serial_bridge_package sllidar_ros2 lidar_filter realsense_pkg completed_scripts_jetbot jetbot_mirea_description realsense_ros_gazebo trajectory_maker nav2_bringup slam_toolbox gazebo_ros rmw_cyclonedds_cpp; do \
        ros2 pkg prefix "$p" > /dev/null || { echo "ОШИБКА: пакет $p не найден"; exit 1; }; \
    done; \
    for p in simple_regulators_configurator_pkg; do \
        ros2 pkg prefix "$p" > /dev/null 2>&1 && echo "Есть необязательный пакет: $p" || echo "ПРЕДУПРЕЖДЕНИЕ: на коммите $(cat /jetbot_ws/COMMIT) нет необязательного пакета $p"; \
    done; \
    echo "Все обязательные пакеты на месте"'

# Возвращаем root: entrypoint базового образа стартует от root, подгоняет UID/GID и переходит на ros.
# /jetbot_ws читается любым UID, поэтому после смены UID пользователя ничего перенастраивать не нужно.
USER root
RUN chmod -R a+rX /jetbot_ws
WORKDIR /home/ros/developer_ws
# ENTRYPOINT и CMD наследуются от базового образа.
