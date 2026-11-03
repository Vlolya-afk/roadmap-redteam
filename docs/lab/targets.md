# Цели и уязвимые приложения

Все цели — **локальные** или легальные полигоны. Никаких «соседних сайтов».

## Что поднять в первую очередь

| Цель | Тип | RAM | Когда нужна | Где |
|---|---|---:|---|---|
| DVWA | Docker | ~200 МБ | M04, M08 | `vulnerables/web-dvwa` |
| OWASP Juice Shop | Docker | ~300 МБ | M08, M09 | `bkimminich/juice-shop` |
| OWASP WebGoat | Docker | ~400 МБ | M08 | `webgoat/webgoat` |
| crAPI | Docker Compose | ~1.5 ГБ | M08 (API) | OWASP crAPI |
| Ubuntu Server | ВМ | 1 ГБ | M01, M02, M07, M10 | ubuntu.com |
| Metasploitable2 | ВМ | 512 МБ | M07, M09 | VulnHub |
| Windows Server + WS | ВМ | 6 ГБ | M05, M10–M12 | Microsoft Eval |
| GOAD | Несколько ВМ | 16–24 ГБ | M11 (позже) | Orange Cyberdefense |
| kind / minikube | Docker | 2–4 ГБ | M16 | kind.sigs.k8s.io |

## Docker-цели

```bash
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"    # перелогиниться

docker run -d --name dvwa   -p 8080:80   vulnerables/web-dvwa
docker run -d --name juice  -p 3000:3000 bkimminich/juice-shop
docker run -d --name webgoat -p 8081:8080 webgoat/webgoat
docker run -d --name bwapp  -p 8082:80   raesene/bwapp
```

Проверка:

```bash
docker ps
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8080/
```

DVWA: `admin` / `password`, затем **Setup → Create/Reset Database**, Security level = `low` для первых лаб.

> [!NOTE]
> **Docker и host-only**
> Контейнеры на хосте доступны по `127.0.0.1`. Если атакуете из ВМ `attacker`, публикуйте порты на IP хоста в VMnet1 (`-p 192.168.56.1:8080:80`) или поднимайте контейнеры внутри `docker-host` (10.10.10.40) и открывайте порты в VMnet2.

### Compose для web-полигона

`labs/web-targets/docker-compose.yml`:

```yaml
services:
  dvwa:
    image: vulnerables/web-dvwa
    ports: ["8080:80"]
    restart: unless-stopped

  juice:
    image: bkimminich/juice-shop
    ports: ["3000:3000"]
    restart: unless-stopped

  webgoat:
    image: webgoat/webgoat
    ports: ["8081:8080"]
    restart: unless-stopped

  bwapp:
    image: raesene/bwapp
    ports: ["8082:80"]
    restart: unless-stopped
```

```bash
docker compose up -d
docker compose down
```

## Windows-цели

Официальные evaluation-образы:

- Windows Server 2022/2025 Evaluation — 180 дней, полноценный AD.
- Windows 11 Enterprise Evaluation — 90 дней.

После установки:

```powershell
# Отключить сон и быстрый старт (мешают снапшотам)
powercfg /change standby-timeout-ac 0
powercfg /hibernate off

# Отключить автоматические перезагрузки (на время лабы)
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name NoAutoRebootWithLoggedOnUsers -Value 1
```

**Defender:** для лаб M10–M11 его можно ослабить, но для M12 он должен быть **включён** — иначе вы тренируетесь против пустоты. Никогда не отключайте Defender на реальной машине «для удобства».

## AD-полигон

Два пути:

1. **Собрать вручную** (M05): DC01 + WS01, домен `lab.local`, 5–8 пользователей, 2–3 сервисные учётки, одна с SPN. Этого хватает для 80% лаб.
2. **GOAD** (Game of Active Directory): готовый лес из нескольких доменов, ~16–24 ГБ RAM. Поднимать после M11, когда есть 32 ГБ или отдельный сервер. Для 16 ГБ — не начинайте.
3. **BadBlood** / `vulnerable-AD`: скрипты, которые наполняют домен пользователями, группами и ACL-дырами. Лёгкий вариант для 16 ГБ.

Минимальный набор для M11:

| Объект | Зачем |
|---|---|
| `svc_sql` с SPN `MSSQLSvc/sql01.lab.local:1433` | Kerberoasting |
| `svc_backup` без предаутентификации | AS-REP roasting |
| `helpdesk` с `GenericAll` на OU | ACL abuse |
| `WS01$` с unconstrained delegation | Delegation |
| ADCS с шаблоном `User` + enrollee supplies subject | ESC1 |
| Доверие `lab.local` ↔ `dev.lab.local` (опц.) | Trusts |

## Легальные полигоны

| Полигон | Плюсы | Минусы |
|---|---|---|
| VulnHub | Бесплатно, офлайн | Старые машины, мало AD |
| Hack The Box | Современно, рейтинг, AD-машины | Платно, VPN, нельзя делиться флагами |
| TryHackMe | Хорошо для старта | Много «кнопочных» комнат |
| PortSwigger Web Security Academy | Лучший бесплатный web-тренинг | Только web |
| PentesterLab | Аккуратные web/API лабы | Платно |
| GOAD | Реалистичный AD | Тяжёлый |
| Blue Team Labs Online | Детект и форензика | Платно |

> [!CAUTION]
> **Не смешивайте контуры**
> HTB/THM VPN и ваша host-only лаборатория — разные вещи. Не сканируйте полигон из лаборатории и не подключайте лабораторию к VPN. Один контур — один scope.

## Данные и чистота

- Пароли в лабах: `Passw0rd!`, `lab.local` — **не используйте** реальные.
- Перед публикацией writeup: уберите хэши, токены, приватные ключи, реальные IP.
- Дампы и pcaps держите в `labs/**/captures/`, они в `.gitignore`.
- После лабы — откат снапшота или `docker compose down -v`.
