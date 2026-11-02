# 12.5 — Тест против Defender и телеметрия

> **M12 · Этап 2 · 5 ч · 🔴 · артефакт:** `labs/m12-evasion/l05-defender/`

## Цель

Провести контролируемый тест: что именно детектит Defender/EDR, на каком шаге и какая телеметрия остаётся. Научиться оформлять результат как инженер-исследователь.

## Результат

- Матрица «техника → детект → событие → вывод».
- 3 гипотезы, проверенные экспериментально.
- Рекомендации по детекту и hardening.

## Теория

### 1. Методология

1. Зафиксируйте baseline (версия Defender, сигнатуры, политики, EDR).
2. Определите одну переменную за тест.
3. Запустите технику.
4. Соберите: детект (имя/severity), события (4688, Sysmon, Defender 1116/1117), сеть.
5. Сделайте вывод и повторите.

### 2. Что тестировать

- Файл на диске vs in-memory.
- Подписанный vs неподписанный бинарник.
- LOLBin vs свой лоадер.
- Скрипт vs .NET assembly.
- Сеть: прямой egress vs прокси/redirector.
- Привилегии: user vs admin.

### 3. Метрики

- **Prevention:** заблокировано/нет.
- **Detection:** обнаружено/нет, через сколько.
- **Visibility:** какие события остались.
- **Fidelity:** ложные срабатывания на легитимных действиях.

### 4. Defender: что смотреть

```powershell
Get-MpComputerStatus
Get-MpPreference
Get-MpThreatDetection
Get-WinEvent -LogName "Microsoft-Windows-Windows Defender/Operational" -MaxEvents 50
```

События: 1116 (детект), 1117 (действие), 5001 (real-time off), 5007 (конфиг изменён).

### 5. ASR

Правила Attack Surface Reduction блокируют поведение, а не файл:

- Block Office macros.
- Block executable content from email.
- Block credential stealing from LSASS.
- Block untrusted executables from USB.
- Block persistence through WMI.

Проверка:

```powershell
Get-MpPreference | Select-Object AttackSurfaceReductionRules_Ids,AttackSurfaceReductionRules_Actions
```

### 6. Этика теста

Тест не должен выходить за пределы ВМ. Не отключайте Defender «навсегда» — используйте снимок. Не публикуйте работающий обход без ответственного disclosure.

## Лаборатория

> `WIN01` с Defender, снимок. EDR (опционально) — Defender for Endpoint trial или открытый агент.

### 1. Baseline

```powershell
Get-MpComputerStatus | Select-Object AntivirusSignatureVersion,RealTimeProtectionEnabled
Get-MpPreference | Select-Object -Property *ASR*
```

Запишите в `baseline.md`.

### 2. Тест 1: файл

Скопируйте `shell.exe` из 12.2. Ожидаемо: детект при записи или запуске. Зафиксируйте событие 1116.

### 3. Тест 2: in-memory

Запустите лоадер из 12.3. Ожидаемо: файл может пройти, но поведение (RX-память, сеть) — нет. Сравните.

### 4. Тест 3: LOLBin

```powershell
certutil.exe -urlcache -split -f http://10.10.10.50/test.txt C:\lab\t.txt
```

Ожидаемо: скорее всего, без детекта. Событие 4688 есть. Это важный вывод: «нет детекта» ≠ «нет телеметрии».

### 5. Сбор

```powershell
Get-WinEvent -LogName "Microsoft-Windows-Windows Defender/Operational" -MaxEvents 100 |
  Where-Object Id -in 1116,1117,5007 | Select-Object TimeCreated,Id,Message
Get-WinEvent -LogName Security -MaxEvents 500 | ? Id -eq 4688 |
  Select-Object TimeCreated,Message
```

### 6. Матрица

| Техника | Prevention | Detection | Событие | Visibility | Вывод |
|---|---|---|---|---|---|

## Атака и защита

- **Атака:** тестировать по одной переменной.
- **Детект:** Defender 1116/1117, 4688, Sysmon, ASR.
- **Фикс:** ASR, WDAC, Credential Guard, аудит, регулярные purple-тесты.

## Самопроверка

- [ ] Чем prevention отличается от detection?
- [ ] Почему «нет алерта» не значит «нет следов»?
- [ ] Какие события Defender показывают детект?
- [ ] Зачем фиксировать baseline?
- [ ] Как оценить fidelity правила?

## Дальше

[Контрольная M12](exam.md)
