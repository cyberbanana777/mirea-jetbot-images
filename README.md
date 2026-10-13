# jetbot-images: образы для робота jetbot_mirea и его ПК

Два образа на ROS2 Humble с репозиторием [mirea_jetbot_full](https://github.com/cyberbanana777/mirea_jetbot_full) на выбранном коммите. Оба строятся на базовых образах из репозитория **ros2-base-images** (`registry.cookcloud.ru/base_images/ros2-base-humble-*`), поэтому DDS-конфиг, баннер, цветной терминал, сетевые утилиты и подгонка UID/GID те же (подробности в README того репозитория).

| Папка | Образ | Версия | Ubuntu | Железо | Что внутри |
|---|---|---|---|---|---|
| `extra-humble-amd64-host` | `registry.cookcloud.ru/jetbot_mirea/extra-humble-amd64-host` | v1.0.1 | 22.04 | ПК, amd64 | `ros2-base-humble-amd64` + mirea_jetbot_full + Gazebo, Nav2, slam-toolbox, RViz, Tk-GUI |
| `extra-humble-arm64-robot` | `registry.cookcloud.ru/jetbot_mirea/extra-humble-arm64-robot` | v1.0.1 | 22.04 | робот jetbot, arm64 | `ros2-base-humble-arm64` + mirea_jetbot_full, приводной уровень (ESP32, лидар, RealSense) |

Версия каждого образа хранится в `.env` его папки (`VERSION`), история изменений в `CHANGELOG.md` там же. Таблица выше показывает актуальные версии: при выпуске новой её нужно обновить.

## Готовые образы

Образы лежат в реестре `registry.cookcloud.ru` (при необходимости `docker login registry.cookcloud.ru`):

```bash
docker pull registry.cookcloud.ru/jetbot_mirea/extra-humble-amd64-host:v1.0.1   # ПК
docker pull registry.cookcloud.ru/jetbot_mirea/extra-humble-arm64-robot:v1.0.1    # робот
```

## Структура

```
.
├── extra-humble-amd64-host/
└── extra-humble-arm64-robot/
    ├── Dockerfile
    ├── .env                         # VERSION, BASE_VERSION, REPO_URL, REPO_COMMIT, BUILD_JOBS, HOST_UID/HOST_GID
    ├── CHANGELOG.md                 # подробная история версий
    ├── docker-compose.yml
    ├── build_image.sh               # сборка
    ├── start_container.sh           # разовый запуск без compose
    ├── set_host_ids.sh              # пишет HOST_UID/HOST_GID в .env
    ├── save_image.sh / load_image.sh
    └── user_data/                   # каждый элемент монтируется в /home/ros
        ├── developer_ws/            # свой код: src/ накладывается поверх /jetbot_ws
        ├── extra_files_to_container/  # карты, дампы и т. п.
        └── ros2_custom_config_setup/  # DDS-конфиг и окружение, правятся без пересборки
```

## Сборка

Нужен файл `.env` с коммитом `mirea_jetbot_full` (`REPO_COMMIT`). Базовый образ docker скачает из реестра сам (версия — `BASE_VERSION` в `.env`), либо возьмёт локальный.

```bash
./extra-humble-amd64-host/build_image.sh [коммит]    # ПК
./extra-humble-arm64-robot/build_image.sh [коммит]     # робот
```

Коммит берётся из аргумента, иначе из `REPO_COMMIT` в `.env`. Выпуск новой версии: поменять `VERSION` в `.env`, добавить запись в `CHANGELOG.md`, обновить таблицу выше, затем собрать и отправить образ:

```bash
cd extra-humble-arm64-robot
./build_image.sh
source .env && docker push registry.cookcloud.ru/jetbot_mirea/extra-humble-arm64-robot:$VERSION
```

Подробности про состав и запуск каждого образа — в README его папки.

## Пользователь и права на файлы

Контейнер стартует от root, entrypoint базового образа подгоняет пользователя `ros` под `HOST_UID`/`HOST_GID` и переходит на него, поэтому файлы в `user_data/developer_ws` принадлежат тебе на хосте. Один раз на машину выполни `./set_host_ids.sh` (запишет UID/GID в `.env`). Интерактивный `docker compose exec <имя> bash` сам переключается на `ros`; для команд без шелла нужен `-u ros`, для root — `-e KEEP_ROOT=1`.

## DDS между ПК и роботом

Оба образа используют CycloneDDS и один `ROS_DOMAIN_ID` (по умолчанию 0); настройка и отладка описаны в README образа `extra-humble-amd64-host` и в README ros2-base-images (`dds-check`).
