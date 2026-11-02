# 19.3 — iOS кратко и отчёт

> **M19 · Этап 3 · 4 ч · 🟡 · артефакт:** `labs/m19-mobile/l03-ios/`

## Цель

Понять отличия iOS-пентеста и собрать итоговый отчёт по мобильному приложению.

## Результат

- Понимание IPA, jailbreak, Frida на iOS.
- Чеклист iOS-тестов.
- Итоговый отчёт по MASTG.

## Теория

### 1. IPA

Zip с `Payload/App.app`:

```text
Info.plist
App binary (Mach-O)
Frameworks/
PlugIns/
Assets.car
```

`plutil -p Info.plist`, `class-dump`, `otool -L`, `strings`.

### 2. Ограничения

- Нет root по умолчанию.
- Jailbreak (palera1n/checkra1n/dopamine) — только на своём устройстве.
- Подпись приложений.
- Keychain, Secure Enclave.
- Jailbreak detection, ptrace, anti-debug.

### 3. Инструменты

| Инструмент | Назначение |
|---|---|
| `frida` | динамика (jailbreak/device) |
| `objection` | обёртка |
| `class-dump` | классы |
| `Hopper/Ghidra` | реверс |
| `Burp/mitmproxy` | сеть |
| `ios-deploy` | установка |

### 4. Что проверять

- ATS (App Transport Security).
- Keychain access.
- Биометрия/LocalAuthentication.
- Jailbreak detection.
- Pinning.
- WebView.
- Логи.
- Данные в `Documents/`, `Library/`.

### 5. Отчёт

Структура: scope, окружение, методология, findings, риски, рекомендации, приложения. Для мобильных — MASTG ID.

## Лаборатория

> Своё устройство или симулятор. Без jailbreak — ограниченный набор тестов.

### 1. IPA

```bash
unzip app.ipa -d app
plutil -p app/Payload/App.app/Info.plist | head -40
strings app/Payload/App.app/App | grep -i "http\|token"
```

### 2. ATS

Проверьте `NSAppTransportSecurity` в Info.plist. Ожидаемо: `NSAllowsArbitraryLoads` — риск.

### 3. Сеть

Настройте прокси, установите CA. Проверьте, проходит ли трафик.

### 4. Отчёт

Соберите findings из 19.1–19.2 + iOS.

| ID | Платформа | Тест | Риск | Фикс |
|---|---|---|---|---|

### 5. Ревью

Проверьте: доказательства, приоритеты, отсутствие секретов.

## Атака и защита

- **Атака:** реверс, proxy, Frida.
- **Детект:** jailbreak detection, attestation, pinning.
- **Фикс:** ATS, Keychain, биометрия, обфускация, обновления.

## Самопроверка

- [ ] Чем IPA отличается от APK?
- [ ] Почему jailbreak нужен для динамики?
- [ ] Что такое ATS?
- [ ] Где iOS хранит секреты?
- [ ] Что обязательно в отчёте?

## Дальше

[Контрольная M19](exam.md)
