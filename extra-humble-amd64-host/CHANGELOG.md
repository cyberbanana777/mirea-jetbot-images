# Changelog

Формат: [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/), версии `vMAJOR.MINOR.PATCH`.
Версия образа хранится в `.env` (`VERSION`).

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
