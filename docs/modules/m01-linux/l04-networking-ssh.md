# 1.4 — Сеть в Linux, nftables, SSH

> **M01 · Этап 0 · 4 ч · 🟢 · артефакт:** `labs/m01-linux/l04-networking-ssh/`

## Цель

Настраивать сеть без NetworkManager-GUI, видеть открытые порты, писать простые правила firewall и безопасно ходить по SSH, включая проброс портов.

## Результат

- Настраиваете статический IP и маршрут через `ip`/`nmcli`.
- Объясняете вывод `ss -tulpn` и находите, какой процесс слушает порт.
- Пишете правило nftables и проверяете его.
- Настраиваете SSH-ключи, `~/.ssh/config` и локальный проброс.

## Теория

- `ip link` — интерфейсы, `ip addr` — адреса, `ip route` — маршруты. Всё, что делает GUI, делает эти три команды.
- `ss -tulpn` = TCP/UDP, listening, process, numeric. `-p` требует root для чужих процессов.
- nftables: таблица → цепочка → правило. `hook input` — входящий трафик, `policy drop` — запрет по умолчанию.
- SSH-ключ: приватный остаётся у вас, публичный — в `~/.ssh/authorized_keys` на сервере.
- `ssh -L` — локальный проброс (ваш порт → удалённый сервис), `-R` — обратный, `-D` — SOCKS.
- Парольная аутентификация SSH — главный вектор брутфорса; ключи + отключение пароля решают 90% проблемы.

## Лаборатория

### 1. Сеть

```bash
ip -brief link
ip -brief addr
ip route
resolvectl status | head -20
ss -tulpn
```

Ожидаемо: видите два lab-интерфейса, маршрут только туда, куда нужно, и список портов. Каждый порт вы можете объяснить.

### 2. Поднять сервис и проверить

На LNX01:

```bash
python3 -m http.server 8000 --bind 0.0.0.0
```

На attacker:

```bash
curl -I http://10.10.10.30:8000/
ss -tulpn | grep 8000
```

Ожидаемо: `HTTP/1.0 200 OK`, на цели виден процесс `python3`, слушающий `0.0.0.0:8000`.

### 3. Правило nftables

На attacker (тест, не постоянное правило):

```bash
sudo nft add table inet lab
sudo nft 'add chain inet lab input { type filter hook input priority 0; policy accept; }'
sudo nft add rule inet lab input tcp dport 8000 drop
sudo nft list table inet lab
```

Проверка с LNX01: `curl --max-time 3 http://10.10.10.50:8000/` — таймаут.

Удалить: `sudo nft delete table inet lab`.

### 4. SSH-ключи

```bash
ssh-keygen -t ed25519 -a 100 -C "lab@arch" -f ~/.ssh/lab_ed25519
ssh-copy-id -i ~/.ssh/lab_ed25519.pub user@10.10.10.30
ssh -i ~/.ssh/lab_ed25519 user@10.10.10.30 'id; hostname'
```

`~/.ssh/config`:

```
Host lnx01
    HostName 10.10.10.30
    User user
    IdentityFile ~/.ssh/lab_ed25519
    IdentitiesOnly yes
```

Проверка: `ssh lnx01 'uptime'`.

### 5. Проброс порта

На LNX01 запустите `python3 -m http.server 8000`. На attacker:

```bash
ssh -L 8080:127.0.0.1:8000 lnx01 -N
# в другом терминале
curl -I http://127.0.0.1:8080/
```

Ожидаемо: ответ 200. Порт 8080 на attacker ведёт на 8000 на LNX01. Это основа pivoting (M14).

## Атака и защита

- **Атака:** SSH с паролем и слабым паролем, exposed `0.0.0.0` сервисы, доверие по ключу без passphrase, `~/.ssh` с правами 777.
- **Детект:** `journalctl -u sshd` — множественные `Failed password`, вход с нового IP, `Accepted publickey` в нерабочее время.
- **Фикс:** `PasswordAuthentication no`, `PermitRootLogin no`, ключи с passphrase, fail2ban/sshguard, firewall deny inbound, `AllowUsers`.

## Самопроверка

- [ ] Чем `-L` отличается от `-R`?
- [ ] Почему `ss -p` без root показывает не всё?
- [ ] Что делает `policy drop` и почему после него нужен `ct state established`?
- [ ] Какие права должны быть на `~/.ssh` и `authorized_keys`?

## Дальше

[1.5 — Bash и охота на бэкдоры](l05-bash-forensics.md)
