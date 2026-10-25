# Changelog

Формат: [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/), версии `vMAJOR.MINOR.PATCH`.
Версия образа хранится в `.env` (`VERSION`).

## [v1.0.2] — 2026-10-25

Образ: `registry.cookcloud.ru/jetbot_mirea/extra-humble-arm64-robot:v1.0.2`. База: `registry.cookcloud.ru/base_images/ros2-base-humble-arm64:v1.0.1`.

### Изменено
- Репозиторий mirea_jetbot_full на коммите `d8f5a6a` (было `5c048a1`): C++-пакеты `serial_bridge_cpp` и `lidar_filter_cpp` вместо Python-пакетов `serial_bridge_package` и `lidar_filter`, `realsense_d435i_configs` вместо `realsense_pkg`, веб-настройщик ПИД `web_regulators_configurator`, одометрия 50 Гц, топик `/low_level/serial/text` с сообщениями прошивки ESP32.
- Проверка пакетов после сборки обновлена под новый состав: `serial_bridge_cpp`, `lidar_filter_cpp`, `sllidar_ros2`, `realsense_d435i_configs`, `web_regulators_configurator`, `completed_scripts_jetbot`, `jetbot_mirea_description`, `realsense2_camera`, `rmw_cyclonedds_cpp`. Прежняя проверка искала удалённые пакеты.
- `build_image.sh` собирает через `docker buildx build --platform linux/arm64 --load`: образ можно собрать на ноутбуке amd64 с эмуляцией arm64.
- `BUILD_JOBS=8` в `.env` (сборка на ноутбуке); `MAKEFLAGS` больше не задаётся. На Nano ставь 2 или 1.
- `docker-compose.yml`: `/dev` хоста больше не монтируется целиком. Пробрасываются ESP32 и лидар по `/dev/serial/by-id/...` (в контейнере `/dev/esp32` и `/dev/rplidar`), `/dev/video0`–`/dev/video3` камеры D435i, каталог `/dev/bus/usb` (librealsense, переподключение камеры после аппаратного сброса) и сокет `/tmp/argus_socket` (nvargus-daemon).
- Сервис `bringup` принимает `CAMERA_MODE` (пресет камеры, по умолчанию `rgb_depth_pointcloud`) и `ENABLE_WEB_CONFIGURATOR` (по умолчанию `False`).

### Исправлено
- Пустая строка внутри `RUN bash -c '...'` со сборкой colcon (docker предупреждал, что пустые строки продолжения станут ошибкой).

## [v1.0.1] — 2026-10-13

Образ: `registry.cookcloud.ru/jetbot_mirea/extra-humble-arm64-robot:v1.0.1`. База: `registry.cookcloud.ru/base_images/ros2-base-humble-arm64:v1.0.1`.

### Добавлено
- Подгонка UID/GID пользователя `ros` под хост при старте контейнера (`HOST_UID`, `HOST_GID`): entrypoint наследуется от базового образа, образ универсален для любого UID. `set_host_ids.sh` записывает UID/GID в `.env`.
- Интерактивный `docker exec ... bash` автоматически переключается на `ros` (отключается `KEEP_ROOT=1`), чтобы файлы в `user_data/developer_ws` не становились root-овыми.
- Раскладка `user_data/`: `developer_ws/`, `extra_files_to_container/` и `ros2_custom_config_setup/` монтируются в `/home/ros`.
- `CHANGELOG.md`; версия образа и версия базы в `.env`; `chmod -R a+rX /jetbot_ws`, чтобы собранный репозиторий читался под любым UID.

### Изменено
- Имя образа: `registry.cookcloud.ru/jetbot_mirea/extra-humble-arm64-robot:<версия>` (раньше `jetbot:extra-humble-arm64-robot`).
- База берётся из реестра `registry.cookcloud.ru/base_images/ros2-base-humble-arm64:<BASE_VERSION>` (раньше локальный `ros2:base-humble-*` или `REGISTRY`); `build_image.sh` больше не ищет базу сам, это делает docker.
- Рабочее пространство участника перенесено из `/developer_ws` в `/home/ros/developer_ws` и монтируется целиком (`build/`, `install/` и `log/` остаются на хосте); `files_to_container` стал `extra_files_to_container`.
- Dockerfile заканчивается на `USER root` (раньше `USER ros`), иначе entrypoint не смог бы подогнать UID.
- Из `ros2_custom_config_setup/` убран `ros_entrypoint.sh`: он не использовался, entrypoint берётся из базового образа.
- Сокращены комментарии в Dockerfile и `setup.sh`.

## [v1.0.0]

Состояние до перехода на реестр и версионирование: робот (arm64), приводной уровень: драйверы ESP32, лидара RPLidar и камеры RealSense D435i. Образ `jetbot:extra-humble-arm64-robot` собирался локально поверх `ros2:base-humble-*`.
