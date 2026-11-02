# 4.3 — Криптография: хэши, шифры, KDF

> **M04 · Этап 0 · 4 ч · 🟢 · артефакт:** `labs/m04-web-crypto/l03-crypto/`

## Цель

Перестать путать кодирование, хэширование и шифрование — и увидеть типовые ошибки, которые превращают криптографию в декорацию.

## Результат

- Объясняете, где какой примитив нужен.
- Ломаете слабый хэш по словарю и понимаете, почему это возможно.
- Видите разницу между ECB и GCM на примере.

## Теория

- Кодирование (base64, hex) — не защита, а представление.
- Хэш: односторонний, фиксированная длина, лавинный эффект. MD5/SHA-1 — сломаны для коллизий.
- Соль делает радужные таблицы бесполезными; pepper хранится отдельно от БД.
- KDF (PBKDF2, bcrypt, scrypt, Argon2) намеренно медленный — для паролей.
- Симметрика: AES-CBC требует IV и padding, AES-GCM даёт и шифрование, и целостность.
- Nonce в GCM нельзя повторять: повтор = раскрытие и подделка.
- Асимметрика: RSA/ECDSA для подписи и обмена, не для больших данных.

## Лаборатория

### 1. Кодирование vs хэш

```bash
echo -n "admin:password" | base64
echo -n "admin:password" | base64 -d
echo -n "password" | md5sum
echo -n "password" | sha256sum
echo -n "password2" | sha256sum
```

Ожидаемо: base64 обратим; хэши разной длины; `password` и `password2` дают совершенно разные хэши.

### 2. Сломать слабый хэш

```bash
printf 'password123\nletmein\nqwerty\n' > /tmp/words.txt
echo -n "letmein" | md5sum | awk '{print $1}' > /tmp/hash.txt
hashcat -m 0 -a 0 /tmp/hash.txt /tmp/words.txt --potfile-disable
```

Ожидаемо: `letmein` найден за секунды. Если hashcat не заводится (нет OpenCL), используйте `john --format=raw-md5 /tmp/hash.txt --wordlist=/tmp/words.txt`.

Вывод: быстрый хэш без соли + слабый пароль = мгновенный подбор.

### 3. ECB виден по паттерну

```bash
python3 - <<'PY'
open('/tmp/ecb.bin','wb').write(b'A'*16*1000)
PY
KEY=000102030405060708090a0b0c0d0e0f
openssl enc -aes-128-ecb -K $KEY -nosalt -in /tmp/ecb.bin -out /tmp/ecb.out
xxd /tmp/ecb.out | head -4
```

Ожидаемо: одинаковые 16-байтовые блоки. В CBC/GCM такого паттерна нет. Это причина, почему ECB запрещён.

### 4. GCM и nonce

```bash
KEY=000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f
IV=101112131415161718191a1b
echo -n "secret message" | openssl enc -aes-256-gcm -K $KEY -iv $IV -nosalt -out /tmp/gcm.bin
openssl enc -d -aes-256-gcm -K $KEY -iv $IV -nosalt -in /tmp/gcm.bin
```

Ожидаемо: `secret message`. Повторите с тем же IV для другого сообщения — и объясните, почему это катастрофа (повтор nonce в GCM ломает и конфиденциальность, и целостность).

### 5. Пароли правильно

```bash
python3 - <<'PY'
import hashlib, os, time
salt = os.urandom(16)
t = time.time()
hashlib.pbkdf2_hmac('sha256', b'password123', salt, 600_000)
print(f"pbkdf2 600k: {time.time()-t:.2f}s")
PY
```

Ожидаемо: десятые доли секунды на проверку — и это только один пароль. Argon2id предпочтительнее.

## Атака и защита

- **Атака:** offline-подбор быстрых хэшей, rainbow tables, ECB-паттерны, nonce reuse, padding oracle, слабый `random`.
- **Детект:** массовые неудачные логины, аномальная нагрузка на CPU при проверке паролей.
- **Фикс:** Argon2id/bcrypt с солью, AES-GCM с уникальным nonce, `secrets` вместо `random`, ротация ключей, HSM/KMS.

## Самопроверка

- [ ] Чем хэш отличается от шифрования?
- [ ] Зачем соль, если хэш и так необратим?
- [ ] Почему ECB выдаёт структуру данных?
- [ ] Что произойдёт при повторном nonce в GCM?

## Дальше

[4.4 — TLS и PKI](l04-tls-pki.md)
