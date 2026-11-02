# Red Team Roadmap — от нуля до Senior

> Личный, проверяемый на практике трек в кибербезопасность с упором на red team.
> Каждый модуль = теория → лаборатория на своей ВМ → артефакт в портфолио → контрольная из 3 задач.

[![Deploy docs](https://github.com/Vlolya-afk/roadmap-redteam/actions/workflows/deploy.yml/badge.svg)](https://github.com/Vlolya-afk/roadmap-redteam/actions/workflows/deploy.yml)
[![License: MIT](https://img.shields.io/badge/code-MIT-blue.svg)](LICENSE)
[![Docs: CC BY-SA 4.0](https://img.shields.io/badge/docs-CC%20BY--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)

---

## Что это

Это не «список курсов», а **рабочий учебный план и лабораторный практикум**. Репозиторий устроен так, чтобы его можно было:

- проходить последовательно с нуля (уровень 0 — базовый Linux и сети не требуются);
- использовать как портфолио: каждая лаба оставляет артефакт (writeup, скрипт, отчёт, детект, PoC);
- показать работодателю: сайт на GitHub Pages + история коммитов + раздел с отчётами и контрольными.

**Честно о сроках.** «Senior за 6 месяцев с нуля» не существует. Senior — это ~4–6 лет практики, самостоятельные операции, умение вести заказчика и принимать решения при неполных данных. Здесь трек разбит на этапы:

| Этап | Что даёт | Реалистичный срок при 10–12 ч/нед |
|---|---|---|
| 0. База | Linux, сети, код, web, Windows/AD | 6–8 месяцев |
| 1. Атакующая база | Recon, сеть, web, эксплуатация, privesc | 6–8 месяцев |
| 2. Red team core | AD-атаки, evasion, C2, инфраструктура, отчётность | 8–12 месяцев |
| 3. Senior-широта | Cloud/K8s, detection, hardware/RF, mobile, research | 6–10 месяцев |

Этапы 0–2 дают уровень, с которым берут на junior/middle red team и с которым можно сдавать OSCP/CRTO. Этап 3 и реальная работа — то, что превращает middle в senior. В `docs/roadmap.md` описаны критерии выхода и что именно считается «senior-артефактом».

## Быстрый старт

```bash
# 1. Клонировать
git clone https://github.com/Vlolya-afk/roadmap-redteam.git
cd roadmap-redteam

# 2. Поставить зависимости сайта (Arch)
sudo pacman -S --needed python python-pip
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# 3. Локальный просмотр
mkdocs serve
# http://127.0.0.1:8000

# 4. Публикация
mkdocs gh-deploy --force
```

Публикация на GitHub Pages настраивается один раз: репозиторий `roadmap-redteam` уже создан, включите **Settings → Pages → Source: gh-pages branch** и сделайте push в `main`. Дальше сайт обновляется автоматически через GitHub Actions. Подробнее — в [docs/how-to-use.md](docs/how-to-use.md).

## Структура

```
redteam-roadmap/
├─ docs/                     # теория, лабы, контрольные (MkDocs)
│  ├─ roadmap.md             # карта этапов и критерии senior
│  ├─ progress.md            # чек-лист прогресса
│  ├─ lab/                   # установка Arch, топология VMware, цели, OPSEC
│  ├─ modules/mXX-*/         # модуль: index.md + lNN-*.md + exam.md
│  ├─ exams/                 # сводка всех контрольных и рубрики
│  └─ capstone/              # финальная операция
├─ labs/                     # скрипты, compose-файлы, конфиги, стартеры
├─ scripts/                  # bootstrap Arch, генератор урока, проверка ссылок
├─ assets/                   # схемы, скриншоты, pcap (крупное — в Releases)
├─ mkdocs.yml
└─ .github/workflows/        # автодеплой сайта
```

## Модули

| # | Модуль | Этап | Уроков | Контрольная |
|---|---|---|---|---|
| M00 | Старт, лаборатория, правила игры | 0 | 3 | ✅ |
| M01 | Linux и командная строка | 0 | 5 | ✅ |
| M02 | Сети и протоколы | 0 | 5 | ✅ |
| M03 | Python, Bash, Git | 0 | 4 | ✅ |
| M04 | Web, HTTP, криптография | 0 | 5 | ✅ |
| M05 | Windows и Active Directory: база | 0 | 5 | ✅ |
| M06 | Recon и OSINT | 1 | 4 | ✅ |
| M07 | Сетевые атаки и MITM | 1 | 5 | ✅ |
| M08 | Web/API-эксплуатация | 1 | 6 | ✅ |
| M09 | Сканирование, CVE, эксплуатация | 1 | 4 | ✅ |
| M10 | Повышение привилегий | 1 | 5 | ✅ |
| M11 | AD-атаки | 2 | 6 | ✅ |
| M12 | Обход защиты Windows | 2 | 5 | ✅ |
| M13 | Initial access, фишинг, C2 | 2 | 5 | ✅ |
| M14 | Pivoting, туннели, инфраструктура | 2 | 4 | ✅ |
| M15 | Red team операции и отчётность | 2 | 4 | ✅ |
| M16 | Cloud и Kubernetes | 3 | 4 | ✅ |
| M17 | Detection engineering / purple | 3 | 4 | ✅ |
| M18 | Hardware, RF, Wi-Fi, OT | 3 | 4 | ✅ |
| M19 | Mobile и реверс | 3 | 3 | ✅ |
| M20 | Research, tooling, карьера | 3 | 4 | ✅ |

Всего: **94 занятия**, **21 контрольная** (по 3 задачи: 🟢 база / 🟡 средний / 🔴 продвинутый) и финальный capstone.

## Как проходить

1. Читаете `docs/modules/mXX/index.md` — цель модуля и критерии готовности.
2. Проходите урок: теория → лаборатория → отвечаете на самопроверку.
3. Кладёте артефакт в `labs/mXX-.../writeup.md` (шаблон внутри).
4. В конце модуля решаете `exam.md`: минимум зелёная задача, для зачёта — жёлтая, для портфолио — красная.
5. Отмечаете прогресс в `docs/progress.md` и делаете коммит `feat(mXX): ...`.

Правило трека: **не более 30% времени на видео/чтение, не менее 70% — на руки**. Если лаба не воспроизводится с нуля по вашему же writeup — она не засчитана.

## Безопасность и закон

Все атаки в этом репозитории выполняются **только против собственных виртуальных машин в изолированной лаборатории**. Реальные цели, чужие сети, «проверка сайта друга» и т.п. — вне рамок трека и во многих юрисдикциях являются преступлением (в РФ — ст. 272, 273, 274 УК РФ; в США — CFAA и т.д.).

Перед началом прочитайте [docs/ethics-legal.md](docs/ethics-legal.md) и [docs/lab/opsec.md](docs/lab/opsec.md). Правила простые: свой стенд, свой scope, письменное разрешение, ответственное раскрытие.

## Лицензия

- Код и скрипты — MIT (`LICENSE`).
- Тексты, лабы и отчёты — CC BY-SA 4.0. Можно форкать и адаптировать, но с указанием источника и той же лицензией.

## English summary

A self-paced, lab-first roadmap from zero to senior-level red teaming. 94 lessons across 21 modules (Linux, networking, scripting, web, Windows/AD, recon, exploitation, privesc, AD attacks, evasion, C2, cloud/K8s, detection engineering, hardware/RF, mobile, research), each with a hands-on lab, expected results, and a 3-tier exam. Built for a 16 GB RAM host with VMware Workstation, with `minimal` and `full` lab profiles. Docs are in Russian; all tooling, commands and terminology stay in English.

> ⚠️ For educational use only. Attack only your own isolated lab VMs. Unauthorized access to systems is illegal.
