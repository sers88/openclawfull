# OpenClaw Full — расширенный Docker-образ

Кастомный Docker-образ на базе [ghcr.io/openclaw/openclaw](https://github.com/openclaw/openclaw/pkgs/container/openclaw) с дополнительными системными утилитами для диагностики, автоматизации и управления серверами.

Образ публикуется в GitHub Container Registry: `ghcr.io/sers88/openclawfull`

---

## Состав пакета

### Базовые (уже в стандартном образе openclaw)

| Пакет | Назначение |
|-------|-----------|
| `ca-certificates` | SSL/TLS сертификаты |
| `curl` | HTTP-клиент |
| `git` | Контроль версий |
| `openssl` | Криптография, сертификаты |
| `procps` | `ps`, `top`, `free`, `kill` |
| `lsof` | Список открытых файлов |
| `python3` | Python runtime |
| `tini` | Init-система для контейнеров |
| `less`, `file`, `tar` | Базовые утилиты |

### SSH и передача файлов

| Пакет | Назначение |
|-------|-----------|
| `openssh-client` | SSH-клиент (`ssh`, `scp`, `ssh-keygen`) |
| `rsync` | Синхронизация файлов между серверами |
| `paramiko` (pip) | SSH через Python |

### Сетевая диагностика

| Пакет | Назначение |
|-------|-----------|
| `iputils-ping` | `ping` |
| `netcat-openbsd` | `nc` — проверка портов |
| `nmap` | Сканер сети |
| `dnsutils` | `dig`, `nslookup`, `host` |
| `iproute2` | `ip`, `ss`, `tc` |
| `tcpdump` | Захват сетевого трафика |
| `traceroute` | Трассировка маршрута |

### Обработка данных

| Пакет | Назначение |
|-------|-----------|
| `jq` | Парсинг JSON |
| `yq` (Go binary) | Парсинг YAML/JSON/XML/CSV/TOML |
| `ripgrep` | `rg` — быстрый поиск по содержимому файлов |
| `python3-pip` | Менеджер Python-пакетов |

### Системные утилиты

| Пакет | Назначение |
|-------|-----------|
| `strace` | Трассировка системных вызовов |
| `psmisc` | `killall`, `pstree`, `fuser` |
| `htop` | Мониторинг процессов |
| `nano`, `vim-tiny` | Текстовые редакторы |
| `unzip`, `zip` | Архивы |
| `wget` | Загрузка файлов |

---

## Установка на Unraid

### Предварительные требования

- Unraid 6.x+
- Включённый Docker (Settings → Docker → Enable Docker: Yes)
- Для приватного образа: доступ к терминалу Unraid для `docker login`

### Шаг 1. Открыть Docker tab

В WebGUI перейдите на вкладку **Docker** и нажмите **Add Container** (внизу страницы).

### Шаг 2. Базовые настройки

| Поле | Значение |
|------|---------|
| **Name** | `openclaw` |
| **Repository** | `ghcr.io/sers88/openclawfull:latest` |
| **Network Type** | `Bridge` |

### Шаг 3. Port Mappings

| Host Port | Container Port | Protocol |
|-----------|---------------|----------|
| `18789` | `18789` | TCP |
| `18790` | `18790` | TCP |

### Шаг 4. Volume Mappings

| Host Path | Container Path | Access Mode |
|-----------|---------------|-------------|
| `/mnt/user/appdata/openclaw` | `/home/node/.openclaw` | Read/Write |
| `/mnt/user/appdata/openclaw/workspace` | `/home/node/.openclaw/workspace` | Read/Write |
| `/mnt/user/appdata/openclaw-auth-profile-secrets` | `/home/node/.config/openclaw` | Read/Write |

> Host-пути создаются автоматически при первом запуске. Рекомендуется расположить `appdata` на cache pool.

### Шаг 5. Environment Variables

Нажмите **Add another Path, Port, Variable, Label or Device** и добавьте переменные:

| Variable Name | Value | Описание |
|---------------|-------|----------|
| `HOME` | `/home/node` | Домашняя директория |
| `OPENCLAW_HOME` | `/home/node` | Корень OpenClaw |
| `TERM` | `xterm-256color` | Терминал |
| `OPENCLAW_STATE_DIR` | `/home/node/.openclaw` | Директория состояния |
| `OPENCLAW_CONFIG_PATH` | `/home/node/.openclaw/openclaw.json` | Путь к конфигу |
| `OPENCLAW_CONFIG_DIR` | `/home/node/.openclaw` | Директория конфигов |
| `OPENCLAW_WORKSPACE_DIR` | `/home/node/.openclaw/workspace` | Workspace |
| `OPENCLAW_GATEWAY_BIND` | `lan` | Привязка к 0.0.0.0 (доступ из LAN) |
| `OPENCLAW_GATEWAY_TOKEN` | *ваш-токен* | Токен авторизации gateway |
| `TZ` | `Europe/Moscow` | Часовой пояс |

### Шаг 6. Extra Parameters

В поле **Extra Parameters** (видно в Advanced View) добавьте:

```
--init --cap-drop=NET_ADMIN --security-opt=no-new-privileges=true
```

Это включает:
- `--init` — tini как PID 1 (корректная обработка сигналов)
- `--cap-drop=NET_ADMIN` — снижение привилегий (безопасность)
- `--security-opt=no-new-privileges=true` — запрет повышения привилегий

> **Важно:** `NET_RAW` **не** удаляется из capabilities, чтобы работали `ping`, `nmap`, `tcpdump`, `traceroute`.

### Шаг 7. Создание контейнера

1. Нажмите **Apply** / **Create**
2. Дождитесь скачивания образа (первый раз ~500 MB)
3. После завершения нажмите **Done**

### Шаг 8. Включить автозапуск

На вкладке **Docker** переключите **Auto-Start** в положение **ON** для контейнера `openclaw`.

---

## Проверка установки

Нажмите на иконку контейнера → **Console** и выполните:

```bash
# Проверка gateway
curl -s http://127.0.0.1:18789/healthz

# Проверка сетевых утилит
ping -c 2 google.com
nc -zv google.com 443
dig google.com
ip addr show

# Проверка обработки данных
echo '{"test":1}' | jq .
echo 'key: value' | yq .
echo "hello world" | rg "hello"

# Проверка SSH
ssh -V

# Проверка Python
python3 -m pip show paramiko

# Проверка системных утилит
htop --version
strace --version
```

---

## Обновление образа

### На Unraid

1. Остановите контейнер: иконка → **Stop**
2. Удалите контейнер: иконка → **Remove** (выберите *только контейнер*, **не** удаляйте образ)
3. Откройте терминал Unraid и выполните:
   ```bash
   docker pull ghcr.io/sers88/openclawfull:latest
   ```
4. Перейдите на вкладку **Docker** → выберите контейнер из списка **Previous Containers** внизу страницы
5. Нажмите **Install** — настройки сохранятся из шаблона

### Альтернативный способ (через терминал Unraid)

```bash
docker stop openclaw
docker rm openclaw
docker pull ghcr.io/sers88/openclawfull:latest
```

Затем пересоздайте контейнер через WebGUI из Previous Containers.

---

## Приватный реестр (если образ приватный)

Если GHCR-репозиторий приватный, выполните на терминале Unraid:

```bash
docker login ghcr.io -u sers88
```

В качестве пароля используйте GitHub Personal Access Token (PAT) с правом `read:packages`.

---

## Установка через Docker Compose (не Unraid)

Для обычных серверов с Docker Compose:

```bash
cp .env.example .env
# Отредактируйте .env: укажите OPENCLAW_GATEWAY_TOKEN, TZ и т.д.
docker compose up -d --build
```

Или с готовым образом из GHCR:

```bash
docker compose up -d
```

---

## CI/CD

Образ автоматически собирается и публикуется через GitHub Actions:

- **Push в `main`** → сборка и пуш тега `latest`
- **Тег `v*`** → сборка и пуш с версией (например `v1.0.0`)
- **Платформы:** `linux/amd64`, `linux/arm64`
- **Registry:** `ghcr.io/sers88/openclawfull`

---

## Ссылки

- [OpenClaw — официальный проект](https://github.com/openclaw/openclaw)
- [Документация OpenClaw](https://docs.openclaw.ai)
- [Базовый образ на GHCR](https://github.com/openclaw/openclaw/pkgs/container/openclaw)
- [Документация Unraid Docker](https://docs.unraid.net/unraid-os/using-unraid-to/run-docker-containers/overview/)
