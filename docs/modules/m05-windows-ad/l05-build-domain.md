# 5.5 — Строим лабораторный домен

> **M05 · Этап 0 · 5 ч · 🟡 · артефакт:** `labs/m05-windows-ad/l05-domain/`

## Цель

Поднять домен `lab.local` с контроллером, рабочей станцией, пользователями, группами и специально уязвимыми сервисными учётками. Это стенд для M10–M12.

## Результат

- DC01 с AD DS, DNS, статическим IP.
- 5+ пользователей, 2 группы, 2 сервисные учётки (SPN и без preauth).
- WS01 в домене.
- Снапшот `domain-ready` и карта домена.

## Теория

- Промоушен DC создаёт `NTDS.dit`, SYSVOL, DNS-зону и записи SRV.
- DNS для домена критичен: клиенты находят DC по `_ldap._tcp.dc._msdcs.lab.local`.
- DSRM-пароль нужен для восстановления AD; храните отдельно.
- Сервисные учётки с SPN и без preauth — намеренные дыры для лаб. В реальном домене так делать нельзя.
- Снапшот домаенного DC делать **выключенным**; откат «на горячую» ломает репликацию.

## Лаборатория

### 1. Подготовка DC01

Windows Server 2022/2025 Evaluation, Desktop Experience (для первого раза), 2 vCPU, 4 ГБ, 60 ГБ, адаптер VMnet2.

```powershell
Rename-Computer -NewName DC01 -Restart
```

После перезагрузки:

```powershell
New-NetIPAddress -InterfaceAlias "Ethernet0" -IPAddress 10.10.10.10 -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 127.0.0.1
Get-NetIPConfiguration
```

Ожидаемо: `10.10.10.10/24`, DNS `127.0.0.1`.

### 2. Промоушен

```powershell
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Import-Module ADDSDeployment

$dsrm = ConvertTo-SecureString "DsrmPassw0rd!" -AsPlainText -Force
Install-ADDSForest `
  -DomainName "lab.local" `
  -DomainNetbiosName "LAB" `
  -InstallDns `
  -SafeModeAdministratorPassword $dsrm `
  -Force
```

ВМ перезагрузится. Войдите как `LAB\Administrator`.

Проверка:

```powershell
Get-ADDomain | Format-List Name,DistinguishedName,PDCEmulator
Get-ADForest | Format-List Name,RootDomain
dcdiag /q
```

Ожидаемо: домен `lab.local`, ошибок нет (пустой вывод `dcdiag /q` — хорошо).

### 3. OU, пользователи, группы

```powershell
$base = "DC=lab,DC=local"
"Staff","Workstations","Servers","ServiceAccounts" | ForEach-Object {
  New-ADOrganizationalUnit -Name $_ -Path $base
}

$pw = ConvertTo-SecureString "Passw0rd!" -AsPlainText -Force
$users = @(
  @{n="Alice"; s="alice"; d="Helpdesk engineer"},
  @{n="Bob";   s="bob";   d="Developer"},
  @{n="Carol"; s="carol"; d="Finance"},
  @{n="Dave";  s="dave";  d="Intern"},
  @{n="Erin";  s="erin";  d="IT manager"}
)
foreach ($u in $users) {
  New-ADUser -Name $u.n -SamAccountName $u.s -UserPrincipalName "$($u.s)@lab.local" `
    -Path "OU=Staff,$base" -Description $u.d -AccountPassword $pw -Enabled $true
}

New-ADGroup -Name "Helpdesk" -SamAccountName helpdesk -GroupScope Global -Path "OU=Staff,$base"
Add-ADGroupMember -Identity helpdesk -Members alice,dave

New-ADGroup -Name "Finance" -SamAccountName finance -GroupScope Global -Path "OU=Staff,$base"
Add-ADGroupMember -Identity finance -Members carol,erin
```

Ожидаемо: `Get-ADUser -Filter * | Measure-Object` — 5 пользователей + Administrator.

### 4. Сервисные учётки (намеренно уязвимые)

```powershell
New-ADUser -Name "svc_sql" -SamAccountName svc_sql -Path "OU=ServiceAccounts,$base" `
  -AccountPassword $pw -Enabled $true -PasswordNeverExpires $true `
  -Description "SQL service account"
setspn -A MSSQLSvc/sql01.lab.local:1433 LAB\svc_sql

New-ADUser -Name "svc_backup" -SamAccountName svc_backup -Path "OU=ServiceAccounts,$base" `
  -AccountPassword $pw -Enabled $true -PasswordNeverExpires $true `
  -Description "Backup service (legacy)"
Set-ADAccountControl -Identity svc_backup -DoesNotRequirePreAuth $true

New-ADUser -Name "svc_web" -SamAccountName svc_web -Path "OU=ServiceAccounts,$base" `
  -AccountPassword $pw -Enabled $true -PasswordNeverExpires $true
```

Проверка:

```powershell
setspn -L LAB\svc_sql
Get-ADUser svc_backup -Properties DoesNotRequirePreAuth | Select-Object Name,DoesNotRequirePreAuth
```

Ожидаемо: SPN на месте, `DoesNotRequirePreAuth = True`.

### 5. ACL-дыра

```powershell
dsacls "OU=Staff,$base" /G "LAB\helpdesk:GA"
dsacls "OU=Staff,$base" | Select-String "helpdesk"
```

Ожидаемо: `helpdesk` имеет `GENERIC_ALL` на OU. Это позволит M11 показать ACL-атаку.

### 6. WS01 в домен

На WS01 (Windows 11, 3 ГБ, статический IP `10.10.10.20`, DNS `10.10.10.10`):

```powershell
Add-Computer -DomainName lab.local -Credential (Get-Credential LAB\Administrator) -Restart
```

После перезагрузки:

```powershell
whoami
nltest /dsgetdc:lab.local
klist
```

Ожидаемо: `LAB\alice` (или другой пользователь), DC найден, TGT в кэше.

### 7. Снапшот и карта

1. Выключите DC01 и WS01.
2. Снапшоты: `domain-ready` у обеих.
3. Заполните `ad-map.md`: домен, OU, пользователи, группы, сервисные учётки, уязвимые настройки.

## Атака и защита

- **Атака:** домен с такими настройками ломается за часы: Kerberoast `svc_sql`, AS-REP `svc_backup`, ACL через `helpdesk`.
- **Детект:** 4769 для `svc_sql`, 4768 без preauth, 5136 при изменении ACL.
- **Фикс:** gMSA, случайные 25+ пароли, включить preauth, убрать `GenericAll`, tiering.

## Самопроверка

- [ ] Зачем DC указывает DNS на себя?
- [ ] Что произойдёт, если WS01 не видит DNS домена?
- [ ] Почему снапшот DC делают выключенным?
- [ ] Какие три намеренные дыры вы создали и как каждая эксплуатируется?

## Дальше

[Контрольная M05](exam.md)
