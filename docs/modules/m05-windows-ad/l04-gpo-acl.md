# 5.4 — GPO, ACL, SYSVOL, доверия

> **M05 · Этап 0 · 4 ч · 🟡 · артефакт:** `labs/m05-windows-ad/l04-gpo-acl/`

## Цель

Понять, как в AD раздаются права и настройки, и где конфигурация превращается в уязвимость.

## Результат

- Читаете результат применения GPO и объясняете порядок.
- Находите опасные ACE (`GenericAll`, `WriteDACL`, `ForceChangePassword`).
- Понимаете, почему старый `Groups.xml` в SYSVOL — находка.

## Теория

- GPO применяется в порядке: local → site → domain → OU (LSDOU). `Enforced` перебивает, `Block Inheritance` останавливает.
- Security filtering и WMI filter ограничивают, к кому применяется политика.
- ACL объекта AD: ACE с правами (`GenericAll`, `GenericWrite`, `WriteDACL`, `WriteOwner`, `ForceChangePassword`, `AddMember`).
- `adminCount=1` — маркер защищённых админов; их ACL часто сломаны.
- SYSVOL (`\\domain\SYSVOL`) хранит GPO и скрипты; старые `Groups.xml` содержали `cpassword`.
- `cpassword` шифруется AES-ключом, опубликованным Microsoft (MS14-025), то есть это фактически открытый пароль.
- Доверие: направление (inbound/outbound), транзитивность, SID filtering.

## Лаборатория

### 1. GPO

```powershell
Get-GPO -All | Select-Object DisplayName,Id,GpoStatus
gpresult /r /scope:computer
gpresult /h C:\lab\gpresult.html
```

Ожидаемо: список политик и отчёт. Откройте HTML и найдите, какие политики применились к компьютеру и пользователю.

Создайте политику:

```powershell
New-GPO -Name "Lab-LegalNotice" | New-GPLink -Target "OU=Workstations,DC=lab,DC=local"
Set-GPRegistryValue -Name "Lab-LegalNotice" `
  -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
  -ValueName "LegalNoticeCaption" -Type String -Value "Lab"
gpupdate /force
gpresult /r | Select-String "Lab-LegalNotice"
```

Ожидаемо: политика прилинкована и применена.

### 2. ACL

```powershell
Import-Module ActiveDirectory
$ou = "OU=Staff,DC=lab,DC=local"
(Get-Acl "AD:\$ou").Access |
  Select-Object IdentityReference,ActiveDirectoryRights,AccessControlType
```

Ожидаемо: список ACE. Ищите `GenericAll`, `WriteDACL`, `WriteOwner` у не-админских групп.

Выдать опасное право (демо):

```powershell
dsacls "OU=Staff,DC=lab,DC=local" /G "LAB\helpdesk:GA"
dsacls "OU=Staff,DC=lab,DC=local" | Select-String "helpdesk"
```

Ожидаемо: `helpdesk` получил `GENERIC_ALL` на OU. Это модель ACL-атаки из M11.

### 3. SYSVOL и cpassword

```powershell
net use \\lab.local\SYSVOL /user:LAB\alice Passw0rd!
dir \\lab.local\SYSVOL\lab.local\scripts
findstr /S /I "cpassword" \\lab.local\SYSVOL\lab.local\*.*
```

Если ничего нет — создайте демо-файл (только в лабе):

```powershell
$xml = @'
<?xml version="1.0" encoding="utf-8"?>
<Groups><User><Properties action="U" newName="" cpassword="VPe/o9YRyz2cksnYRbNeQj1r0a9Q" userName="LAB\svc_old"/></Properties></User></Groups>
'@
Set-Content -Path \\lab.local\SYSVOL\lab.local\scripts\Groups.xml -Value $xml
findstr /S /I "cpassword" \\lab.local\SYSVOL\lab.local\*.*
```

Ожидаемо: находка `cpassword`. Расшифровка — через `gpp-decrypt` (Kali) или соответствующий скрипт. Смысл: пароль сервисной учётки лежит в открытом виде для всех, кто читает SYSVOL.

### 4. Доверия

```powershell
nltest /domain_trusts /all_trusts /v
Get-ADTrust -Filter *
```

Ожидаемо: список доверий (в лаборатории может быть пусто). Для одного домена — нормально.

## Атака и защита

- **Атака:** ACL abuse (дать себе права), GPO abuse (изменить политику → код на всех хостах), cpassword из SYSVOL, trust abuse с SID history.
- **Детект:** 5136 (изменение объекта AD), 4662 (доступ), изменения GPO (Audit Directory Service Access), чтение SYSVOL.
- **Фикс:** аудит ACL, удаление cpassword и старых скриптов, минимальные права на GPO, tiering, SID filtering, мониторинг изменений.

## Самопроверка

- [ ] В каком порядке применяются GPO и что сильнее — Enforced или Block Inheritance?
- [ ] Чем `GenericAll` на OU опасен для всех объектов внутри?
- [ ] Почему `cpassword` можно расшифровать без ключа?
- [ ] Что такое SID filtering при доверии?

## Дальше

[5.5 — Строим лабораторный домен](l05-build-domain.md)
