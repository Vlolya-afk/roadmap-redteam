# M16 — Cloud и Kubernetes

> **Этап 3 · 4 занятия · ~22 часа · артефакты в `labs/m16-cloud-k8s/`**

## Зачем этот модуль

Периметр уехал в облако. Теперь доступ — это IAM-политика, роль, service account или токен, а не открытый порт. Senior обязан понимать AWS, Azure/Entra и Kubernetes хотя бы на уровне атаки и защиты.

## Чему научитесь

- Находить privesc в AWS IAM.
- Атаковать Entra ID и Azure RBAC.
- Эксплуатировать Kubernetes RBAC и service account.
- Понимать container escape и cloud-детект.

## Занятия

| # | Тема | Время | Артефакт |
|---|---|---|---|
| [16.1](l01-aws-iam.md) | AWS IAM и privesc | 6 ч | `aws/` |
| [16.2](l02-azure-entra.md) | Azure/Entra ID | 6 ч | `azure/` |
| [16.3](l03-kubernetes.md) | Kubernetes: RBAC и SA abuse | 5 ч | `k8s/` |
| [16.4](l04-container-cloud-detect.md) | Container escape и cloud detection | 5 ч | `detect/` |

## Критерии выхода

- [ ] Читаете IAM-политику и находите путь к admin.
- [ ] Понимаете разницу Entra ID и Azure RBAC.
- [ ] Эксплуатируете over-permissioned service account.
- [ ] Объясняете container escape и как его детектить.

## Контрольная

[exam.md](exam.md): IAM-путь, Entra/K8s-атака, детект и отчёт.

## Бюджет и этика

AWS/Azure — только free tier или локальные эмуляторы (LocalStack, Azurite, k3d/kind). Не оставляйте включённые ресурсы. Атаки — только на собственные аккаунты. Чужие cloud-аккаунты — это не «лаборатория», а уголовное дело.
