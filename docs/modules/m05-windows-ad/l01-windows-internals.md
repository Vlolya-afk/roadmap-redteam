# 5.1 — Windows: архитектура, токены, реестр, службы

> **M05 · Этап 0 · 4 ч · 🟢 · артефакт:** `labs/m05-windows-ad/l01-win-basics/`

## Цель

Понять, как Windows решает, что вам можно: токен, SID, привилегии, целостность. Без этого privesc (M10) и evasion (M12) — набор кнопок.

## Результат

- Читаете `whoami /all` и объясняете каждую привилегию.
- Понимаете разницу user mode / kernel mode и почему драйвер = ring 0.
- Находите autoruns и службы, которые может использовать атакующий.

## Теория

- Архитектура: user mode (приложения, подсистемы) и kernel mode (ядро, драйверы). Граница — syscall.
- Процесс получает **токен** при входе: SID пользователя, группы, привилегии, integrity level, session.
- UAC: даже админ работает с medium integrity, пока не повысит права; повышение создаёт новый токен.
- Привилегии: `SeDebugPrivilege` (отладка чужих процессов), `SeImpersonatePrivilege` (воплощение токена), `SeBackupPrivilege` (обход ACL при чтении), `SeTakeOwnership`.
- Реестр: `HKLM\SAM`, `SECURITY`, `SYSTEM`, autoruns `Run`, services, Winlogon.
- Службы запускаются под SYSTEM/LocalService/NetworkService — частая цель privesc.
- События: 4624 (logon), 4625 (failed), 4672 (special privileges), 4688 (process), 7045 (service install).

## Лаборатория

### 1. Кто я

```powershell
whoami /all
whoami /priv
whoami /groups
```

Ожидаемо: SID пользователя, группы (`Domain Users`, `Administrators`?), integrity level (`Medium`/`High`), список привилегий. Найдите `SeImpersonatePrivilege` — если есть у сервисной учётки, это путь к SYSTEM (Potato-семейство).

### 2. Процессы и токены

```powershell
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name,Id,CPU
Get-Process -Id $PID | Select-Object Name,Id,Path
```

Ожидаемо: список процессов и путь. Обратите внимание на процессы, запущенные от `SYSTEM` (`winlogon`, `lsass`, `services`).

### 3. Реестр и autoruns

```powershell
reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Run"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
Get-Service | Where-Object Status -eq Running | Select-Object Name,DisplayName
Get-ScheduledTask | Where-Object State -eq Ready | Select-Object -First 10 TaskName,TaskPath
```

Ожидаемо: записи автозапуска, службы, задачи. Каждая — потенциальный persistence-механизм.

### 4. Создать службу (админ)

```powershell
New-Item -Path C:\lab -ItemType Directory -Force
Set-Content -Path C:\lab\svc.ps1 -Value 'Add-Content C:\lab\svc.log "tick $(Get-Date)"'
sc.exe create LabSvc binPath= "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\lab\svc.ps1" start= auto
sc.exe start LabSvc
Get-Service LabSvc
sc.exe delete LabSvc
```

Ожидаемо: служба создана и запущена, в `C:\lab\svc.log` появляются записи. Это модель легитимного механизма, который злоумышленник использует для закрепления.

### 5. События

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4688} -MaxEvents 5 |
  Select-Object TimeCreated, Message
Get-WinEvent -FilterHashtable @{LogName='System'; Id=7045} -MaxEvents 5 |
  Select-Object TimeCreated, Message
```

Ожидаемо: события создания процессов и установки служб. Если аудит 4688 выключен — включите (M17).

## Атака и защита

- **Атака:** токен-кража, `SeImpersonate` → SYSTEM, служба с записываемым бинарником, autorun в пользовательском реестре.
- **Детект:** 4688 с необычным родителем, 7045 с путём в `C:\Users`/`C:\Temp`, 4672 для не-админа, Sysmon Event 1/11/13.
- **Фикс:** least privilege, LSA protection, Credential Guard, AppLocker/WDAC, аудит, запрет записи в каталоги служб.

## Самопроверка

- [ ] Почему админ без UAC-повышения не может писать в `C:\Windows`?
- [ ] Что даёт `SeImpersonatePrivilege` и кто им обычно обладает?
- [ ] Чем служба отличается от задачи планировщика для persistence?
- [ ] Какие события покажут установку службы?

## Дальше

[5.2 — Структура AD](l02-ad-structure.md)
