# 12.1 — Как работают AV/EDR

> **M12 · Этап 2 · 5 ч · 🟡 · артефакт:** `labs/m12-evasion/l01-av-edr/`

## Цель

Разобрать конвейер защиты Windows от файла до поведения: сигнатуры, эвристика, эмуляция, AMSI, userland-хуки, ETW, kernel callbacks. Без этого обход — это набор скопированных трюков.

## Результат

- Схема «payload → защита → детект».
- Список точек телеметрии на вашей ВМ.
- 5 гипотез, что и где детектится.

## Теория

### 1. Слои защиты

```text
Файл → сканер (signature/heuristic/ML)
     → репутация (cloud)
     → эмуляция/песочница
     → запуск
     → AMSI (скрипты)
     → userland hooks (ntdll)
     → ETW/.NET events
     → kernel callbacks (process/image/thread)
     → EDR-корреляция и реакция
```

### 2. Сканер

- **Сигнатуры** — байтовые паттерны, YARA-подобные правила.
- **Эвристика** — подозрительные структуры (например, PE с нестандартными секциями).
- **ML/облако** — вероятность вредоносности по признакам.
- **Эмуляция** — запуск в лёгкой песочнице на N инструкций.

Обход на этом уровне — изменение структуры, а не поведения. Это самое хрупкое: сигнатуры обновляются.

### 3. AMSI

Antimalware Scan Interface получает содержимое скриптов до выполнения: PowerShell, VBScript, JScript, .NET-сборки. Он отдаёт буфер в провайдер (Defender). Если патчить `amsi.dll!AmsiScanBuffer` — это известный, но детектируемый трюк.

### 4. Userland hooks

EDR вставляет переходы в начале функций `ntdll.dll` (`NtCreateFile`, `NtAllocateVirtualMemory`, `NtProtectVirtualMemory`). Перехват позволяет видеть аргументы. Обходы: direct syscalls, indirect syscalls, unhooking, hardware breakpoints. Каждый оставляет свой признак.

### 5. ETW

Event Tracing for Windows даёт телеметрию от `.NET` (`EventSource`), PowerShell (Script Block Logging), Defender и самой ОС. Провайдеры `Microsoft-Windows-DotNETRuntime`, `Microsoft-Windows-PowerShell`, `Microsoft-Windows-Threat-Intelligence` (последний — только для защитных продуктов).

### 6. Kernel callbacks

Драйвер EDR регистрирует:

- `PsSetCreateProcessNotifyRoutineEx` — создание процессов.
- `PsSetLoadImageNotifyRoutine` — загрузка образов/DLL.
- `ObRegisterCallbacks` — доступ к процессам/потокам (защита LSASS).

Обход требует уязвимого драйвера (BYOVD) и является громким, рискованным шагом.

### 7. Что важно для red team

Не «обойти всё», а **понять, какой слой даст детект первым**, и выбрать минимально шумный путь. Часто лучший обход — легитимный инструмент и правильный контекст.

## Лаборатория

> `WIN01` (Defender включён), снимок. Все инструменты — только в `C:\lab`.

### 1. Инвентаризация защиты

```powershell
Get-MpComputerStatus | Select-Object AMServiceEnabled,RealTimeProtectionEnabled,AntivirusSignatureVersion
Get-MpPreference | Select-Object AttackSurfaceReductionRules_Ids,EnableControlledFolderAccess
Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct
```

Ожидаемо: статус Defender и ASR-правила.

### 2. Проверка AMSI

```powershell
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').GetValue($null)
```

Ожидаемо: `False` (AMSI активен).

### 3. Точки хуков

```powershell
# Process Explorer: свойства процесса → Strings, или
Get-Process lsass | Select-Object Id,Path
```

В Process Explorer посмотрите загруженные DLL в `powershell.exe`: `amsi.dll`, `mpclient.dll`. Ожидаемо: защитные модули внутри процесса.

### 4. Тест EICAR

```powershell
# строка EICAR в файле — безопасный тест
Set-Content C:\lab\eicar.com 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
Get-MpThreatDetection | Select-Object -First 3
```

Ожидаемо: детект и quarantine. Файл удалите.

### 5. ETW и логи

```powershell
Get-WinEvent -ListLog *PowerShell* | Select-Object LogName,IsEnabled
Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -MaxEvents 5
```

Ожидаемо: Script Block Logging. Включите его, если выключен (только в лабе):

```powershell
Set-ItemProperty HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging -Name EnableScriptBlockLogging -Value 1
```

### 6. Схема

Нарисуйте свой payload-путь и отметьте, где сработает каждый слой. Это ваш рабочий документ.

## Атака и защита

- **Атака:** снижать подозрительность на каждом слое, а не «выключать Defender».
- **Детект:** корреляция файла, процесса, сети и поведения; ETW; kernel callbacks.
- **Фикс:** Defender + ASR + WDAC + LAPS + мониторинг; регулярные purple-тесты.

## Самопроверка

- [ ] Чем сигнатура отличается от эвристики?
- [ ] Что такое AMSI и какие языки он покрывает?
- [ ] Зачем EDR хукает `ntdll`?
- [ ] Какие kernel callbacks используются для защиты LSASS?
- [ ] Почему BYOVD — плохой первый выбор?

## Дальше

[12.2 — Payload](l02-payloads.md)
