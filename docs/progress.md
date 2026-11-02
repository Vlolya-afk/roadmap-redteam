# Прогресс

Отмечайте `[x]`, когда урок закрыт: сделана лаба, написан writeup, пройдена самопроверка. Модуль закрыт, когда решена контрольная минимум на 🟡.

## Сводка

| Этап | Модулей | Уроков | Контрольных | Закрыто |
|---|---:|---:|---:|---:|
| 0. База | 6 | 27 | 6 | 0 |
| 1. Атакующая база | 5 | 24 | 5 | 0 |
| 2. Red team core | 5 | 24 | 5 | 0 |
| 3. Senior-широта | 5 | 19 | 5 | 0 |
| **Итого** | **21** | **94** | **21** | **0** |

## Этап 0 — База

### M00 — Старт, лаборатория, правила игры
- [ ] [L01 Этика, закон, scope, OPSEC](modules/m00-start/l01-rules-of-engagement.md)
- [ ] [L02 Установка Arch Linux](modules/m00-start/l02-arch-install.md)
- [ ] [L03 Лаборатория на VMware](modules/m00-start/l03-vmware-lab.md)
- [ ] [Контрольная M00](modules/m00-start/exam.md) · артефакт: `labs/m00-start/writeup.md`

### M01 — Linux и командная строка
- [ ] [L01 Файлы, права, пользователи](modules/m01-linux/l01-files-perms.md)
- [ ] [L02 Процессы, systemd, логи](modules/m01-linux/l02-processes-systemd.md)
- [ ] [L03 Пакеты, сборка, окружение](modules/m01-linux/l03-packages.md)
- [ ] [L04 Сеть в Linux и SSH](modules/m01-linux/l04-networking-ssh.md)
- [ ] [L05 Bash-скрипты и охота на бэкдор](modules/m01-linux/l05-bash-forensics.md)
- [ ] [Контрольная M01](modules/m01-linux/exam.md) · артефакт: `labs/m01-linux/`

### M02 — Сети и протоколы
- [ ] [L01 OSI/TCP-IP, Ethernet, ARP](modules/m02-networking/l01-osi-ethernet-arp.md)
- [ ] [L02 IP, подсети, маршрутизация, NAT](modules/m02-networking/l02-ip-routing-nat.md)
- [ ] [L03 TCP/UDP, порты, ручное сканирование](modules/m02-networking/l03-tcp-udp.md)
- [ ] [L04 DNS, HTTP, TLS](modules/m02-networking/l04-dns-http-tls.md)
- [ ] [L05 Захват и разбор трафика](modules/m02-networking/l05-packet-capture.md)
- [ ] [Контрольная M02](modules/m02-networking/exam.md) · артефакт: `labs/m02-networking/`

### M03 — Python, Bash, Git
- [ ] [L01 Python: ядро языка](modules/m03-scripting/l01-python-core.md)
- [ ] [L02 Python для сетей и безопасности](modules/m03-scripting/l02-python-security.md)
- [ ] [L03 Bash, Git и документация](modules/m03-scripting/l03-bash-git.md)
- [ ] [L04 C/ASM и чтение чужого кода](modules/m03-scripting/l04-c-asm-reversing.md)
- [ ] [Контрольная M03](modules/m03-scripting/exam.md) · артефакт: `labs/m03-scripting/`

### M04 — Web, HTTP, криптография
- [ ] [L01 HTTP глубже](modules/m04-web-crypto/l01-http-deep.md)
- [ ] [L02 Архитектура приложений и сессии](modules/m04-web-crypto/l02-app-architecture.md)
- [ ] [L03 Криптография: хэши, шифры, KDF](modules/m04-web-crypto/l03-crypto.md)
- [ ] [L04 TLS и PKI](modules/m04-web-crypto/l04-tls-pki.md)
- [ ] [L05 OWASP Top 10 вживую](modules/m04-web-crypto/l05-owasp-lab.md)
- [ ] [Контрольная M04](modules/m04-web-crypto/exam.md) · артефакт: `labs/m04-web-crypto/`

### M05 — Windows и Active Directory: база
- [ ] [L01 Windows: архитектура, реестр, службы](modules/m05-windows-ad/l01-windows-internals.md)
- [ ] [L02 AD DS: лес, домен, OU, LDAP](modules/m05-windows-ad/l02-ad-structure.md)
- [ ] [L03 NTLM и Kerberos](modules/m05-windows-ad/l03-auth-protocols.md)
- [ ] [L04 GPO, ACL, SYSVOL, trusts](modules/m05-windows-ad/l04-gpo-acl.md)
- [ ] [L05 Строим лабораторный домен](modules/m05-windows-ad/l05-build-domain.md)
- [ ] [Контрольная M05](modules/m05-windows-ad/exam.md) · артефакт: `labs/m05-windows-ad/`

## Этап 1 — Атакующая база

### M06 — Recon и OSINT
- [ ] [L01 Пассивный recon](modules/m06-recon/l01-passive-recon.md)
- [ ] [L02 OSINT по людям и организациям](modules/m06-recon/l02-osint-people.md)
- [ ] [L03 Активный recon](modules/m06-recon/l03-active-recon.md)
- [ ] [L04 Карта инфраструктуры и таргетинг](modules/m06-recon/l04-attack-surface-map.md)
- [ ] [Контрольная M06](modules/m06-recon/exam.md) · артефакт: `labs/m06-recon/`

### M07 — Сетевые атаки и MITM
- [ ] [L01 ARP spoofing и MITM](modules/m07-network-attacks/l01-arp-mitm.md)
- [ ] [L02 LLMNR/NBT-NS/mDNS poisoning](modules/m07-network-attacks/l02-name-resolution-poisoning.md)
- [ ] [L03 SMB relay и перехват NTLM](modules/m07-network-attacks/l03-smb-relay.md)
- [ ] [L04 VLAN hopping, DHCP, 802.1X](modules/m07-network-attacks/l04-l2-attacks.md)
- [ ] [L05 Защита и детект L2-атак](modules/m07-network-attacks/l05-defense-detection.md)
- [ ] [Контрольная M07](modules/m07-network-attacks/exam.md) · артефакт: `labs/m07-network-attacks/`

### M08 — Web/API-эксплуатация
- [ ] [L01 SQL-инъекции](modules/m08-web-api/l01-sqli.md)
- [ ] [L02 XSS и CSRF](modules/m08-web-api/l02-xss-csrf.md)
- [ ] [L03 SSRF, XXE, file inclusion/upload](modules/m08-web-api/l03-ssrf-xxe-lfi.md)
- [ ] [L04 Десериализация, SSTI, RCE](modules/m08-web-api/l04-deserialization-ssti.md)
- [ ] [L05 Аутентификация: JWT, OAuth, сессии](modules/m08-web-api/l05-auth-jwt-oauth.md)
- [ ] [L06 API: BOLA, mass assignment, GraphQL](modules/m08-web-api/l06-api.md)
- [ ] [Контрольная M08](modules/m08-web-api/exam.md) · артефакт: `labs/m08-web-api/`

### M09 — Сканирование, CVE, эксплуатация
- [ ] [L01 Сканирование и приоритизация](modules/m09-exploitation/l01-scanning.md)
- [ ] [L02 Research CVE и проверка PoC](modules/m09-exploitation/l02-cve-research.md)
- [ ] [L03 Ручная эксплуатация и Metasploit](modules/m09-exploitation/l03-exploitation.md)
- [ ] [L04 Отчёт по уязвимостям и retest](modules/m09-exploitation/l04-vuln-report.md)
- [ ] [Контрольная M09](modules/m09-exploitation/exam.md) · артефакт: `labs/m09-exploitation/`

### M10 — Повышение привилегий
- [ ] [L01 Linux enumeration](modules/m10-privesc/l01-linux-enum.md)
- [ ] [L02 Linux privesc](modules/m10-privesc/l02-linux-privesc.md)
- [ ] [L03 Windows enumeration](modules/m10-privesc/l03-windows-enum.md)
- [ ] [L04 Windows privesc](modules/m10-privesc/l04-windows-privesc.md)
- [ ] [L05 Дамп кредов и reuse](modules/m10-privesc/l05-credential-dumping.md)
- [ ] [Контрольная M10](modules/m10-privesc/exam.md) · артефакт: `labs/m10-privesc/`

## Этап 2 — Red team core

### M11 — AD-атаки
- [ ] [L01 Enumeration: PowerView, BloodHound](modules/m11-ad-attacks/l01-ad-enum.md)
- [ ] [L02 Kerberoasting, AS-REP, spraying](modules/m11-ad-attacks/l02-kerberos-attacks.md)
- [ ] [L03 ACL abuse](modules/m11-ad-attacks/l03-acl-abuse.md)
- [ ] [L04 Delegation](modules/m11-ad-attacks/l04-delegation.md)
- [ ] [L05 ADCS: ESC1–ESC8](modules/m11-ad-attacks/l05-adcs.md)
- [ ] [L06 Trusts и тикеты](modules/m11-ad-attacks/l06-trusts-tickets.md)
- [ ] [Контрольная M11](modules/m11-ad-attacks/exam.md) · артефакт: `labs/m11-ad-attacks/`

### M12 — Обход защиты Windows
- [ ] [L01 Как работают AV/EDR](modules/m12-evasion/l01-av-edr-architecture.md)
- [ ] [L02 Payload: shellcode и стадии](modules/m12-evasion/l02-payloads.md)
- [ ] [L03 Лоадеры и обход AMSI/ETW](modules/m12-evasion/l03-loaders-amsi-etw.md)
- [ ] [L04 LOLBins и AppLocker](modules/m12-evasion/l04-lolbins-applocker.md)
- [ ] [L05 Тест против Defender и телеметрия](modules/m12-evasion/l05-defender-test.md)
- [ ] [Контрольная M12](modules/m12-evasion/exam.md) · артефакт: `labs/m12-evasion/`

### M13 — Initial access, фишинг, C2
- [ ] [L01 Фишинг-инфраструктура и evilginx](modules/m13-initial-access-c2/l01-phishing-infra.md)
- [ ] [L02 Payload delivery и Mark-of-the-Web](modules/m13-initial-access-c2/l02-payload-delivery.md)
- [ ] [L03 C2: Sliver/Havoc](modules/m13-initial-access-c2/l03-c2.md)
- [ ] [L04 Redirectors и профили](modules/m13-initial-access-c2/l04-redirectors.md)
- [ ] [L05 OPSEC C2 и burn-план](modules/m13-initial-access-c2/l05-c2-opsec.md)
- [ ] [Контрольная M13](modules/m13-initial-access-c2/exam.md) · артефакт: `labs/m13-initial-access-c2/`

### M14 — Pivoting, туннели, инфраструктура
- [ ] [L01 SSH-туннели и chisel](modules/m14-pivoting-infra/l01-tunnels.md)
- [ ] [L02 SOCKS, proxychains, двойной pivot](modules/m14-pivoting-infra/l02-socks-pivot.md)
- [ ] [L03 Инфраструктура как код](modules/m14-pivoting-infra/l03-infra-as-code.md)
- [ ] [L04 OPSEC инфраструктуры](modules/m14-pivoting-infra/l04-infra-opsec.md)
- [ ] [Контрольная M14](modules/m14-pivoting-infra/exam.md) · артефакт: `labs/m14-pivoting-infra/`

### M15 — Red team операции и отчётность
- [ ] [L01 Скоуп, RoE, deconfliction](modules/m15-rt-ops/l01-scope-roe.md)
- [ ] [L02 Планирование операции и MITRE](modules/m15-rt-ops/l02-op-planning.md)
- [ ] [L03 Отчёт: от executive summary до evidence](modules/m15-rt-ops/l03-reporting.md)
- [ ] [L04 Debrief и purple feedback](modules/m15-rt-ops/l04-debrief.md)
- [ ] [Контрольная M15](modules/m15-rt-ops/exam.md) · артефакт: `labs/m15-rt-ops/`

## Этап 3 — Senior-широта

### M16 — Cloud и Kubernetes
- [ ] [L01 AWS IAM и privesc](modules/m16-cloud-k8s/l01-aws-iam.md)
- [ ] [L02 Azure/Entra ID](modules/m16-cloud-k8s/l02-azure-entra.md)
- [ ] [L03 Kubernetes: RBAC и SA abuse](modules/m16-cloud-k8s/l03-kubernetes.md)
- [ ] [L04 Container escape и cloud detection](modules/m16-cloud-k8s/l04-container-cloud-detect.md)
- [ ] [Контрольная M16](modules/m16-cloud-k8s/exam.md) · артефакт: `labs/m16-cloud-k8s/`

### M17 — Detection engineering / purple
- [ ] [L01 Телеметрия: Sysmon, auditd, EDR](modules/m17-detection/l01-telemetry.md)
- [ ] [L02 Sigma и маппинг на MITRE](modules/m17-detection/l02-sigma.md)
- [ ] [L03 SIEM: Wazuh/ELK](modules/m17-detection/l03-siem.md)
- [ ] [L04 Purple loop](modules/m17-detection/l04-purple-loop.md)
- [ ] [Контрольная M17](modules/m17-detection/exam.md) · артефакт: `labs/m17-detection/`

### M18 — Hardware, RF, Wi-Fi, OT
- [ ] [L01 Wi-Fi: handshake, PMKID, deauth](modules/m18-hardware-rf-ot/l01-wifi.md)
- [ ] [L02 SDR и разбор сигналов](modules/m18-hardware-rf-ot/l02-sdr.md)
- [ ] [L03 Физическая безопасность и RFID](modules/m18-hardware-rf-ot/l03-physical-rfid.md)
- [ ] [L04 OT/ICS: Modbus и Purdue](modules/m18-hardware-rf-ot/l04-ot-ics.md)
- [ ] [Контрольная M18](modules/m18-hardware-rf-ot/exam.md) · артефакт: `labs/m18-hardware-rf-ot/`

### M19 — Mobile и реверс
- [ ] [L01 Android: APK, adb, Frida](modules/m19-mobile/l01-android.md)
- [ ] [L02 Мобильный пентест и pinning bypass](modules/m19-mobile/l02-mobile-pentest.md)
- [ ] [L03 iOS кратко и отчёт](modules/m19-mobile/l03-ios-report.md)
- [ ] [Контрольная M19](modules/m19-mobile/exam.md) · артефакт: `labs/m19-mobile/`

### M20 — Research, tooling, карьера
- [ ] [L01 Как делать исследования и disclosure](modules/m20-research-career/l01-research.md)
- [ ] [L02 Свой инструмент](modules/m20-research-career/l02-tooling.md)
- [ ] [L03 Публикации и конференции](modules/m20-research-career/l03-publications.md)
- [ ] [L04 Senior-компетенции и карьера](modules/m20-research-career/l04-career.md)
- [ ] [Контрольная M20](modules/m20-research-career/exam.md) · артефакт: `labs/m20-research-career/`

## Capstone

- [ ] [Финальная операция](capstone/index.md)
- [ ] [Экзамен capstone](capstone/exam-final.md) · артефакт: `labs/capstone/`
