# 3.4 — C, ассемблер и чтение чужого кода

> **M03 · Этап 0 · 5 ч · 🟡 · артефакт:** `labs/m03-scripting/l04-reversing/`

## Цель

Понять, как программа превращается в бинарник, и научиться находить в ней ключевую логику без исходников. Это вход в реверс, эксплуатацию и анализ malware.

## Результат

- Компилируете C, читаете ELF и дизассемблер.
- Находите пароль в crackme через `strings`, `objdump`, `gdb`.
- Объясняете, что такое стек, canary, NX и ASLR.

## Теория

- Компиляция: препроцессор → компилятор → ассемблер → линкер.
- ELF: `.text` (код), `.data` (инициализированные данные), `.bss` (нули), `.rodata` (константы), stack/heap в рантайме.
- Регистры x86-64: `rax` (результат), `rdi/rsi/rdx` (аргументы), `rsp` (стек), `rbp` (кадр), `rip` (инструкция).
- SysV: первые 6 аргументов — в регистрах, остальные — в стеке.
- `gdb`: `break`, `run`, `disassemble`, `info registers`, `x/s`, `ni`, `si`.
- Защиты: stack canary, NX, ASLR, PIE, RELRO, Fortify.

## Лаборатория

### 1. Собрать и посмотреть

```bash
cat > crackme.c <<'EOF'
#include <stdio.h>
#include <string.h>
int main(void) {
    char buf[32];
    printf("password: ");
    if (!fgets(buf, sizeof(buf), stdin)) return 1;
    buf[strcspn(buf, "\n")] = 0;
    if (strcmp(buf, "s3cr3t_lab") == 0) puts("access granted");
    else puts("denied");
    return 0;
}
EOF

gcc -O0 -g -o crackme crackme.c
file crackme
readelf -h crackme | head
strings -a crackme | grep -i -E 's3cr3t|access|denied'
```

Ожидаемо: `ELF 64-bit`, а в `strings` — `s3cr3t_lab`, `access granted`. Первый вывод: не всё защищено, строки видны.

### 2. Дизассемблер

```bash
objdump -d -M intel crackme | sed -n '/<main>:/,/^$/p'
```

Ожидаемо: вызовы `printf`, `fgets`, `strcmp`, `puts`. Найдите, где загружается адрес строки-пароля (`lea rdi,[rip+...]`) и где ветвление (`test eax,eax; jne`).

### 3. GDB

```bash
gdb -q ./crackme
```
```
(gdb) break strcmp
(gdb) run
password: test
(gdb) info registers rdi rsi
(gdb) x/s $rdi
(gdb) x/s $rsi
(gdb) continue
```

Ожидаемо: `$rdi` — ваш ввод, `$rsi` — `s3cr3t_lab`. Пароль найден без исходников.

### 4. Stripped-бинарь

```bash
gcc -O2 -s -o crackme_stripped crackme.c
file crackme_stripped
strings -a crackme_stripped | head
objdump -d -M intel crackme_stripped | grep -A5 -B5 'strcmp'
```

Ожидаемо: символов меньше, но `strcmp` и строка остаются. Усложнение: `-static`, обфускация, шифрование строк — тема M12/M20.

### 5. Переполнение буфера (наблюдение)

```bash
cat > vuln.c <<'EOF'
#include <stdio.h>
void vuln(void) { char buf[16]; gets(buf); puts(buf); }
int main(void) { vuln(); return 0; }
EOF
gcc -fno-stack-protector -z execstack -no-pie -o vuln vuln.c
python3 -c "print('A'*40)" | ./vuln; echo "exit=$?"
```

Ожидаемо: segfault (`exit=139`). В gdb:

```
(gdb) run < <(python3 -c "print('A'*40)")
(gdb) info registers rip rsp
```

`rip` = `0x4141414141414141` — вы перезаписали адрес возврата. Эксплуатировать не нужно: поймите механизм.

## Атака и защита

- **Атака:** переполнение стека → контроль `rip`; ret2libc/ROP при NX; утечка адресов при ASLR.
- **Детект:** падения процесса, аномальные `execve`, WAF/EDR на exploit-паттерны.
- **Фикс:** безопасные функции (`fgets`), canary, NX, PIE, ASLR, компиляция с `-D_FORTIFY_SOURCE=2`.

## Самопроверка

- [ ] Что лежит в `.rodata` и почему пароль виден в `strings`?
- [ ] Зачем `strcmp` получает два указателя в `rdi` и `rsi`?
- [ ] Что перезаписывает переполнение, чтобы изменить `rip`?
- [ ] Как canary мешает классическому overflow?

## Дальше

[Контрольная M03](exam.md)
