# 3.3 — Bash, Git и документация

> **M03 · Этап 0 · 3 ч · 🟢 · артефакт:** `labs/m03-scripting/l03-git/`

## Цель

Научиться вести репозиторий так, чтобы по нему было видно прогресс, и писать README, который читают.

## Результат

- Репозиторий с осмысленной историей и `.gitignore`.
- Понимание веток, merge и `git log --graph`.
- Умение проверить, не попали ли в git секреты.

## Теория

- Git хранит снимки, а не diff; коммит = снимок + родитель + сообщение.
- `add` — в индекс, `commit` — в историю; `diff` показывает разницу между состояниями.
- Ветка — указатель на коммит; merge создаёт коммит с двумя родителями.
- `.gitignore` не удаляет уже отслеживаемые файлы — их нужно `git rm --cached`.
- Секрет, попавший в историю, остаётся там навсегда. `git filter-repo` — не серебряная пуля, лучше не коммитить.
- README отвечает на три вопроса: что это, зачем, как запустить.

## Лаборатория

### 1. Инициализация

```bash
mkdir -p labs/m03-scripting/l03-git && cd labs/m03-scripting/l03-git
git init -b main
git config user.name "Your Name"
git config user.email "you@example.com"

cat > .gitignore <<'EOF'
*.pcap
*.log
.env
secrets/
__pycache__/
EOF

cat > README.md <<'EOF'
# Log parser

Считает события аутентификации по IP.

## Usage

```bash
python logparse.py auth.log --top 10
```
EOF

git add .gitignore README.md
git commit -m "chore: initial repo layout"
```

Ожидаемо: `git log --oneline` — один коммит.

### 2. История

```bash
cp ../../l01-logparse/logparse.py .
git add logparse.py
git commit -m "feat: add auth log parser"

git switch -c experiment/csv
# добавьте --csv (или сделайте вид, что добавили)
git add -A && git commit -m "feat: csv output"
git switch main
git merge experiment/csv
git log --oneline --graph --all
```

Ожидаемо: граф с веткой и merge (или fast-forward).

### 3. Проверка на секреты

```bash
grep -rInE '(password|passwd|api[_-]?key|token|secret)\s*=' . --exclude-dir=.git || echo "clean"
git log -p | grep -iE 'password|api[_-]?key' || echo "no secrets in history"
```

Ожидаемо: `clean` и `no secrets in history`. Если нашли — удалите файл, добавьте в `.gitignore`, при необходимости перепишите историю.

### 4. Плохой и хороший коммит

Плохо: `fix`, `update`, `asdf`.
Хорошо: `feat(scanner): add timeout and worker pool`, `docs: explain CSV format`.

Сделайте три коммита по конвенции `type(scope): subject`.

## Атака и защита

- **Атака:** секреты в git — классика утечек; публичный репозиторий с `.env` = скомпрометированные ключи.
- **Детект:** GitHub secret scanning, gitleaks в pre-commit/CI.
- **Фикс:** `.gitignore`, pre-commit hooks, ротация ключей при утечке, приватность до проверки.

## Самопроверка

- [ ] Чем `git diff` отличается от `git diff --staged`?
- [ ] Почему `.gitignore` не помогает для уже закоммиченного файла?
- [ ] Что делает `git switch -c`?
- [ ] Как проверить историю на секреты?

## Дальше

[3.4 — C/ASM и реверс](l04-c-asm-reversing.md)
