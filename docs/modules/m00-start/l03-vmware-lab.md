# 0.3 — Лаборатория на VMware: сети, цели, снапшоты

> **M00 · Этап 0 · 3 ч · 🟢 база · артефакт:** `labs/m00-start/l03-lab/`

## Цель

Собрать воспроизводимый стенд: две изолированные сети, атакующая ВМ, Linux-цель, снапшоты и бюджет ресурсов под 16 ГБ.

## Результат

- VMnet1 `192.168.56.0/24` и VMnet2 `10.10.10.0/24`, DHCP выключен.
- `attacker` с двумя NIC и статическими IP.
- `LNX01` (Ubuntu Server) в VMnet2, пингуется с attacker.
- Снапшоты `clean-install`, проверенный откат.
- Таблица ресурсов и схема в `lab-topology.md`.

## Теория

- Host-only сеть изолирует ВМ от LAN, но позволяет им видеть друг друга и хост.
- NAT нужен только для обновлений; цели в нём не нуждаются.
- Статические IP + выключенный DHCP = воспроизводимость после отката.
- Снапшот без памяти занимает меньше диска; для лаб этого достаточно.
- Клонирование доменных ВМ без sysprep даёт конфликт SID и имён.
- 16 ГБ хватает на 3 ВМ, если DC — Server Core, а не GUI.

## Лаборатория

### 1. Создать сети

`sudo vmware-netcfg`:

| Сеть | Тип | Подсеть | DHCP |
|---|---|---|---|
| VMnet1 | Host-only | 192.168.56.0/24 | off |
| VMnet2 | Host-only | 10.10.10.0/24 | off |
| VMnet8 | NAT | 192.168.150.0/24 | on |

Ожидаемо: в списке нет VMnet0/Bridged у ваших ВМ.

### 2. Настроить attacker

Два адаптера: VMnet1 (192.168.56.10/24) и VMnet2 (10.10.10.50/24). Шлюз по умолчанию — только через VMnet8/NAT, если он подключён третьим адаптером, либо не указывайте шлюз вовсе.

```bash
sudo nmcli connection modify "Wired connection 1" ipv4.method manual \
  ipv4.addresses 192.168.56.10/24 ipv4.never-default yes
sudo nmcli connection modify "Wired connection 2" ipv4.method manual \
  ipv4.addresses 10.10.10.50/24 ipv4.never-default yes
sudo nmcli connection up "Wired connection 1"
sudo nmcli connection up "Wired connection 2"
ip -brief addr
```

Ожидаемо: оба адреса на месте, `ip route` не содержит маршрута в домашнюю сеть.

### 3. Поднять LNX01

Ubuntu Server, 1 ГБ RAM, 1 vCPU, адаптер VMnet2. Настройте netplan:

```yaml
network:
  version: 2
  ethernets:
    ens33:
      dhcp4: false
      addresses: [10.10.10.30/24]
```

```bash
sudo netplan apply
ip -brief addr
```

Проверка с attacker:

```bash
ping -c 3 10.10.10.30
nmap -Pn -p 22 10.10.10.30
```

Ожидаемо: `22/tcp open ssh`. Если `filtered` — проверьте firewall цели (`sudo ufw status`).

### 4. Снапшот и откат

1. Выключите LNX01.
2. VMware → VM → Snapshot → Take Snapshot → имя `clean-install`.
3. Включите, создайте файл `touch /tmp/test`, выключите.
4. Revert to snapshot `clean-install`, включите, проверьте `ls /tmp/test` — файла нет.

### 5. Схема и бюджет

Заполните `labs/m00-start/l03-lab/lab-topology.md`: таблица ВМ (vCPU/RAM/диск/IP/сеть) и mermaid-схема. Проверьте:

```bash
free -h
```

Ожидаемо: при attacker + LNX01 + DC (если уже есть) свободно ≥ 2 ГБ.

## Атака и защита

- **Атака:** если у цели есть NAT-адаптер, она ходит в интернет и может быть достижима извне при пробросе портов. В учебной лабе это не нужно.
- **Детект:** неожиданные исходящие соединения с цели — сигнал, что вы случайно дали ей интернет.
- **Фикс:** один адаптер на цель, host-only, DHCP off, firewall по умолчанию deny inbound.

## Самопроверка

- [ ] Почему DHCP выключен, если статические IP можно выдать и через него?
- [ ] Что проверять после отката снапшота кроме файлов?
- [ ] Сколько ВМ можно держать одновременно при 16 ГБ и почему?
- [ ] Чем linked clone опасен для домена?

## Дальше

[Контрольная M00](exam.md)
