# jetbot-images: образы для робота jetbot_mirea и его ПК

Два образа на ROS2 Humble с репозиторием [mirea_jetbot_full](https://github.com/cyberbanana777/mirea_jetbot_full) на выбранном коммите. Оба строятся на базовых образах из репозитория **ros2-base-images**, поэтому DDS-конфиг, баннер, цветной терминал и сетевые утилиты те же (подробности в README того репозитория).

| Папка | Образ | Ubuntu | Железо | Что внутри |
|---|---|---|---|---|
| `extra-humble-amd64-host` | `jetbot:extra-humble-amd64-host` | 22.04 | ПК, amd64 | `base-humble-amd64` + mirea_jetbot_full + Gazebo, Nav2, slam-toolbox, RViz, Tk-GUI |
| `extra-humble-arm64-robot` | `jetbot:extra-humble-arm64-robot` | 22.04 | робот jetbot, arm64 | `base-humble-arm64` + mirea_jetbot_full, приводной уровень (ESP32, лидар, RealSense) |

```
.
├── extra-humble-amd64-host/    # + .env с REPO_COMMIT
└── extra-humble-arm64-robot/   # + .env с REPO_COMMIT
```

В каждой папке: `Dockerfile`, `docker-compose.yml`, `build_image.sh`, `start_container.sh`, `save_image.sh` / `load_image.sh`, `src/` (монтируется в `/developer_ws/src`), `files_to_container/` и `ros2_custom_config_setup/` (DDS-конфиг и окружение, правятся без пересборки).

## Откуда берётся базовый образ

`build_image.sh` ищет базу (`ros2:base-humble-amd64` для образа `extra-humble-amd64-host`, `ros2:base-humble-arm64` для образа `extra-humble-arm64-robot`) по порядку:

1. **локально**: собрана на этой машине в ros2-base-images или загружена через `load_image.sh`;
2. **из реестра**, если задан `REGISTRY`: `REGISTRY=registry.local:5000 ./build_image.sh` (или строка `REGISTRY=` в `.env`);
3. иначе сборка остановится с подсказкой.

## Сборка

```bash
./extra-humble-amd64-host/build_image.sh [коммит]    # ПК
./extra-humble-arm64-robot/build_image.sh [коммит]   # робот
```

Коммит `mirea_jetbot_full` берётся из аргумента, иначе из `REPO_COMMIT` в `.env` папки образа. Подробности про состав и запуск каждого образа — в README его папки.

## DDS между ПК и роботом

Оба образа используют CycloneDDS и один `ROS_DOMAIN_ID` (по умолчанию 0); настройка и отладка описаны в README образа `extra-humble-amd64-host` и в README ros2-base-images (`dds-check`).
