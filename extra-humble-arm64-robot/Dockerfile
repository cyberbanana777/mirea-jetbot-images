# ============================================================================
#  Extra, робот: ROS2 Humble на роботе (arm64) + mirea_jetbot_full, приводной уровень  ·  jetbot:extra-humble-arm64-robot
#
#  Запускается на роботе jetbot: драйверы ESP32 (serial), лидара RPLidar и камеры RealSense D435i.
#  Gazebo, Nav2 и Tk-GUI не входят (они на ПК, образ extra-humble-amd64-host).
#  Строится поверх базового образа base-humble-arm64 (там ROS2 Humble, CycloneDDS 0.10, DDS-конфиг,
#  баннер, цветной терминал, сетевые утилиты, пользователь ros).
#  Репозиторий https://github.com/cyberbanana777/mirea_jetbot_full клонируется при сборке на коммит REPO_COMMIT и собирается в /jetbot_ws.
#
#  Сборка: ./build_image.sh [коммит]   (по умолчанию коммит из .env)
# ============================================================================

# === 1. Базовый образ ===
ARG BASE_IMAGE=ros2:base-humble-arm64
FROM ${BASE_IMAGE}

# === 2. Зависимости репозитория (apt) ===
# Состав взят из init_scripts/install_dependensies_jetbot.bash репозитория: realsense2-camera,
# compressed-image-transport, pyserial (в виде пакета apt). Дополнительно: xacro, robot_state_publisher и
# joint_state_publisher для описания робота и teleop_twist_keyboard для езды с клавиатуры.
# Gazebo, Nav2 и slam-toolbox на роботе не нужны (они на ПК, образ extra-humble-amd64-host). Если всё же нужны Nav2 и slam-toolbox,
# собери с --build-arg WITH_NAV2=1.
USER root
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ros-humble-realsense2-camera ros-humble-compressed-image-transport ros-humble-image-transport \
    ros-humble-xacro ros-humble-robot-state-publisher ros-humble-joint-state-publisher \
    ros-humble-teleop-twist-keyboard \
    python3-serial \
    && rm -rf /var/lib/apt/lists/*

# Необязательно: Nav2 и slam-toolbox на самом роботе (по умолчанию выключено).
ARG WITH_NAV2=0
RUN if [ "${WITH_NAV2}" = "1" ]; then \
        apt-get update && apt-get install -y --no-install-recommends \
            ros-humble-slam-toolbox ros-humble-nav2-map-server ros-humble-navigation2 ros-humble-nav2-bringup \
        && rm -rf /var/lib/apt/lists/*; \
    fi

# === 3. Исходники репозитория на нужном коммите ===
# REPO_COMMIT — хеш коммита (короткий или полный), обязательный аргумент сборки. ARG стоит после
# установки пакетов: смена коммита пересобирает только этот и следующие шаги, apt-слои берутся из кэша.
# Клонирование частичное (--filter=blob:none) и без docs/ и esp_firmware/ (PDF и прошивки в образе
# не нужны): качаются только нужные файлы, а короткий хеш коммита при этом разрешается как обычно.
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

# === 4. Сборка рабочего пространства ===
# BUILD_JOBS — число параллельных задач (на Jetson/arm64 с малой памятью оставь 2 или 1).
# Папки с COLCON_IGNORE в репозитории (development, esp_firmware, init_scripts, simple_PID_configurator)
# colcon пропускает сам.
RUN bash -c 'set -eo pipefail; source /opt/ros/humble/setup.bash; cd /jetbot_ws; \
    export MAKEFLAGS="-j${BUILD_JOBS}"; \
    colcon build --parallel-workers "${BUILD_JOBS}" --cmake-args -DCMAKE_BUILD_TYPE=Release --packages-skip realsense_ros_gazebo trajectory_maker'

# jetbot_mirea_description при активации подключает /usr/share/gazebo/setup.sh. Если Gazebo в образе нет
# (или файла нет), строка без проверки обрывала бы entrypoint (там set -e). Делаем её безопасной.
RUN find /jetbot_ws/install -type f -name 'jetbot_mirea_description_model_path.*' \
        -exec sed -i 's#^source /usr/share/gazebo/setup.sh#if [ -f /usr/share/gazebo/setup.sh ]; then . /usr/share/gazebo/setup.sh; fi#' {} +

# === 5. Проверка результата ===
# Образ не соберётся, если какого-то пакета нет в окружении.
RUN bash -c 'set -eo pipefail; source /opt/ros/humble/setup.bash; source /jetbot_ws/install/setup.bash; \
    for p in serial_bridge_package sllidar_ros2 lidar_filter realsense_pkg completed_scripts_jetbot jetbot_mirea_description realsense2_camera rmw_cyclonedds_cpp; do \
        ros2 pkg prefix "$p" > /dev/null || { echo "ОШИБКА: пакет $p не найден"; exit 1; }; \
    done; echo "Все пакеты на месте"'

WORKDIR /developer_ws
# ENTRYPOINT и CMD наследуются от базового образа.
