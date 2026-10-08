# jetbot:extra-humble-amd64-host

Образ для стационарного компьютера (amd64, Ubuntu 22.04): ROS2 Humble, репозиторий [mirea_jetbot_full](https://github.com/cyberbanana777/mirea_jetbot_full) на выбранном коммите, Gazebo, Nav2, slam-toolbox, RViz2, Tk-GUI настройки ПИД. Строится на `base-humble-amd64` (папка `base-humble-amd64` в репозитории ros2-base-images), поэтому DDS-конфиг, баннер, цветной терминал и сетевые утилиты те же. Драйверы реального робота здесь не запускаются: они работают в образе `extra-humble-arm64-robot`.

## Сборка

```bash
./build_image.sh            # коммит из .env (REPO_COMMIT)
./build_image.sh 5c048a1    # или любой другой коммит
```

Коммит передаётся как аргумент сборки `REPO_COMMIT` (короткий или полный хеш). При сборке репозиторий клонируется с GitHub, переключается на этот коммит (без `docs/` и `esp_firmware/`, чтобы не тянуть PDF и прошивки) и собирается в `/jetbot_ws`. Хеш собранного коммита лежит в `/jetbot_ws/COMMIT` и показывается в баннере. Смена коммита пересобирает только клонирование и `colcon build`, пакеты apt берутся из кэша. Базовый образ `base-humble-amd64` скрипт берёт локальный, а если его нет — скачивает из реестра (`REGISTRY=<реестр> ./build_image.sh`); без обоих сборка остановится с подсказкой.

Образ не соберётся, если после сборки не нашёлся какой-то из пакетов: все пакеты робота, `realsense_ros_gazebo`, `trajectory_maker`, `nav2_bringup`, `slam_toolbox`, `gazebo_ros`, `rmw_cyclonedds_cpp`. Пакет `simple_regulators_configurator_pkg` (Tk-GUI настройки ПИД) необязательный: его нет на коммите `5c048a1`, и тогда при сборке печатается предупреждение.

## Запуск

```bash
xhost +local:                          # разрешить контейнеру окна на экране (после перезагрузки повторить)
docker compose up -d
docker compose exec extra-humble-amd64-host bash
```

`DISPLAY` и `/tmp/.X11-unix` пробрасываются, окна Gazebo, RViz и Tk-GUI открываются на экране хоста. Для Gazebo на видеокарте NVIDIA раскомментируй `runtime: nvidia` в `docker-compose.yml` (нужен nvidia-container-toolkit). Проверка графики: `glxinfo -B`, `xeyes`.

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
```

Карты сохраняй в примонтированную папку, чтобы они не пропали вместе с контейнером: `ros2 run nav2_map_server map_saver_cli -f /files_to_container/map`. Свой код клади в `src/` рядом с этим README: он монтируется в `/developer_ws/src` и накладывается поверх `/jetbot_ws`.

## DDS между ПК и роботом

Оба образа используют CycloneDDS и один `ROS_DOMAIN_ID` (по умолчанию 0). Если ПК и робот в одной сети и мультикаст проходит, ничего настраивать не нужно. Иначе раскомментируй блок `<Peers>` в `ros2_custom_config_setup/cyclonedds.xml` на обеих сторонах и впиши IP другой стороны. Проверка: `dds-check`.
