# 17.3 — SIEM: Wazuh/ELK

> **M17 · Этап 3 · 5 ч · 🟡 · артефакт:** `labs/m17-detection/l03-siem/`

## Цель

Поднять SIEM, подключить источники, написать алерт и убедиться, что он срабатывает на вашу атаку.

## Результат

- Wazuh/ELK с логами Windows/Linux.
- 2 алерта.
- Дашборд.

## Теория

### 1. Компоненты

- **Collection** — агенты, syslog, API.
- **Parsing** — декодеры, нормализация.
- **Storage** — Elasticsearch/OpenSearch.
- **Detection** — правила.
- **Visualization** — Kibana/OpenSearch Dashboards.
- **Response** — активные действия.

### 2. Wazuh

Проще для старта:

```bash
docker compose -f wazuh-docker/single-node/docker-compose.yml up -d
```

Агент на Windows/Linux, правила в `/var/ossec/etc/rules/`.

### 3. ELK

Гибче, но тяжелее. Для 16 ГБ — Elasticsearch + Kibana + Filebeat, без лишнего.

### 4. Правила

Wazuh:

```xml
<group name="windows,">
  <rule id="100001" level="10">
    <if_sid>60009</if_sid>
    <field name="win.eventdata.image">certutil.exe</field>
    <description>Certutil execution</description>
  </rule>
</group>
```

### 5. Тюнинг

- Исключения для легитимных действий.
- Порог и корреляция.
- Контекст (пользователь, хост, время).
- Не «алерт на всё».

### 6. Метрики

- MTTD (mean time to detect).
- FP rate.
- Coverage.

## Лаборатория

> `LNX01` (SIEM) + `WIN01` (агент). 16 ГБ — используйте single-node.

### 1. Запуск

```bash
git clone https://github.com/wazuh/wazuh-docker.git
cd wazuh-docker/single-node
docker compose up -d
```

Ожидаемо: Kibana на `https://localhost:443`.

### 2. Агент

Установите Wazuh-агент на `WIN01`, подключите к `10.10.10.50`.

Ожидаемо: агент `Active`.

### 3. События

```bash
docker exec -it wazuh-wazuh.manager-1 tail -f /var/ossec/logs/alerts/alerts.log
```

Ожидаемо: события с `WIN01`.

### 4. Правило

Добавьте правило на `certutil`. Перезапустите менеджер.

```bash
docker exec -it wazuh-wazuh.manager-1 /var/ossec/bin/wazuh-control restart
```

### 5. Проверка

```powershell
certutil -urlcache -split -f http://10.10.10.50/test.txt C:\lab\t.txt
```

Ожидаемо: алерт уровня 10.

### 6. Дашборд

Соберите панель: события по хостам, топ правил, таймлайн.

## Атака и защита

- **Атака:** обойти правило/порог.
- **Детект:** корреляция, контекст.
- **Фикс:** тюнинг, ревью, покрытие.

## Самопроверка

- [ ] Чем Wazuh проще ELK?
- [ ] Что такое decoder?
- [ ] Как проверить правило?
- [ ] Почему алерты без тюнинга бесполезны?
- [ ] Какие метрики смотреть?

## Дальше

[17.4 — Purple loop](l04-purple-loop.md)
