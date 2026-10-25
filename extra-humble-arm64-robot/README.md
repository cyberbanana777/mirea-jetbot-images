# registry.cookcloud.ru/jetbot_mirea/extra-humble-arm64-robot

Образ для робота jetbot (arm64, Ubuntu 22.04), приводной уровень: ROS2 Humble и репозиторий [mirea_jetbot_full](https://github.com/cyberbanana777/mirea_jetbot_full) на выбранном коммите. Запускает драйверы ESP32 (serial), лидара RPLidar и камеры RealSense D435i, а по желанию веб-настройщик ПИД. Строится на `registry.cookcloud.ru/base_images/ros2-base-humble-arm64` (репозиторий ros2-base-images). Gazebo, Nav2, slam-toolbox и Tk-GUI сюда не входят: они в образе `extra-humble-amd64-host` на ПК.

**Актуальная версия: v1.0.2** (коммит `d8f5a6a`, [история изменений](CHANGELOG.md))

```bash
docker pull registry.cookcloud.ru/jetbot_mirea/extra-humble-arm64-robot:v1.0.2
```

## Что внутри

Собираются пакеты репозитория:

| Пакет | Что делает |
|---|---|
| `serial_bridge_cpp` | связь с ESP32: `/cmd_vel` → ESP32, одометрия `/odom` (50 Гц), TF `odom → base_link`, скорости колёс, коэффициенты ПИД; текст прошивки — в `/low_level/serial/text` |
| `sllidar_ros2` | драйвер RPLidar → `/scan` |
| `lidar_filter_cpp` | обрезает скан по углу обзора → `/scan_filtered` |
| `realsense_d435i_configs` | запуск D435i с готовыми пресетами (`camera_mode`) |
| `web_regulators_configurator` | веб-страница настройки ПИД колёс (порт 8080) |
| `completed_scripts_jetbot` | общий launch `jetbot_sensors_and_motors.launch.py` |
| `jetbot_mirea_description` | URDF робота и TF |

Мост и фильтр лидара переписаны на C++ вместо прежних Python-пакетов `serial_bridge_package` и `lidar_filter`: Python-мост держал одно ядро Nano на 100 %. Пропускаются `realsense_ros_gazebo` и `trajectory_maker` (симуляция и цели навигации, они на ПК). Из apt ставится `realsense2_camera`.

Если после сборки какого-то пакета из таблицы (или `realsense2_camera`, `rmw_cyclonedds_cpp`) нет в окружении, образ не соберётся. Поэтому старые коммиты, где каких-то из этих пакетов ещё нет (до перехода на C++-пакеты и веб-настройщик), этим Dockerfile не собрать — для них есть образ v1.0.1.

## Сборка

```bash
./build_image.sh            # коммит из .env (REPO_COMMIT)
./build_image.sh d8f5a6a    # или любой другой коммит
```

Версия образа (`VERSION`), версия базы (`BASE_VERSION`), коммит и `BUILD_JOBS` лежат в `.env`. Коммит передаётся как аргумент сборки `REPO_COMMIT` (короткий или полный хеш). Репозиторий клонируется с GitHub на этот коммит (без `docs/` и `esp_firmware/`) и собирается в `/jetbot_ws`; хеш лежит в `/jetbot_ws/COMMIT` и показан в баннере.

`build_image.sh` собирает через `docker buildx build --platform linux/arm64 --load`, поэтому одинаково работает на самом роботе и на ноутбуке amd64. На ноутбуке нужна эмуляция arm64 (один раз: `docker run --privileged --rm tonistiigi/binfmt --install arm64`). Так надёжнее и быстрее, чем на Nano: собери на ноутбуке и отправь в реестр (`docker push`) или перенеси через `save_image.sh` / `load_image.sh`.

`BUILD_JOBS` в `.env` — число параллельных пакетов colcon. Сейчас стоит 8 (сборка на ноутбуке). **Если собираешь на самой Nano (4 ГБ памяти), поставь 2 или 1**, иначе компилятор упрётся в память.

Nav2 и slam-toolbox на самом роботе по умолчанию не ставятся: `WITH_NAV2=1 ./build_image.sh` добавит их.

## Запуск

```bash
./set_host_ids.sh                          # один раз: UID/GID в .env
docker compose up -d
docker compose exec extra-humble-arm64-robot bash
# или сразу драйверы (ESP32, лидар; камера и веб-настройщик по желанию):
docker compose --profile bringup up bringup
ENABLE_CAMERA=True CAMERA_MODE=rgb_depth docker compose --profile bringup up bringup
```

Переменные для `bringup` (в окружении или в `.env`):

| Переменная | По умолчанию | Аргумент launch |
|---|---|---|
| `ENABLE_CAMERA` | `False` | `enable_front_camera` |
| `CAMERA_MODE` | `rgb_depth_pointcloud` | `camera_mode`: `rgb_usb3`, `rgb_usb2`, `rgb_depth`, `rgb_depth_pointcloud` |
| `ENABLE_WEB_CONFIGURATOR` | `False` | `enable_web_configurator` |

Внутри контейнера то же самое руками:

```bash
ros2 launch completed_scripts_jetbot jetbot_sensors_and_motors.launch.py \
    enable_front_camera:=True camera_mode:=rgb_depth_pointcloud enable_web_configurator:=True
```

Рантайм по умолчанию `runc`. На Jetson с nvidia-рантаймом задай `DOCKER_RUNTIME=nvidia` (в `.env` или в окружении).

В контейнер монтируется всё из `user_data/`: `developer_ws/` → `/home/ros/developer_ws`, `extra_files_to_container/` → `/home/ros/extra_files_to_container`, `ros2_custom_config_setup/` → `/home/ros/ros2_custom_config_setup`.

## Веб-настройщик ПИД

С `enable_web_configurator:=True` на роботе поднимается страница `http://<IP робота>:8080` — открывай её с ноутбука или телефона в той же сети, ROS на них не нужен. На странице: команды движения, чтение и запись коэффициентов ПИД (в ОЗУ или во flash ESP32), ступенчатый тест с показателями качества, графики. Контейнер работает с `network_mode: host`, поэтому порт пробрасывать не надо. Порт меняется аргументом `web_configurator_port`. Подробно — в README пакета `web_regulators_configurator`.

## Отладка ESP32

Всё, что прошивка ESP32 печатает в serial вне кадров протокола (ошибки инициализации и I2C, перезагрузки), мост публикует в топик и пишет в лог как `ESP32: ...`:

```bash
ros2 topic echo /low_level/serial/text
```

Прошивка ESP32 загружается только по USB: обновление по воздуху (OTA) в прошивке 2.2.0 убрано. Прошивка в образ не входит (`esp_firmware/` не клонируется).

## Устройства

`/dev` хоста целиком в контейнер не монтируется. В `docker-compose.yml` пробрасываются:

| На хосте | В контейнере | Что это |
|---|---|---|
| `/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0` | `/dev/esp32` | ESP32 (CH340) |
| `/dev/serial/by-id/usb-Silicon_Labs_CP2102_USB_to_UART_Bridge_Controller_0001-if00-port0` | `/dev/rplidar` | RPLidar (CP2102) |
| `/dev/video0` … `/dev/video3` | те же | видеопотоки D435i |
| `/dev/bus/usb` (каталог) | тот же | USB-доступ librealsense (камера, IMU) |
| `/run/udev` (только чтение) | тот же | описание устройств для librealsense |
| `/tmp/argus_socket` | тот же | сокет nvargus-daemon для CSI-камер Jetson |

- Пути `by-id` не зависят от того, в каком порядке подключены USB-устройства. **На другом роботе адаптеры могут называться иначе:** проверь `ls -l /dev/serial/by-id/` и поправь пути в `docker-compose.yml`.
- Число видеоустройств зависит от камеры и ядра (у робота `mirea_jetbot_2` их 4: `ls /dev/video*`). Если их больше, допиши в `devices`.
- `/dev/bus/usb` смонтирован каталогом, поэтому после аппаратного сброса камеры (она переподключается по USB) librealsense видит её снова без перезапуска контейнера.
- **Устройства из `devices` берутся на момент старта контейнера.** Если ESP32 или лидар подключили после старта или переподключили и он получил другой `ttyUSB`, перезапусти контейнер (`docker compose restart`).
- **`/tmp/argus_socket` должен существовать на хосте**, иначе контейнер не запустится. Сокет создаёт `nvargus-daemon` (JetPack). Если CSI-камер нет и демон не запущен, удали этот блок из `docker-compose.yml`.
- `start_container.sh` (разовый запуск без compose) по-прежнему монтирует `/dev` целиком.

## Что нужно на хосте робота

- Для RealSense на хосте нужны udev-правила librealsense, если камера должна открываться без root.
- Часы Jetson без RTC могут уходить: проверь `date`, иначе обмен с ПК и сборка (TLS) могут ломаться.

Свой код клади в `user_data/developer_ws/src`: он монтируется в `/home/ros/developer_ws/src` и накладывается поверх `/jetbot_ws`.

## DDS между роботом и ПК

См. раздел в README образа `extra-humble-amd64-host`: CycloneDDS, один `ROS_DOMAIN_ID`, при необходимости `<Peers>` в `user_data/ros2_custom_config_setup/cyclonedds.xml`. Проверка: `dds-check`.
