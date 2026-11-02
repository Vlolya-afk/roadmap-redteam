# 2.1 — OSI, Ethernet, ARP

> **M02 · Этап 0 · 3 ч · 🟢 · артефакт:** `labs/m02-networking/l01-arp/`

## Цель

Понять, как данные упаковываются и как хост находит соседа по IP. ARP — фундамент L2-атак из M07.

## Результат

- Объясняете инкапсуляцию на примере `curl`.
- Читаете Ethernet-кадр в `tcpdump -e`.
- Показываете ARP-запрос/ответ и объясняете, почему он не защищён.

## Теория

- OSI: физика → канал → сеть → транспорт → сессия → представление → приложение. На практике — TCP/IP: link, internet, transport, application.
- Инкапсуляция: HTTP → TCP → IP → Ethernet. Каждый уровень добавляет заголовок.
- Ethernet-кадр: `dst MAC | src MAC | EtherType | payload | FCS`. MTU 1500 байт.
- ARP: «у кого 10.10.10.30? Скажи 10.10.10.50» — broadcast, ответ unicast. Кэш живёт минуты.
- ARP не аутентифицирован: любой может ответить. Отсюда ARP spoofing.
- MAC-адрес: 6 байт, первые 3 — OUI производителя (VMware — `00:0c:29`).

## Лаборатория

### 1. Таблица соседей

```bash
ip neigh
ping -c 2 10.10.10.30
ip neigh show 10.10.10.30
```

Ожидаемо: запись `10.10.10.30 dev <iface> lladdr 00:0c:29:xx:xx:xx REACHABLE`.

### 2. ARP в эфире

Терминал 1:

```bash
sudo tcpdump -i any -e -n arp
```

Терминал 2:

```bash
sudo ip neigh flush dev <iface>
ping -c 1 10.10.10.30
```

Ожидаемо в tcpdump:

```
Request who-has 10.10.10.30 tell 10.10.10.50
Reply 10.10.10.30 is-at 00:0c:29:...
```

Обратите внимание: запрос broadcast (`ff:ff:ff:ff:ff:ff`), ответ — уже unicast.

### 3. Ручной ARP

```bash
sudo arping -I <iface> -c 3 10.10.10.30
```

Ожидаемо: три ответа с MAC цели. `arping` работает на L2, даже если IP-связность сломана.

### 4. Подмена записи (демо)

```bash
sudo ip neigh replace 10.10.10.30 lladdr 00:11:22:33:44:55 dev <iface>
ip neigh show 10.10.10.30
ping -c 1 10.10.10.30   # не дойдёт
sudo ip neigh del 10.10.10.30 dev <iface>
```

Ожидаемо: пакеты уходят на несуществующий MAC, связь пропадает. Это ручная модель ARP spoofing; в M07 сделаем автоматически.

## Атака и защита

- **Атака:** ARP spoofing → MITM; MAC flooding → переполнение CAM-таблицы коммутатора; gratuitous ARP для подмены шлюза.
- **Детект:** `arpwatch`, алерты на смену MAC у шлюза, Dynamic ARP Inspection (DAI) на коммутаторе.
- **Фикс:** DAI + DHCP snooping, статические ARP для критичных узлов, сегментация, 802.1X.

## Самопроверка

- [ ] Почему ARP-запрос broadcast, а ответ unicast?
- [ ] Что произойдёт, если в ARP-кэше шлюза неверный MAC?
- [ ] Чем Ethernet-кадр отличается от IP-пакета?
- [ ] Как DAI понимает, какой MAC легитимный?

## Дальше

[2.2 — IP, подсети, маршрутизация](l02-ip-routing-nat.md)
