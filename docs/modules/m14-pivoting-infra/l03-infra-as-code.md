# 14.3 — Инфраструктура как код

> **M14 · Этап 2 · 5 ч · 🟡 · артефакт:** `labs/m14-pivoting-infra/l03-iac/`

## Цель

Сделать лабораторию воспроизводимой: Terraform/Ansible/Docker Compose, конфиги в git, одна команда — и стенд готов.

## Результат

- Репозиторий с IaC для лаборатории.
- `make up` / `make down`, которые работают.
- Документация: что разворачивается и зачем.

## Теория

### 1. Зачем IaC в security

- Повторяемость: одинаковый стенд для уроков и экзаменов.
- Версионирование: видно, что изменилось.
- Быстрый снос: меньше забытых артефактов.
- Документация как код.

### 2. Инструменты

| Инструмент | Для чего |
|---|---|
| Terraform | ВМ/сеть в VMware/vSphere/cloud |
| Ansible | конфигурация ОС, пакеты, сервисы |
| Docker Compose | сервисы (DVWA, Juice Shop, MailHog, Wazuh) |
| Packer | образы |
| cloud-init | первичная настройка |

### 3. Docker Compose для лабы

```yaml
services:
  dvwa:
    image: vulnerables/web-dvwa
    ports: ["8080:80"]
  juice:
    image: bkimminich/juice-shop
    ports: ["3000:3000"]
  mailhog:
    image: mailhog/mailhog
    ports: ["1025:1025", "8025:8025"]
```

```bash
docker compose up -d
```

### 4. Ansible

```yaml
- hosts: lab
  become: true
  tasks:
    - name: install tools
      pacman:
        name: [nmap, tcpdump, wireshark-qt, git]
        state: present
```

```bash
ansible-playbook -i inventory.ini lab.yml
```

### 5. Terraform (VMware)

Провайдер `vmware/vsphere` или `hashicorp/vsphere`. Для локальной VMware Workstation проще `govc`/`vmrun` или Vagrant. В курсе достаточно показать принцип и один рабочий пример.

### 6. Гигиена

- Секреты — в vault/переменных, не в git.
- `.gitignore` для state и ключей.
- Версии образов фиксированы.
- README с prerequisites.

## Лаборатория

> Ваш репозиторий `labs/`.

### 1. Compose

Создайте `labs/m14-pivoting-infra/l03-iac/compose.yml` с DVWA и MailHog. Запустите.

```bash
docker compose up -d
curl -I http://127.0.0.1:8080
```

Ожидаемо: 200/302.

### 2. Ansible

Создайте `inventory.ini` и `lab.yml` (пример выше). Запустите на `LNX01`.

```bash
ansible-playbook -i inventory.ini lab.yml --check
```

Ожидаемо: `changed=0` после первого прогона (идемпотентность).

### 3. Makefile

```makefile
up:
	docker compose up -d
down:
	docker compose down -v
logs:
	docker compose logs -f
```

Проверьте `make up`/`make down`.

### 4. Секреты

Убедитесь, что в репозитории нет паролей. Проверьте:

```bash
git grep -i "password\|secret\|token" -- . ':!*.md'
```

Ожидаемо: пусто или только примеры.

### 5. Документация

`README.md`: prerequisites, `make up`, порты, как снести.

## Атака и защита

- **Атака:** (в контексте) быстро пересобрать инфраструктуру после сжигания.
- **Детект:** IaC-артефакты в git, необычные образы.
- **Фикс:** ревью IaC, сканирование секретов, фиксация версий.

## Самопроверка

- [ ] Чем Terraform отличается от Ansible?
- [ ] Зачем фиксировать версии образов?
- [ ] Как избежать секретов в git?
- [ ] Что такое идемпотентность?
- [ ] Почему `make down -v` важен?

## Дальше

[14.4 — OPSEC инфраструктуры](l04-infra-opsec.md)
