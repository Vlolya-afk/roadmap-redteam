#!/usr/bin/env bash
# new-lesson.sh — создать файл урока из шаблона.
# usage: ./scripts/new-lesson.sh m05-windows-ad l06-tokens
set -euo pipefail

MODULE="${1:-}"
LESSON="${2:-}"

if [[ -z "$MODULE" || -z "$LESSON" ]]; then
  echo "usage: $0 <module-dir> <lesson-file-without-.md>" >&2
  echo "example: $0 m05-windows-ad l06-tokens" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="$ROOT_DIR/docs/modules/$MODULE"
FILE="$DIR/$LESSON.md"

if [[ ! -d "$DIR" ]]; then
  echo "Нет такого модуля: $DIR" >&2
  exit 1
fi

if [[ -e "$FILE" ]]; then
  echo "Файл уже существует: $FILE" >&2
  exit 1
fi

NUM="$(echo "$LESSON" | sed -E 's/^l([0-9]+).*/\1/')"
TITLE="$(echo "$LESSON" | sed -E 's/^l[0-9]+-//; s/-/ /g')"
MODNUM="${MODULE#m}"; MODNUM="${MODNUM%%-*}"

cat > "$FILE" <<EOF
# $MODNUM.$NUM — $TITLE

> **Модуль:** $MODULE · **Этап:** _ · **Время:** _ ч · **Уровень:** 🟢 база
> **Артефакты:** \`labs/$MODULE/$LESSON/\`

## Цель

_Одно-два предложения._

## Результат

К концу занятия у вас должно получиться:

- ...
- ...

## Теория-минимум

- ...
- ...

## Лаборатория

### 0. Подготовка

\`\`\`bash
# снапшот, проверка сети
\`\`\`

### 1. Шаг

\`\`\`bash
command
\`\`\`

**Что должно получиться**

\`\`\`
expected output
\`\`\`

**Почему это работает**

_Механизм._

## Атака и защита

- **Как это выглядит в атаке:** ...
- **Как детектится:** ...
- **Как защититься:** ...

## Самопроверка

- [ ] Могу объяснить ...
- [ ] Могу повторить без шпаргалки ...
- [ ] Знаю, как это ловится ...

## Артефакт

\`labs/$MODULE/$LESSON/writeup.md\` по шаблону \`labs/_template/writeup.md\`.

## Дальше

- [Следующий урок](...)
EOF

echo "Создан: $FILE"
