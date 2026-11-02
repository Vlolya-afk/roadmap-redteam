# 2.3 — TCP/UDP, порты, ручное сканирование

> **M02 · Этап 0 · 4 ч · 🟢 · артефакт:** `labs/m02-networking/l03-tcp/`

## Цель

Понять TCP-сессию до флагов и научиться отличать `open`, `closed` и `filtered` без автоматических сканеров.

## Результат

- Читаете handshake в tcpdump и объясняете каждый флаг.
- Понимаете, почему `-sS` быстрее и «тише», чем `-sT`.
- Различаете RST, таймаут и ICMP unreachable.

## Теория

- TCP: 3-way handshake `SYN → SYN/ACK → ACK`, затем данные, затем `FIN/ACK` или `RST`.
- Флаги: SYN, ACK, FIN, RST, PSH, URG. `RST` = «закрыто/не принимаю».
- Состояния: `LISTEN`, `SYN-SENT`, `ESTABLISHED`, `TIME-WAIT`, `CLOSE-WAIT`.
- UDP без состояния: нет handshake, ответа может не быть вообще.
- `closed` = пришёл RST; `filtered` = таймаут или ICMP admin prohibited.
- `-sS` (SYN scan) не завершает handshake; `-sT` использует полный `connect()`.

## Лаборатория

### 1. Слушатель и клиент

На LNX01:

```bash
nc -lvnp 4444
```

На attacker:

```bash
nc -v 10.10.10.30 4444
```

Одновременно на attacker:

```bash
sudo tcpdump -i any -n 'tcp port 4444' -c 10
```

Ожидаемо: `Flags [S]`, `Flags [S.]`, `Flags [.]`, затем `[P.]`. Расшифруйте: SYN, SYN+ACK, ACK, PSH+ACK.

### 2. Состояния

```bash
ss -tan | head -20
ss -tan state established
ss -tulpn
```

Ожидаемо: видите `ESTABLISHED` для nc и `LISTEN` для sshd.

### 3. Три состояния порта

На LNX01:

```bash
# открытый
python3 -m http.server 8001 &
# закрытый — ничего не слушает
# filtered — правило nftables
sudo nft add table inet t
sudo nft 'add chain inet t input { type filter hook input priority 0; policy accept; }'
sudo nft add rule inet t input tcp dport 8002 drop
```

С attacker:

```bash
nmap -Pn -p 8001,8002,8003 10.10.10.30
```

Ожидаемо:

```
8001/tcp open
8002/tcp filtered
8003/tcp closed
```

Объясните: `open` — SYN/ACK, `filtered` — таймаут из-за drop, `closed` — RST.

### 4. Сравнить сканы

```bash
sudo nmap -Pn -sS -p 1-1000 10.10.10.30
sudo nmap -Pn -sT -p 1-1000 10.10.10.30
```

Ожидаемо: одинаковый результат, но `-sS` требует root и не завершает соединения. В логах цели `-sT` оставит завершённые сессии, `-sS` — только SYN.

### 5. UDP

```bash
sudo nmap -Pn -sU -p 53,123,161 10.10.10.30
```

Ожидаемо: `open|filtered` — типичная картина для UDP, потому что ответа может не быть.

## Атака и защита

- **Атака:** SYN flood (не делаем — DoS), сканирование, fingerprinting по TTL/окну.
- **Детект:** много SYN без завершения, один source на много портов, `nmap`-сигнатуры в IDS.
- **Фикс:** rate limiting, SYN cookies, firewall default deny, honeypots для раннего обнаружения.

## Самопроверка

- [ ] Почему `-sS` называют «half-open»?
- [ ] Что означает `open|filtered` и почему для UDP это норма?
- [ ] Как по tcpdump отличить RST от таймаута?
- [ ] Что увидит цель при `-sT`, чего не увидит при `-sS`?

## Дальше

[2.4 — DNS, HTTP, TLS](l04-dns-http-tls.md)
