# 3.2 — Python для сетей и безопасности

> **M03 · Этап 0 · 4 ч · 🟡 · артефакт:** `labs/m03-scripting/l02-scanner/`

## Цель

Написать свой порт-сканер и banner grabber, понять, что делает `nmap` внутри, и научиться работать с сокетами и HTTP.

## Результат

- Сканер с таймаутами и потоками, который не вешает терминал.
- Понимание разницы между `connect()` и отправкой сырых пакетов.
- Скрипт с `--help`, логированием и корректной обработкой ошибок.

## Теория

- `socket.socket(AF_INET, SOCK_STREAM)` + `connect_ex()` → код ошибки вместо исключения.
- Таймаут обязателен: без него скан «filtered» портов занимает минуты.
- Потоки (`ThreadPoolExecutor`) дают конкурентность без сложности asyncio.
- `requests` удобен для HTTP, но не для сырых TCP.
- `scapy` умеет собирать пакеты вручную (ARP, TCP SYN) — мощно, но требует root.
- Всегда ограничивайте скан своим scope и ставьте задержки.

## Лаборатория

### 1. TCP-клиент

```python
import socket

s = socket.socket()
s.settimeout(1)
print(s.connect_ex(("10.10.10.30", 22)))  # 0 = open
s.close()
```

Ожидаемо: `0`, если SSH открыт. Для закрытого порта — `111` (connection refused) или `110` (timeout).

### 2. Сканер

`scanner.py`:

```python
#!/usr/bin/env python3
import argparse
import socket
from concurrent.futures import ThreadPoolExecutor, as_completed

def check(host: str, port: int, timeout: float) -> tuple[int, str]:
    with socket.socket() as s:
        s.settimeout(timeout)
        if s.connect_ex((host, port)) != 0:
            return port, "closed"
        try:
            s.sendall(b"HEAD / HTTP/1.0\r\n\r\n")
            banner = s.recv(256).decode(errors="replace").splitlines()[0]
        except OSError:
            banner = ""
    return port, banner or "open"

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("host")
    ap.add_argument("-p", "--ports", default="1-1024")
    ap.add_argument("-t", "--timeout", type=float, default=0.5)
    ap.add_argument("-w", "--workers", type=int, default=100)
    args = ap.parse_args()

    start, _, end = args.ports.partition("-")
    ports = range(int(start), int(end or start) + 1)

    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = [pool.submit(check, args.host, p, args.timeout) for p in ports]
        for f in as_completed(futures):
            port, state = f.result()
            if state != "closed":
                print(f"{port:5d}/tcp {state}")

if __name__ == "__main__":
    main()
```

Проверка:

```bash
python scanner.py 10.10.10.30 -p 1-1024
```

Ожидаемо: `22/tcp open` и, если поднят, `8000/tcp open`. Время — секунды, не минуты.

### 3. Banner grab

Для SSH баннер придёт сразу:

```python
import socket
s = socket.create_connection(("10.10.10.30", 22), timeout=2)
print(s.recv(128).decode())
```

Ожидаемо: `SSH-2.0-OpenSSH_9.x`.

### 4. ARP-скан через scapy (опционально)

```bash
pip install scapy --break-system-packages   # или в venv
sudo python - <<'PY'
from scapy.all import ARP, Ether, srp
pkt = Ether(dst="ff:ff:ff:ff:ff:ff")/ARP(pdst="10.10.10.0/24")
ans, _ = srp(pkt, timeout=2, verbose=False)
for _, r in ans:
    print(r.psrc, r.hwsrc)
PY
```

Ожидаемо: список живых хостов с MAC. Сравните с `ip neigh`.

## Атака и защита

- **Атака:** медленное сканирование малым числом потоков обходит пороги; banner grabbing выдаёт версии для подбора CVE.
- **Детект:** IDS по числу SYN, honeypot, аномалии по одному источнику.
- **Фикс:** rate limiting, закрытие лишних портов, скрытие версий (`ServerTokens Prod`), fail2ban.

## Самопроверка

- [ ] Почему `connect_ex` удобнее `connect` в сканере?
- [ ] Что будет, если убрать `settimeout`?
- [ ] Чем `ThreadPoolExecutor` лучше ручного `threading.Thread`?
- [ ] Почему scapy требует root?

## Дальше

[3.3 — Bash, Git, документация](l03-bash-git.md)
