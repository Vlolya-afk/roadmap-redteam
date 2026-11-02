# 5.2 — AD DS: лес, домен, OU, LDAP

> **M05 · Этап 0 · 4 ч · 🟢 · артефакт:** `labs/m05-windows-ad/l02-ad-map/`

## Цель

Понять структуру Active Directory и научиться находить объекты по LDAP-пути. Это язык, на котором говорят BloodHound, PowerView и все AD-атаки.

## Результат

- Объясняете лес/дерево/домен/OU и разницу между ними.
- Строите DN объекта и запрашиваете его через PowerShell и LDAP.
- Понимаете, что такое FSMO, сайты и репликация.

## Теория

- Лес (forest) — граница безопасности; домены в лесу доверяют друг другу.
- Домен — контейнер с собственной БД (`NTDS.dit`) и контроллерами.
- OU — организационная единица для делегирования и GPO, не граница безопасности.
- DN (distinguished name): `CN=Alice,OU=Users,DC=lab,DC=local`.
- LDAP — протокол доступа: `(sAMAccountName=alice)`, `(objectClass=user)`, `(servicePrincipalName=*)`.
- FSMO-роли: Schema Master, Domain Naming, PDC Emulator, RID Master, Infrastructure Master.
- Сайты и репликация: KCC строит топологию, `repadmin` диагностирует.
- SYSVOL — общая папка с GPO и скриптами, реплицируется через DFS-R.

## Лаборатория

### 1. Лес и домен

На DC (после 5.5) или на WS с RSAT:

```powershell
Get-ADForest | Format-List Name,RootDomain,Domains,GlobalCatalogs
Get-ADDomain | Format-List Name,DomainMode,DistinguishedName,PDCEmulator
Get-ADDomainController -Filter * | Select-Object Name,IPv4Address,Site
```

Ожидаемо: `lab.local`, список DC, роли.

### 2. OU и объекты

```powershell
Get-ADOrganizationalUnit -Filter * | Select-Object Name,DistinguishedName
Get-ADUser -Filter * -Properties Description,servicePrincipalName |
  Select-Object Name,SamAccountName,Enabled,DistinguishedName
Get-ADGroup -Filter * | Select-Object Name,GroupScope,GroupCategory
```

Ожидаемо: дерево OU и объекты. Найдите сервисные учётки по `servicePrincipalName`.

### 3. LDAP-запрос

```powershell
Get-ADUser -LDAPFilter "(servicePrincipalName=*)" -Properties servicePrincipalName |
  Select-Object SamAccountName,servicePrincipalName
Get-ADUser -LDAPFilter "(&(objectClass=user)(adminCount=1))" |
  Select-Object SamAccountName
```

Ожидаемо: учётки с SPN и «защищённые» админы (`adminCount=1`).

С attacker (Linux) через `ldapsearch`:

```bash
ldapsearch -x -H ldap://10.10.10.10 -D "alice@lab.local" -w 'Passw0rd!' \
  -b "DC=lab,DC=local" "(sAMAccountName=alice)" cn memberOf
```

Ожидаемо: атрибуты пользователя. Если LDAP подписан/зашифрован — используйте `-Z` или LDAPS.

### 4. FSMO и репликация

```powershell
netdom query fsmo
repadmin /replsummary
dcdiag /test:dns /v
```

Ожидаемо: все роли на DC01, репликация без ошибок (для одного DC — тривиально).

### 5. Карта

Нарисуйте mermaid-схему: лес → домен → OU → ключевые объекты (пользователи, группы, сервисные учётки, компьютеры). Отметьте, где лежат права.

## Атака и защита

- **Атака:** enumeration через LDAP (легитимный протокол, трудно блокировать), поиск SPN, `adminCount`, ACL.
- **Детект:** аномальное количество LDAP-запросов, `4662` (доступ к объектам), сканирование с одного хоста.
- **Фикс:** минимальные права на чтение, tiering, мониторинг LDAP, honeytokens в AD.

## Самопроверка

- [ ] Чем OU отличается от домена с точки зрения безопасности?
- [ ] Как построить DN для пользователя в OU `Staff`?
- [ ] Что такое FSMO и почему PDC Emulator важен для времени?
- [ ] Почему LDAP- enumeration сложно заметить?

## Дальше

[5.3 — NTLM и Kerberos](l03-auth-protocols.md)
