# 2.5 — Захват и разбор трафика

> **M02 · Этап 0 · 3 ч · 🟢 · артефакт:** `labs/m02-networking/l05-capture/`

## Цель

Научиться записывать трафик, фильтровать его и доставать из него факты: кто, куда, с какими учётными данными.

## Результат

- Пишете pcap через `tcpdump` и читаете его в Wireshark/`tshark`.
- Строите фильтры по хосту, порту, флагам.
- Находите Basic-аутентификацию и декодируете её.
- Оформляете findings как для отчёта.

## Теория

- `tcpdump -w file.pcap` пишет, `-r` читает, `-i any` слушает все интерфейсы.
- BPF-фильтры: `host`, `net`, `port`, `tcp[tcpflags] & tcp-syn != 0`.
- Wireshark: Follow → TCP Stream, File → Export Objects → HTTP.
- `tshark -Y` — display-фильтры, `-T fields -e` — вывод полей.
- В pcap видны только незашифрованные протоколы; TLS скрывает содержимое, но не метаданные.
- Basic-аутентификация = `Authorization: Basic base64(user:pass)`, обратима тривиально.

## Лаборатория

### 1. Записать трафик

Терминал 1:

```bash
sudo tcpdump -i any -n -w /tmp/lab.pcap 'tcp port 8000 or icmp or udp port 53'
```

Терминал 2:

```bash
ping -c 3 10.10.10.30
dig example.com A >/dev/null
curl -s -u alice:Secret123 http://10.10.10.30:8000/ >/dev/null
```

Остановите tcpdump (Ctrl+C). Проверьте:

```bash
ls -lh /tmp/lab.pcap
sudo tcpdump -r /tmp/lab.pcap -n | head
```

Ожидаемо: ICMP, DNS и HTTP-пакеты.

### 2. Фильтры

```bash
sudo tcpdump -r /tmp/lab.pcap -n 'icmp'
sudo tcpdump -r /tmp/lab.pcap -n 'udp port 53'
sudo tcpdump -r /tmp/lab.pcap -n 'tcp port 8000'
sudo tcpdump -r /tmp/lab.pcap -n 'tcp[tcpflags] & tcp-syn != 0'
```

Ожидаемо: на каждый фильтр — только нужные пакеты.

### 3. Достать учётные данные

```bash
sudo tcpdump -r /tmp/lab.pcap -A -n 'tcp port 8000' | grep -i authorization
```

Ожидаемо:

```
Authorization: Basic YWxpY2U6U2VjcmV0MTIz
```

Декодируйте:

```bash
echo YWxpY2U6U2VjcmV0MTIz | base64 -d
```

Ожидаемо: `alice:Secret123`. Это и есть демонстрация: HTTP без TLS = пароль в открытом виде.

Через `tshark`:

```bash
tshark -r /tmp/lab.pcap -Y 'http.authorization' \
  -T fields -e http.host -e http.request.uri -e http.authorization
```

### 4. Follow stream

Откройте pcap в Wireshark: выберите HTTP-пакет → правой кнопкой → **Follow → TCP Stream**. Ожидаемо: весь запрос и ответ, включая заголовки.

### 5. Отчёт

Создайте `findings.md`:

```markdown
# Capture findings

| # | Что | Доказательство | Риск |
|---|---|---|---|
| 1 | Basic auth в cleartext | кадр 42, `Authorization: Basic ...` | Высокий: перехват пароля |
| 2 | DNS-запросы видны | `dig example.com` | Средний: утечка интересов |
```

## Атака и защита

- **Атака:** пассивный sniffing в своей сети, ARP spoof + перехват (M07), SSLstrip.
- **Детект:** неожиданные интерфейсы в promiscuous mode, ARP-аномалии, рост трафика к одному хосту.
- **Фикс:** TLS везде, HSTS, сегментация, запрет cleartext-протоколов, 802.1X.

## Самопроверка

- [ ] Чем `-w` отличается от перенаправления в файл?
- [ ] Почему TLS не спасает от анализа метаданных?
- [ ] Как найти в pcap все SYN-пакеты?
- [ ] Что делать, если pcap огромный и Wireshark тормозит?

## Дальше

[Контрольная M02](exam.md)
