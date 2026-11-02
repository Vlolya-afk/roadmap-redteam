# 1.3 — Пакеты, сборка из исходников, окружение

> **M01 · Этап 0 · 3 ч · 🟢 · артефакт:** `labs/m01-linux/l03-packages/`

## Цель

Понять, откуда берутся программы в Arch, как они собираются и почему `PATH`, `LD_PRELOAD` и права на каталоги — это векторы атаки.

## Результат

- Ставите, ищете и инспектируете пакеты через `pacman`.
- Собираете программу из исходников и объясняете роль `configure`, `make`, `ldconfig`.
- Понимаете, как работает подмена библиотеки и перехват `PATH`.

## Теория

- `pacman -S` ставит бинарный пакет; `-Ss` ищет, `-Qi` показывает метаданные, `-Ql` — файлы, `-Qo` — владельца файла.
- AUR — пользовательские рецепты `PKGBUILD`; они **не проверены** модераторами. AUR-хелперы (`paru`, `yay`) просто автоматизируют сборку.
- `./configure && make && sudo make install` кладёт файлы в `/usr/local` по умолчанию.
- `ldconfig` обновляет кэш динамических библиотек; `ldd` показывает зависимости.
- `PATH` ищется слева направо; каталог с правами записи в `PATH` = выполнение чужого кода.
- `LD_PRELOAD` подгружает библиотеку до остальных — мощный, но и опасный механизм.

## Лаборатория

### 1. Инспекция пакета

```bash
pacman -Ss nmap | head
pacman -Qi nmap | head -20
pacman -Ql nmap | head
pacman -Qo /usr/bin/nmap
```

Ожидаемо: версия, зависимости, список файлов, владелец — пакет `nmap`.

### 2. Сборка из исходников

```bash
mkdir -p ~/src && cd ~/src
curl -LO https://github.com/stedolan/jq/releases/download/jq-1.7.1/jq-1.7.1.tar.gz
tar xzf jq-1.7.1.tar.gz && cd jq-1.7.1
./configure --prefix="$HOME/.local"
make -j"$(nproc)"
make install
~/.local/bin/jq --version
```

Ожидаемо: `jq-1.7.1`. Объясните, почему без `--prefix` пришлось бы `sudo make install` и куда попали бы файлы.

### 3. PATH hijack (демо)

```bash
mkdir -p /tmp/evil
cat > /tmp/evil/ls <<'EOF'
#!/bin/bash
echo "[hijacked] $(date) $*" >> /tmp/evil/log
exec /usr/bin/ls "$@"
EOF
chmod +x /tmp/evil/ls
PATH=/tmp/evil:$PATH ls /tmp
cat /tmp/evil/log
```

Ожидаемо: `ls` работает как обычно, но в лог добавлена запись. Это демонстрация, а не «хакерский трюк»: в реальной системе такой каталог в `PATH` — инцидент.

### 4. LD_PRELOAD (демо)

```bash
cat > /tmp/evil.c <<'EOF'
#include <stdio.h>
__attribute__((constructor)) void init(void) {
    fprintf(stderr, "[preload] library loaded\n");
}
EOF
gcc -shared -fPIC -o /tmp/evil.so /tmp/evil.c
LD_PRELOAD=/tmp/evil.so /bin/true
```

Ожидаемо: `[preload] library loaded` в stderr.

## Атака и защита

- **Атака:** вредоносный `PKGBUILD` в AUR, typosquatting имени пакета, записываемый каталог в `PATH`, `LD_PRELOAD` через `.bashrc`.
- **Детект:** `pacman -Qkk` (целостность), мониторинг изменений `/usr/local`, алерты на новые файлы в `PATH`-каталогах.
- **Фикс:** читать `PKGBUILD` перед сборкой, `PATH` без `.` и world-writable каталогов, `noexec` на `/tmp` и `$HOME/tmp`, минимальные права.

## Самопроверка

- [ ] Чем AUR отличается от официальных репозиториев?
- [ ] Что делает `ldconfig` и когда его вызывать?
- [ ] Почему `.` в `PATH` — плохая идея?
- [ ] Как проверить, какой пакет владеет файлом?

## Дальше

[1.4 — Сеть в Linux и SSH](l04-networking-ssh.md)
