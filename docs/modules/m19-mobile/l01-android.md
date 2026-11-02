# 19.1 — Android: APK, adb, Frida

> **M19 · Этап 3 · 6 ч · 🟡 · артефакт:** `labs/m19-mobile/l01-android/`

## Цель

Разобрать APK до кода и данных, подключиться к приложению через `adb` и Frida, понять, где хранятся секреты.

## Результат

- Разобранный APK (smali/dex/ресурсы).
- Работающая Frida-сессия.
- Список найденных артефактов.

## Теория

### 1. APK

APK — zip:

```text
AndroidManifest.xml
classes.dex (или несколько)
resources.arsc
res/
lib/<abi>/*.so
META-INF/
assets/
```

`AndroidManifest.xml` в бинарном XML; `apktool` декодирует.

### 2. Инструменты

| Инструмент | Назначение |
|---|---|
| `apktool` | декомпиляция ресурсов/smali |
| `jadx` | dex → Java |
| `dex2jar` | dex → jar |
| `frida` | динамическая инструментация |
| `objection` | Frida-обёртка |
| `adb` | устройство |

### 3. adb

```bash
adb devices
adb shell pm list packages | grep target
adb shell run-as com.target.app ls
adb pull /data/local/tmp/file
```

На эмуляторе с root — доступ к `/data/data/<pkg>`.

### 4. Frida

```bash
frida-ps -U
frida -U -f com.target.app -l hook.js --no-pause
```

Пример hook:

```javascript
Java.perform(function () {
  var Login = Java.use('com.target.app.Login');
  Login.checkPassword.implementation = function (p) {
    console.log('password: ' + p);
    return true;
  };
});
```

### 5. Где искать

- `SharedPreferences` (XML).
- SQLite.
- Файлы в `files/`, `cache/`.
- Логи (`logcat`).
- Строки в dex/so.
- Ключи в `strings.xml`/BuildConfig.

## Лаборатория

> Эмулятор Android (AVD) + учебное APK (DIVA/InsecureBankv2).

### 1. Установка

```bash
adb install diva.apk
adb shell pm list packages | grep diva
```

### 2. Декомпиляция

```bash
apktool d diva.apk -o diva_src
jadx -d diva_java diva.apk
```

Ожидаемо: smali и Java. Найдите `AndroidManifest.xml` и экспортируемые activity.

### 3. Секреты

```bash
grep -ri "password\|secret\|api_key" diva_java | head
strings lib/*/*.so | grep -i "http"
```

Ожидаемо: строки/ключи.

### 4. adb

```bash
adb shell run-as jakhar.aseem.diva ls -R /data/data/jakhar.aseem.diva
adb shell run-as jakhar.aseem.diva cat shared_prefs/*.xml
```

Ожидаемо: данные приложения.

### 5. Frida

```bash
frida-ps -U | grep diva
frida -U -f jakhar.aseem.diva -l hook.js --no-pause
```

Ожидаемо: лог вызовов.

### 6. Отчёт

| Артефакт | Где | Риск | Фикс |
|---|---|---|---|

## Атака и защита

- **Атака:** реверс + динамика.
- **Детект:** root/pinning/attestation, Play Integrity.
- **Фикс:** не хранить секреты, obfuscation, pinning, attestation.

## Самопроверка

- [ ] Чем smali отличается от Java?
- [ ] Что такое `run-as`?
- [ ] Как Frida обходит проверку?
- [ ] Где Android хранит токены?
- [ ] Почему obfuscation не защита?

## Дальше

[19.2 — Мобильный пентест](l02-mobile-pentest.md)
