# 5.3 — NTLM и Kerberos

> **M05 · Этап 0 · 5 ч · 🟡 · артефакт:** `labs/m05-windows-ad/l03-auth/`

## Цель

Понять две системы аутентификации Windows на уровне сообщений: что именно передаётся, что хранится в памяти и почему Kerberoasting работает.

## Результат

- Объясняете NTLM challenge/response и почему pass-the-hash возможен.
- По шагам описываете Kerberos AS/TGS и где находится уязвимость.
- Знаете, какие события/logи фиксируют вход и выдачу тикетов.

## Теория

- NT hash = `MD4(UTF-16LE(password))`. Хранится в SAM (локально) и `NTDS.dit` (домен).
- NTLM: сервер шлёт 8-байтовый challenge, клиент отвечает HMAC-MD5 на основе NT hash. Сам пароль не передаётся, но хэш = эквивалент пароля для NTLM.
- Pass-the-Hash: зная NT hash, можно аутентифицироваться без взлома пароля.
- NTLM relay: перехваченный challenge/response переигрывается на другой сервер, если нет SMB signing.
- Kerberos: `AS-REQ` → `AS-REP` (TGT, зашифрован ключом пользователя) → `TGS-REQ` с SPN → `TGS-REP` (сервисный тикет, зашифрован ключом сервисной учётки).
- Pre-authentication: метка времени, зашифрованная ключом пользователя. Если выключена — `AS-REP` можно запросить и ломать офлайн.
- Kerberoasting: любой доменный пользователь может запросить TGS для SPN; тикет зашифрован паролем сервисной учётки.
- RC4 (etype 23) ломается быстрее AES256 (etype 18).

## Лаборатория

### 1. Хэши и тикеты

На WS01 (домен уже должен быть из 5.5):

```powershell
klist
whoami /user
```

Ожидаемо: текущие Kerberos-тикеты (`krbtgt/LAB.LOCAL`, сервисные). Если пусто — вы вошли локально, а не в домен.

### 2. SPN

На DC или WS с RSAT:

```powershell
setspn -L LAB\svc_sql
Get-ADUser svc_sql -Properties servicePrincipalName,msDS-SupportedEncryptionTypes |
  Format-List
```

Ожидаемо: `MSSQLSvc/sql01.lab.local:1433`, тип шифрования (если пусто — поддерживается RC4).

### 3. Запросить TGS

На WS01 от доменного пользователя:

```powershell
klist get MSSQLSvc/sql01.lab.local:1433
klist
```

Ожидаемо: новый тикет `MSSQLSvc/...` в кэше. Именно его злоумышленник выносит и ломает офлайн.

### 4. События

На DC:

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4768} -MaxEvents 3 |
  Select-Object TimeCreated, Message
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4769} -MaxEvents 3 |
  Select-Object TimeCreated, Message
```

Ожидаемо: 4768 — выдача TGT, 4769 — выдача TGS. В сообщении видно имя учётки, IP, тип шифрования (`0x17` = RC4, `0x12` = AES256).

### 5. AS-REP roasting (концепт)

Если у учётки `svc_backup` стоит «не требовать Kerberos pre-auth»:

```powershell
Get-ADUser svc_backup -Properties DoesNotRequirePreAuth |
  Select-Object SamAccountName,DoesNotRequirePreAuth
```

Ожидаемо: `True`. С attacker (Linux, impacket, после M05):

```bash
impacket-GetNPUsers lab.local/alice:'Passw0rd!' -dc-ip 10.10.10.10 -request
```

Ожидаемо: `$krb5asrep$23$svc_backup@LAB.LOCAL:...` — хэш для офлайн-подбора. (Полная лаба — в M11.)

## Атака и защита

- **Атака:** pass-the-hash, NTLM relay, Kerberoasting, AS-REP roasting, golden/silver ticket.
- **Детект:** 4769 с RC4 и большим объёмом, 4768 без preauth, 4624 type 3 с NTLM, аномальные SPN-запросы.
- **Фикс:** gMSA для сервисов, 25+ символов и ротация, AES-only, отключить NTLM где можно, SMB/LDAP signing, Protected Users, tiering, honey-учётки.

## Самопроверка

- [ ] Почему NT hash позволяет войти без пароля?
- [ ] Чем TGT отличается от TGS?
- [ ] Почему Kerberoasting возможен для любого пользователя?
- [ ] Что нужно, чтобы NTLM relay сработал?

## Дальше

[5.4 — GPO, ACL, SYSVOL, trusts](l04-gpo-acl.md)
