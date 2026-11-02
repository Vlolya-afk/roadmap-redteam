# 13.2 — Payload delivery и Mark-of-the-Web

> **M13 · Этап 2 · 5 ч · 🟡 · артефакт:** `labs/m13-initial-access-c2/l02-delivery/`

## Цель

Понять, как Windows помечает скачанные файлы и какие форматы доставки работают в 2026 году — без иллюзий и без вредоносного кода.

## Результат

- Таблица форматов доставки и их ограничений.
- Понимание MotW, Protected View, SmartScreen.
- 3 сценария доставки, проверенные в лабе.

## Теория

### 1. Mark-of-the-Web (MotW)

Файл, скачанный из интернета/почты, получает Zone.Identifier (ZoneId=3). Дальше:

- Office открывает в Protected View.
- Windows блокирует макросы.
- SmartScreen проверяет репутацию.
- Некоторые форматы (ISO, VHD) наследуют MotW на содержимое.

Проверка:

```powershell
Get-Item .\file.docx -Stream Zone.Identifier
```

### 2. Форматы

| Формат | Плюсы | Минусы/детект |
|---|---|---|
| Office + macro | привычно | макросы блокируются по умолчанию |
| ISO/IMG | обходит некоторые проверки | MotW наследуется, монтирование заметно |
| LNK | простой запуск | подозрительный процесс, 4688 |
| HTA | гибкость | mshta, AMSI, AppLocker |
| JS/VBS | распространено | AMSI, Script Block Logging |
| OneNote | был популярен | Microsoft закрыл/ужесточил |
| PDF | универсально | ограниченное выполнение |
| MSI | установка | AlwaysInstallElevated, логирование |

### 3. Обход MotW

Исторически: контейнеры (ISO), `Zone.Identifier` в ADS, архивы. Microsoft закрывает по мере сил. В лабе проверяем, что работает на конкретной сборке, и фиксируем — не строим стратегию на одном трюке.

### 4. Доставка

- **Ссылка** — самый частый вектор.
- **Вложение** — фильтруется.
- **QR-код** — обходит почтовые фильтры, требует телефон.
- **Мессенджер/Teams** — доверие к платформе.
- **USB** — физический доступ.
- **Watering hole** — сложнее и рискованнее.

### 5. Детект

- Sysmon 15 (FileCreateStreamHash) — MotW.
- 4688 — `mshta`, `wscript`, `rundll32`.
- Office-события: макросы, Protected View.
- SmartScreen/Defender.
- Почтовый шлюз: вложения, ссылки, SPF/DMARC.

## Лаборатория

> `WIN01` + `LNX01` (HTTP). Только безопасные тестовые файлы.

### 1. MotW

```powershell
# на WIN01
Invoke-WebRequest http://10.10.10.50/test.txt -OutFile C:\lab\test.txt
Get-Item C:\lab\test.txt -Stream Zone.Identifier
```

Ожидаемо: `ZoneId=3`.

### 2. Удаление MotW (в лабе)

```powershell
Remove-Item C:\lab\test.txt -Stream Zone.Identifier
Get-Item C:\lab\test.txt -Stream Zone.Identifier -ErrorAction SilentlyContinue
```

Ожидаемо: потока нет. Зафиксируйте, что это действие само по себе — признак.

### 3. ISO

```powershell
# создайте ISO с test.exe через oscdimg или любой инструмент
Mount-DiskImage -ImagePath C:\lab\test.iso
Get-Volume
```

Проверьте, есть ли MotW у файла внутри. Ожидаемо: на современных сборках — да.

### 4. LNK/HTA

Создайте ярлык на `cmd.exe /c calc.exe`. Запустите. Ожидаемо: 4688 с `cmd.exe`, родитель — `explorer.exe`. Это шумно.

### 5. Детект

```powershell
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 100 |
  Where-Object Id -eq 15 | Select-Object TimeCreated,Message
```

Ожидаемо: события FileCreateStreamHash.

### 6. Таблица

| Формат | MotW | Запуск | Детект | Работает в 2026? |
|---|---|---|---|---|

## Атака и защита

- **Атака:** выбрать формат под контекст, а не «самый модный».
- **Детект:** Sysmon 15, 4688, Office-события, почтовый шлюз.
- **Фикс:** блокировка макросов, Protected View, ASR, WDAC, обучение, фильтрация вложений.

## Самопроверка

- [ ] Что такое Zone.Identifier?
- [ ] Почему ISO долго считался обходом?
- [ ] Какие события показывают MotW?
- [ ] Почему LNK шумный?
- [ ] Что делает SmartScreen?

## Дальше

[13.3 — C2](l03-c2.md)
