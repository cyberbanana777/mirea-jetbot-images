# Changelog

Формат: [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/), версии `vMAJOR.MINOR.PATCH`.
Версия образа хранится в `.env` (`VERSION`).

## [v1.0.2] — 2026-10-25

Образ: `registry.cookcloud.ru/jetbot_mirea/extra-humble-amd64-host:v1.0.2`. База: `registry.cookcloud.ru/base_images/ros2-base-humble-amd64:v1.0.1`.

### Изменено
- Репозиторий mirea_jetbot_full на коммите `d8f5a6a` (было `5c048a1`): C++-пакеты `serial_bridge_cpp` и `lidar_filter_cpp` вместо Python-пакетов `serial_bridge_package` и `lidar_filter`, `realsense_d435i_configs` вместо `realsense_pkg`, веб-настройщик ПИД `web_regulators_configurator`, одометрия 50 Гц, топик `/low_level/serial/text` с сообщениями прошивки ESP32.
- Проверка пакетов после сборки обновлена под новый состав: пакеты робота (`serial_bridge_cpp`, `lidar_filter_cpp`, `sllidar_ros2`, `realsense_d435i_configs`, `web_regulators_configurator`, `completed_scripts_jetbot`, `jetbot_mirea_description`), `realsense_ros_gazebo`, `trajectory_maker`, `nav2_bringup`, `slam_toolbox`, `gazebo_ros`, `rmw_cyclonedds_cpp`. Прежняя проверка искала удалённые `serial_bridge_package`, `lidar_filter`, `realsense_pkg`, и сборка на новом коммите падала.

### Удалено
- Проверка необязательного пакета `simple_regulators_configurator_pkg`: его в репозитории больше нет. Tk-GUI `simple_PID_configurator` — скрипт, а не ROS-пакет; его зависимости остаются в образе.

## [v1.0.1] — 2026-10-13

Образ: `registry.cookcloud.ru/jetbot_mirea/extra-humble-amd64-host:v1.0.1`. База: `registry.cookcloud.ru/base_images/ros2-base-humble-amd64:v1.0.1`.

### Добавлено
- Подгонка UID/GID пользователя `ros` под хост при старте контейнера (`HOST_UID`, `HOST_GID`): entrypoint наследуется от базового образа, образ универсален для любого UID. `set_host_ids.sh` записывает UID/GID в `.env`.
- Интерактивный `docker exec ... bash` автоматически переключается на `ros` (отключается `KEEP_ROOT=1`), чтобы файлы в `user_data/developer_ws` не становились root-овыми.
- Раскладка `user_data/`: `developer_ws/`, `extra_files_to_container/` и `ros2_custom_config_setup/` монтируются в `/home/ros`.
- `CHANGELOG.md`; версия образа и версия базы в `.env`; `chmod -R a+rX /jetbot_ws`, чтобы собранный репозиторий читался под любым UID.

### Изменено
- Имя образа: `registry.cookcloud.ru/jetbot_mirea/extra-humble-amd64-host:<версия>` (раньше `jetbot:extra-humble-amd64-host`).
- База берётся из реестра `registry.cookcloud.ru/base_images/ros2-base-humble-amd64:<BASE_VERSION>` (раньше локальный `ros2:base-humble-*` или `REGISTRY`); `build_image.sh` больше не ищет базу сам, это делает docker.
- Рабочее пространство участника перенесено из `/developer_ws` в `/home/ros/developer_ws` и монтируется целиком (`build/`, `install/` и `log/` остаются на хосте); `files_to_container` стал `extra_files_to_container`.
- Dockerfile заканчивается на `USER root` (раньше `USER ros`), иначе entrypoint не смог бы подогнать UID.
- Из `ros2_custom_config_setup/` убран `ros_entrypoint.sh`: он не использовался, entrypoint берётся из базового образа.
- Сокращены комментарии в Dockerfile и `setup.sh`.

## [v1.0.0]

Состояние до перехода на реестр и версионирование: ПК (amd64): Gazebo, Nav2, slam-toolbox, RViz2, Tk-GUI настройки ПИД. Образ `jetbot:extra-humble-amd64-host` собирался локально поверх `ros2:base-humble-*`.
