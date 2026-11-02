# Глоссарий

Термины, которые встречаются в треке. Английский вариант — то, что вы увидите в инструментах и на собеседовании.

## Сети

| Термин | EN | Смысл |
|---|---|---|
| Пакет | packet | Единица данных в сети; заголовок + полезная нагрузка |
| Кадр | frame | Пакет на канальном уровне (Ethernet) |
| Инкапсуляция | encapsulation | Вложение протокола в протокол: HTTP → TCP → IP → Ethernet |
| ARP | Address Resolution Protocol | IP → MAC в локальной сети; основа L2-атак |
| Шлюз | gateway | Узел, через который идёт трафик за пределы подсети |
| NAT | Network Address Translation | Подмена адресов при выходе в другую сеть |
| VLAN | Virtual LAN | Логическое разделение L2-сегмента |
| CIDR | Classless Inter-Domain Routing | Запись подсети: `10.10.10.0/24` |
| MITM | Man-in-the-Middle | Атакующий в разрыве канала |
| pcap | packet capture | Файл с записанным трафиком |

## Linux

| Термин | EN | Смысл |
|---|---|---|
| Ядро | kernel | Управляет железом, процессами, памятью |
| Пространство пользователя | userland | Всё, что работает поверх ядра |
| systemd | — | init и менеджер служб |
| Юнит | unit | Описание службы/таймера/точки монтирования в systemd |
| SUID | setuid | Бит, при котором программа запускается с правами владельца |
| Capabilities | capabilities | Дробные привилегии вместо полного root |
| Namespace | namespace | Изоляция ресурсов (PID, сеть, mount) — база контейнеров |
| cgroup | control group | Ограничение ресурсов процесса |
| sudoers | — | Политика, кому и что можно через sudo |

## Web

| Термин | EN | Смысл |
|---|---|---|
| Заголовок | header | Метаданные HTTP-запроса/ответа |
| Cookie | cookie | Данные, которые браузер хранит и отправляет серверу |
| Сессия | session | Состояние аутентифицированного пользователя |
| CSRF | Cross-Site Request Forgery | Запрос от имени пользователя без его ведома |
| XSS | Cross-Site Scripting | Внедрение JS в страницу |
| SSRF | Server-Side Request Forgery | Сервер делает запрос по адресу атакующего |
| IDOR/BOLA | Insecure Direct Object Reference | Доступ к чужому объекту по ID |
| JWT | JSON Web Token | Подписанный токен с claims |
| OAuth/OIDC | — | Протоколы делегированной авторизации/аутентификации |
| WAF | Web Application Firewall | Фильтр HTTP-трафика |

## Криптография

| Термин | EN | Смысл |
|---|---|---|
| Хэш | hash | Одностороннее преобразование фиксированной длины |
| Соль | salt | Случайная добавка к паролю перед хэшированием |
| KDF | Key Derivation Function | Медленное преобразование пароля в ключ (PBKDF2, Argon2) |
| Симметричное шифрование | symmetric | Один ключ для шифрования и расшифровки (AES) |
| Асимметричное | asymmetric | Пара ключей: публичный/приватный (RSA, ECDSA) |
| IV/Nonce | initialization vector | Уникальное значение для режима шифрования |
| TLS | Transport Layer Security | Шифрование канала |
| PKI | Public Key Infrastructure | Иерархия доверия сертификатов |
| CA | Certificate Authority | Удостоверяющий центр |
| CSR | Certificate Signing Request | Запрос на выпуск сертификата |

## Windows и AD

| Термин | EN | Смысл |
|---|---|---|
| Реестр | registry | Иерархическая база настроек Windows |
| SAM | Security Account Manager | Локальная база учёток |
| LSASS | Local Security Authority Subsystem | Процесс, хранящий секреты сессии |
| NTLM | — | Хэш пароля и протокол аутентификации |
| Kerberos | — | Протокол аутентификации на тикетах |
| TGT | Ticket Granting Ticket | Тикет на получение других тикетов |
| TGS | Ticket Granting Service | Тикет доступа к конкретному сервису |
| SPN | Service Principal Name | Имя сервиса, привязанное к учётке |
| OU | Organizational Unit | Контейнер объектов в AD |
| GPO | Group Policy Object | Политика конфигурации |
| ACL | Access Control List | Список прав на объект |
| ACE | Access Control Entry | Одна запись в ACL |
| SID | Security Identifier | Уникальный идентификатор субъекта |
| DC | Domain Controller | Контроллер домена |
| DA | Domain Admin | Администратор домена |
| ADCS | AD Certificate Services | PKI внутри AD |
| gMSA | Group Managed Service Account | Управляемая сервисная учётка с автосменой пароля |

## Атаки и red team

| Термин | EN | Смысл |
|---|---|---|
| TTP | Tactics, Techniques, Procedures | Образ действий атакующего |
| IOC | Indicator of Compromise | Признак компрометации |
| C2 | Command and Control | Канал управления имплантом |
| Имплант | implant/beacon | Вредоносная часть на хосте |
| Лоадер | loader | Код, который загружает и запускает payload |
| Shellcode | — | Позиционно-независимый машинный код |
| OPSEC | Operational Security | Гигиена операции: не спалиться |
| Pivoting | — | Перемещение через скомпрометированный хост |
| PrivEsc | Privilege Escalation | Повышение привилегий |
| Lateral movement | — | Перемещение между хостами |
| Persistence | — | Закрепление на хосте |
| Exfiltration | — | Вынос данных |
| RoE | Rules of Engagement | Правила и рамки работ |
| Scope | — | Разрешённые активы |
| Deconfliction | — | Согласование, чтобы blue не приняли вас за реального атакующего |
| Purple team | — | Совместная работа red и blue |
| Adversary emulation | — | Воспроизведение поведения конкретной группы |
| Living off the land | LOTL/LOLBins | Использование легитимных средств системы |

## Защита

| Термин | EN | Смысл |
|---|---|---|
| EDR | Endpoint Detection and Response | Агент на хосте с телеметрией и реакцией |
| AV | Antivirus | Сигнатурный/эвристический антивирус |
| AMSI | Antimalware Scan Interface | Интерфейс сканирования скриптов в Windows |
| ETW | Event Tracing for Windows | Трассировка событий |
| Sysmon | — | Драйвер расширенного логирования Windows |
| SIEM | Security Information and Event Management | Сбор и корреляция логов |
| Sigma | — | Универсальный формат правил детекта |
| YARA | — | Правила поиска по бинарным паттернам |
| Detection engineering | — | Проектирование и тюнинг детектов |
| False positive / negative | FP/FN | Ложное срабатывание / пропуск |

## Облако и контейнеры

| Термин | EN | Смысл |
|---|---|---|
| IAM | Identity and Access Management | Пользователи, роли, политики |
| STS | Security Token Service | Временные креды |
| AssumeRole | — | Получение роли через API |
| Entra ID | (бывш. Azure AD) | Identity-провайдер Azure |
| Service Account | — | Учётка для сервиса |
| Pod | — | Минимальная единица в Kubernetes |
| RBAC | Role-Based Access Control | Роли и привязки в K8s |
| ServiceAccount token | — | Токен пода для доступа к API |
| Container escape | — | Выход из контейнера на хост |
| CSPM | Cloud Security Posture Management | Контроль конфигурации облака |

## Организационное

| Термин | EN | Смысл |
|---|---|---|
| Pentest | penetration test | Согласованная проверка на проникновение |
| Bug bounty | — | Программа выплат за найденные уязвимости |
| VDP | Vulnerability Disclosure Program | Программа ответственного раскрытия |
| CVSS | — | Оценка критичности уязвимости |
| EPSS | Exploit Prediction Scoring System | Вероятность эксплуатации в ближайшие 30 дней |
| CVE | Common Vulnerabilities and Exposures | Идентификатор уязвимости |
| CWE | Common Weakness Enumeration | Класс слабости |
| MITRE ATT&CK | — | База TTP атакующих |
| Kill chain | — | Стадии атаки |
| Threat model | — | Модель угроз |
