# jetbot:extra-humble-arm64-robot

Образ для робота jetbot (arm64, Ubuntu 22.04), приводной уровень: ROS2 Humble и репозиторий [mirea_jetbot_full](https://github.com/cyberbanana777/mirea_jetbot_full) на выбранном коммите. Запускает драйверы ESP32 (serial), лидара RPLidar и камеры RealSense D435i. Строится на `base-humble-arm64` (папка `base-humble-arm64` в репозитории ros2-base-images); локальный образ берётся первым, иначе скачивается из реестра (`REGISTRY=<реестр> ./build_image.sh`). Gazebo, Nav2, slam-toolbox и Tk-GUI сюда не входят: они в образе `extra-humble-amd64-host` на ПК.

## Сборка

```bash
./build_image.sh            # коммит из .env (REPO_COMMIT)
./build_image.sh 5c048a1    # или любой другой коммит
```

Коммит передаётся как аргумент сборки `REPO_COMMIT` (короткий или полный хеш). Репозиторий клонируется с GitHub на этот коммит (без `docs/` и `esp_firmware/`) и собирается в `/jetbot_ws`; хеш лежит в `/jetbot_ws/COMMIT` и показан в баннере. Собираются `serial_bridge_package`, `sllidar_ros2`, `lidar_filter`, `realsense_pkg`, `completed_scripts_jetbot`, `jetbot_mirea_description`. Пропускаются `realsense_ros_gazebo` и `trajectory_maker`. Если на выбранном коммите есть `simple_regulators_configurator_pkg` (Tk-GUI), он тоже соберётся, но без Tk запустить его на роботе не получится.

Параллелизм сборки: `BUILD_JOBS` в `.env` (по умолчанию 2, на Nano с 4 ГБ памяти не повышай). Nav2 и slam-toolbox на самом роботе по умолчанию выключены: `WITH_NAV2=1 ./build_image.sh` добавит их.

Сборка на Nano при нестабильном интернете и малой памяти долгая. Надёжнее собрать образ на ноутбуке под arm64 (`docker buildx` и QEMU) и перенести на робота через `save_image.sh` / `load_image.sh` или локальный registry.

## Запуск

```bash
docker compose up -d
docker compose exec extra-humble-arm64-robot bash
# или сразу драйверы (ESP32, лидар; камера: ENABLE_CAMERA=True):
docker compose --profile bringup up bringup
```

Рантайм по умолчанию `runc`. На Jetson с nvidia-рантаймом задай `DOCKER_RUNTIME=nvidia` (в `.env` или в окружении).

## Что нужно на хосте робота

- Симлинки `/dev/esp32` и `/dev/rplidar` создаются udev-правилами на хосте (шаги A2.2 и A3 из README репозитория). Контейнер видит `/dev` хоста целиком.
- Для RealSense на хосте нужны udev-правила librealsense, если камера должна открываться без root.
- Часы Jetson без RTC могут уходить: проверь `date`, иначе обмен с ПК и сборка (TLS) могут ломаться.

Свой код клади в `src/` рядом с этим README: он монтируется в `/developer_ws/src` и накладывается поверх `/jetbot_ws`.

## DDS между роботом и ПК

См. раздел в README образа `extra-humble-amd64-host`: CycloneDDS, один `ROS_DOMAIN_ID`, при необходимости `<Peers>` в `ros2_custom_config_setup/cyclonedds.xml`. Проверка: `dds-check`.
