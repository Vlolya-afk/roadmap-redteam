# Лаборатория: обзор

Всё в треке делается на **своём** стенде. Этот раздел — про то, как собрать его с нуля на Arch Linux и не утонуть в 16 ГБ RAM.

## Компоненты

| Компонент | Роль | Где взять |
|---|---|---|
| Arch Linux (хост или ВМ) | Рабочая станция атакующего | [Установка](arch-install.md) |
| VMware Workstation Pro | Гипервизор и виртуальные сети | AUR `vmware-workstation`, бесплатно для личного использования |
| Windows Server 2022/2025 Evaluation | Контроллер домена | Microsoft Evaluation Center |
| Windows 11 Enterprise Evaluation | Рабочая станция домена | Microsoft Evaluation Center |
| Ubuntu Server LTS / Debian | Linux-цель | ubuntu.com / debian.org |
| Docker/Podman | Лёгкие web-цели | `pacman -S docker` |
| Уязвимые приложения | DVWA, Juice Shop, WebGoat | [Цели](targets.md) |

## Сети

```
                    ┌─────────────────────────────┐
                    │        Хост (Arch)          │
                    │  16 ГБ RAM, VMware WS Pro   │
                    └──────────────┬──────────────┘
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        │ VMnet8 (NAT)             │ VMnet1 (host-only)       │ VMnet2 (host-only)
        │ 192.168.150.0/24         │ 192.168.56.0/24          │ 10.10.10.0/24
        │ только для обновлений    │ management / атака       │ «корпоративная» сеть
        │                          │                          │
   [интернет]               attacker .10                 DC01 .10
                            kali .11 (опц.)              WS01 .20
                                                         LNX01 .30
                                                         attacker .50 (2-й NIC)
```

**Правило:** bridged-адаптер не используем никогда. Атакующая ВМ получает интернет через NAT, а цели — только host-only. Если хост — Windows, интернет для ВМ идёт через VMnet8, но цели в нём не нуждаются.

## Бюджет 16 ГБ

| ВМ | vCPU | RAM (minimal) | RAM (full) | Диск |
|---|---:|---:|---:|---:|
| Arch attacker | 2 | 3 ГБ | 4 ГБ | 40 ГБ |
| DC01 (Server Core) | 2 | 3 ГБ | 4 ГБ | 40 ГБ |
| WS01 (Windows 11) | 2 | 3 ГБ | 4 ГБ | 50 ГБ |
| LNX01 (Ubuntu Server) | 1 | 1 ГБ | 2 ГБ | 20 ГБ |
| **Итого** | | **10 ГБ** | **14 ГБ** | |

Хосту нужно 4–6 ГБ. Поэтому в минимальном профиле одновременно держим **не более трёх** ВМ: attacker + DC + одна цель. Остальные — включаем по очереди.

Советы:
- **Server Core** для DC экономит ~1 ГБ и убирает GUI-шум.
- **Linked clones** экономят диск, но не RAM.
- Отключите Windows Update, Cortana, индексацию и Defender real-time **только в тех лабах, где он не является объектом исследования**. Для M12 Defender включён.
- На хосте: `zram-generator`, `vm.swappiness=10`, никакого тяжёлого DE во время лабы.
- Снапшоты делайте **до** атаки. Откат дешевле, чем пересборка домена.

## Порядок сборки

1. [Установить Arch](arch-install.md) (хост или ВМ).
2. Настроить [VMware и сети](vmware-topology.md).
3. Поднять цели из [targets.md](targets.md).
4. Пройти [M00](../modules/m00-start/index.md) — там проверка стенда и снапшоты.
5. Прочитать [OPSEC](opsec.md) — как не вынести лабораторию в интернет.

## Если VMware не заводится на Arch

Альтернативы, все бесплатные:

```bash
# KVM/QEMU + virt-manager
sudo pacman -S qemu-full virt-manager libvirt edk2-ovmf dnsmasq iptables-nft
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $USER

# VirtualBox (проще, но медленнее сеть)
sudo pacman -S virtualbox virtualbox-host-modules-arch
```

В KVM сети создаются через `virsh net-define` (host-only) — принцип тот же: изолированная подсеть, без моста в LAN.
