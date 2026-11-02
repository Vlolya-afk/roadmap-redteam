# 10.3 — Windows enumeration

> **M10 · Этап 1 · 4 ч · 🟢 · артефакт:** `labs/m10-privesc/l03-win-enum/`

## Цель

Собрать контекст Windows-хоста: привилегии, службы, задачи, права на файлы, установленные патчи, доверенные пути.

## Результат

- Ручной чек-лист из 12 команд.
- PowerUp/WinPEAS и понимание их находок.
- Список кандидатов на SYSTEM.

## Теория

- `whoami /all` — токен, группы, привилегии, integrity.
- `systeminfo`/`Get-HotFix` — версия и патчи.
- Службы: путь, пользователь, права на бинарник, права на изменение конфигурации.
- Задачи планировщика и autoruns — persistence и privesc.
- `icacls`/`accesschk` — кто может писать.
- PowerUp ищет: unquoted paths, weak service perms, AlwaysInstallElevated, modifiable autoruns.
- WinPEAS — более широкий, но шумный.

## Лаборатория

### 1. Контекст

```powershell
whoami /all
systeminfo | Select-String "OS Name","OS Version","System Type"
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5
```

Ожидаемо: пользователь, группы, привилегии, версия, патчи. Отметьте `SeImpersonatePrivilege`.

### 2. Службы

```powershell
Get-CimInstance Win32_Service |
  Select-Object Name,DisplayName,State,StartMode,PathName,StartName |
  Where-Object State -eq "Running" | Format-Table -AutoSize
```

Ожидаемо: службы, пути, учётки. Ищите пути с пробелами без кавычек.

### 3. Права

```powershell
icacls "C:\Program Files" 
icacls "C:\ProgramData"
accesschk.exe -uwcqv "Everyone" * 2>$null
accesschk.exe -uwcqv "Users" * 2>$null
```

`accesschk` — Sysinternals, скачайте заранее. Ожидаемо: список объектов, доступных на запись.

### 4. Задачи и autoruns

```powershell
Get-ScheduledTask | Where-Object State -eq Ready |
  Select-Object TaskName,TaskPath,Author | Format-Table -AutoSize
Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
```

Ожидаемо: задачи и автозапуск. Ищите задачи с writable-скриптами.

### 5. PowerUp

```powershell
# скачайте PowerUp.ps1 заранее в C:\lab
. C:\lab\PowerUp.ps1
Invoke-AllChecks
```

Ожидаемо: отчёт с `Unquoted Service Paths`, `Modifiable Services`, `AlwaysInstallElevated`. Для каждой находки — гипотеза.

### 6. WinPEAS (опционально)

```powershell
C:\lab\winPEASx64.exe
```

Ожидаемо: много секций. Читайте `Interesting Files`, `Services`, `Privileges`.

## Атака и защита

- **Атака:** weak service perms → SYSTEM; unquoted path → hijack; token → impersonate.
- **Детект:** 4688 с необычным родителем, 7045, Sysmon 1/11/13, изменения служб.
- **Фикс:** кавычки в путях, минимальные права на службы/каталоги, LSA protection, WDAC, аудит.

## Самопроверка

- [ ] Что означает `SeImpersonatePrivilege` в `whoami /priv`?
- [ ] Как найти unquoted service path без PowerUp?
- [ ] Почему `C:\ProgramData` часто опасен?
- [ ] Чем `accesschk` полезнее `icacls`?

## Дальше

[10.4 — Windows privesc](l04-windows-privesc.md)
