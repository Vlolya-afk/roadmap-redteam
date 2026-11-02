# 17.1 — Телеметрия: Sysmon, auditd, EDR

> **M17 · Этап 3 · 5 ч · 🟡 · артефакт:** `labs/m17-detection/l01-telemetry/`

## Цель

Собрать телеметрию, которой хватит для детекта: процессы, сеть, файлы, реестр, аутентификация, скрипты.

## Результат

- Sysmon с конфигом и 10 событиями.
- auditd с правилами на privesc.
- Понимание, чего не хватает.

## Теория

### 1. Windows Security

| ID | Что |
|---|---|
| 4624 | logon (type 2/3/10) |
| 4625 | failed logon |
| 4648 | explicit credentials |
| 4672 | special privileges |
| 4688 | process creation |
| 4768/4769 | Kerberos |
| 4720/4728/4732 | accounts/groups |
| 7045 | service install |

### 2. Sysmon

| ID | Что |
|---|---|
| 1 | process create |
| 3 | network connect |
| 7 | image load |
| 8 | CreateRemoteThread |
| 10 | process access |
| 11 | file create |
| 12/13/14 | registry |
| 15 | FileCreateStreamHash (MotW) |
| 22 | DNS query |

Конфиг: SwiftOnSecurity, Olaf Hartong, или свой. Главное — не «всё подряд», а нужное.

### 3. auditd

Правила на:

- `execve` для привилегированных команд;
- `/etc/passwd`, `/etc/shadow`;
- `sudoers`;
- `setuid`/`setgid`;
- модули ядра.

```bash
auditctl -a always,exit -F arch=b64 -S execve -F auid>=1000 -F auid!=4294967295 -k exec
```

### 4. EDR

Даёт: процессы с родителями, командные строки, сеть, инжекты, credential access, файлы. Часто уже коррелирует. Важно понимать, какие поля доступны.

### 5. PowerShell

- Script Block Logging (4104).
- Module Logging (4103).
- Transcription.
- AMSI.

### 6. Принцип

Телеметрия должна отвечать на вопросы: кто, что, когда, где, с какими аргументами, что было до/после. Если поле отсутствует — детект будет слабым.

## Лаборатория

> `WIN01` + `LNX01`.

### 1. Sysmon

Установите Sysmon с конфигом:

```powershell
Sysmon64.exe -accepteula -i sysmonconfig.xml
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 10
```

Ожидаемо: события 1/3/11.

### 2. Сгенерируйте активность

```powershell
whoami
ipconfig
certutil -urlcache -split -f http://10.10.10.50/test.txt C:\lab\t.txt
notepad.exe
```

Ожидаемо: события 1, 3, 11, 15.

### 3. auditd

```bash
sudo pacman -S audit
sudo systemctl enable --now auditd
sudo auditctl -w /etc/passwd -p wa -k passwd
sudo cat /etc/passwd >/dev/null
sudo ausearch -k passwd -i | tail -20
```

Ожидаемо: событие записи/чтения.

### 4. PowerShell

```powershell
Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -MaxEvents 5 |
  Where-Object Id -eq 4104 | Select-Object Message
```

Ожидаемо: script block.

### 5. Пробелы

Составьте таблицу: какое действие → какое событие → чего не хватает.

## Атака и защита

- **Атака:** избегать телеметрии (в рамках лабы).
- **Детект:** полнота полей и корреляция.
- **Фикс:** включить нужные логи, централизовать, защитить от очистки.

## Самопроверка

- [ ] Чем Sysmon 1 полезнее 4688?
- [ ] Какие поля auditd критичны?
- [ ] Что даёт 4104?
- [ ] Почему «включить всё» — плохо?
- [ ] Как защитить логи от очистки?

## Дальше

[17.2 — Sigma](l02-sigma.md)
