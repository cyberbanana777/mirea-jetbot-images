# registry.cookcloud.ru/jetbot_mirea/extra-humble-amd64-host

Образ для стационарного компьютера (amd64, Ubuntu 22.04): ROS2 Humble, репозиторий [mirea_jetbot_full](https://github.com/cyberbanana777/mirea_jetbot_full) на выбранном коммите, Gazebo, Nav2, slam-toolbox, RViz2, Tk-GUI настройки ПИД (`simple_PID_configurator`). Строится на `registry.cookcloud.ru/base_images/ros2-base-humble-amd64` (репозиторий ros2-base-images), поэтому DDS-конфиг, баннер, цветной терминал и сетевые утилиты те же. Драйверы реального робота здесь не запускаются: они работают в образе `extra-humble-arm64-robot`.

**Актуальная версия: v1.0.2** (коммит `d8f5a6a`, [история изменений](CHANGELOG.md))

```bash
docker pull registry.cookcloud.ru/jetbot_mirea/extra-humble-amd64-host:v1.0.2
```

ПК и робот должны работать на одном коммите репозитория: образ робота `extra-humble-arm64-robot:v1.0.2` собран на том же `d8f5a6a`.

## Сборка

```bash
./build_image.sh            # коммит из .env (REPO_COMMIT)
./build_image.sh d8f5a6a    # или любой другой коммит
```

Версия образа (`VERSION`), версия базы (`BASE_VERSION`), коммит и `BUILD_JOBS` лежат в `.env`. Коммит передаётся как аргумент сборки `REPO_COMMIT` (короткий или полный хеш). При сборке репозиторий клонируется с GitHub, переключается на этот коммит (без `docs/` и `esp_firmware/`) и собирается в `/jetbot_ws`. Хеш собранного коммита лежит в `/jetbot_ws/COMMIT` и показывается в баннере. Смена коммита пересобирает только клонирование и `colcon build`, пакеты apt берутся из кэша. Базовый образ docker берёт локальный, а если его нет — скачивает из реестра.

Собирается весь репозиторий. Образ не соберётся, если после сборки не нашёлся какой-то из пакетов:

- пакеты робота: `serial_bridge_cpp`, `lidar_filter_cpp`, `sllidar_ros2`, `realsense_d435i_configs`, `web_regulators_configurator`, `completed_scripts_jetbot`, `jetbot_mirea_description`;
- симуляция и навигация: `realsense_ros_gazebo`, `trajectory_maker`, `nav2_bringup`, `slam_toolbox`, `gazebo_ros`;
- `rmw_cyclonedds_cpp`.

Пакеты `serial_bridge_cpp` и `lidar_filter_cpp` пришли на смену Python-пакетам `serial_bridge_package` и `lidar_filter`, а `realsense_d435i_configs` — на смену `realsense_pkg`. Поэтому старые коммиты, где новых пакетов ещё нет, этим Dockerfile не собрать — для них есть образ v1.0.1. Пакета `simple_regulators_configurator_pkg` в репозитории больше нет. Tk-GUI `simple_PID_configurator` — не ROS-пакет, а скрипт (colcon его пропускает), его зависимости (`python3-tk`, `matplotlib`, `pil`, `pyserial`) стоят в образе.

## Запуск

```bash
./set_host_ids.sh                      # один раз: UID/GID в .env
xhost +local:                          # разрешить контейнеру окна на экране (после перезагрузки повторить)
docker compose up -d
docker compose exec extra-humble-amd64-host bash
```

`DISPLAY` и `/tmp/.X11-unix` пробрасываются, окна Gazebo, RViz и Tk-GUI открываются на экране хоста. Для Gazebo на видеокарте NVIDIA раскомментируй `runtime: nvidia` в `docker-compose.yml` (нужен nvidia-container-toolkit). Проверка графики: `glxinfo -B`, `xeyes`.

В контейнер монтируется всё из `user_data/`: `developer_ws/` → `/home/ros/developer_ws`, `extra_files_to_container/` → `/home/ros/extra_files_to_container`, `ros2_custom_config_setup/` → `/home/ros/ros2_custom_config_setup`.

## Что запускать (по README репозитория)

Репозиторий лежит в `/jetbot_ws` и уже активирован в каждом терминале. Примеры:

```bash
# симуляция: Gazebo + RViz
ros2 launch jetbot_mirea_description gazebo.launch.py
# реальный робот (на роботе запущен образ `extra-humble-arm64-robot`): описание робота и RViz
ros2 launch completed_scripts_jetbot rviz_and_robot_description.launch.py
# картографирование и навигация
ros2 launch completed_scripts_jetbot mapping.launch.py config_choice:='1'
ros2 launch completed_scripts_jetbot navigation.launch.py config_choice:='1'
ros2 run teleop_twist_keyboard teleop_twist_keyboard
# Tk-GUI настройки ПИД: ESP32 подключена к ПК по USB, порт в config.py (SERIAL_PORT, по умолчанию /dev/ttyUSB0)
cd /jetbot_ws/src/mirea_jetbot_full/simple_PID_configurator && python3 fast_gui_tk.py
```

**Настройка ПИД на реальном роботе.** Удобнее веб-настройщик: он работает на роботе (образ `extra-humble-arm64-robot`, `enable_web_configurator:=True`), а на ПК достаточно браузера — `http://<IP робота>:8080`. Запускать в этом образе ничего не нужно.

**Отладка ESP32 с ПК.** Сообщения прошивки ESP32 (ошибки инициализации, I2C, перезагрузки) приходят по DDS: `ros2 topic echo /low_level/serial/text`.

Карты сохраняй в примонтированную папку, чтобы они не пропали вместе с контейнером: `ros2 run nav2_map_server map_saver_cli -f /home/ros/extra_files_to_container/map`. Свой код клади в `user_data/developer_ws/src`: он монтируется в `/home/ros/developer_ws/src` и накладывается поверх `/jetbot_ws`.

## DDS между ПК и роботом

Оба образа используют CycloneDDS и один `ROS_DOMAIN_ID` (по умолчанию 0). Если ПК и робот в одной сети и мультикаст проходит, ничего настраивать не нужно. Иначе раскомментируй блок `<Peers>` в `user_data/ros2_custom_config_setup/cyclonedds.xml` на обеих сторонах и впиши IP другой стороны. Проверка: `dds-check`.
