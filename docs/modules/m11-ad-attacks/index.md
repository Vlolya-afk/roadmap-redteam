# M11 — AD-атаки

> **Этап 2 · 6 занятий · ~30 часов · артефакты в `labs/m11-ad-attacks/`**

## Зачем этот модуль

Active Directory — сердце корпоративных сетей. Здесь одна ошибка конфигурации превращается в доступ ко всему домену: Kerberoasting, ACL, делегирование, ADCS. Это ядро работы red team в Windows-среде.

## Чему научитесь

- Строить карту домена через PowerView и BloodHound.
- Забирать сервисные аккаунты через Kerberoasting/AS-REP.
- Использовать ACL и делегирование вместо грубого брутфорса.
- Эксплуатировать ADCS (ESC1–ESC8) и доверия между доменами.
- Понимать, какие артефакты оставляет каждый шаг.

## Занятия

| # | Тема | Время | Артефакт |
|---|---|---|---|
| [11.1](l01-ad-enum.md) | Enumeration: PowerView, BloodHound | 5 ч | `enum/` |
| [11.2](l02-kerberos-attacks.md) | Kerberoasting, AS-REP, spraying | 5 ч | `kerberos/` |
| [11.3](l03-acl-abuse.md) | ACL abuse | 5 ч | `acl/` |
| [11.4](l04-delegation.md) | Delegation | 4 ч | `delegation/` |
| [11.5](l05-adcs.md) | ADCS: ESC1–ESC8 | 6 ч | `adcs/` |
| [11.6](l06-trusts-tickets.md) | Trusts и тикеты | 5 ч | `trusts/` |

## Критерии выхода

- [ ] Строите BloodHound-граф и находите кратчайший путь к DA.
- [ ] Объясняете разницу Kerberoasting и AS-REP roasting.
- [ ] Используете `GenericAll`/`WriteDACL` для эскалации.
- [ ] Находите misconfigured delegation и эксплуатируете.
- [ ] Поднимаете ESC1 в лабе и понимаете фикс.
- [ ] Для каждого шага называете событие/лог.

## Контрольная

[exam.md](exam.md): BloodHound-путь, Kerberoasting + ACL, полная цепочка до Domain Admin.

## Этика

Все действия — только в собственном домене `lab.local` на изолированной сети VMnet2. Атаки на AD в чужой сети — это уголовная ответственность, а не «проверка».
