# 0.2 — Установка Arch Linux и восстановление загрузки

> **M00 · Этап 0 · 4 ч · 🟢 база · артефакт:** `labs/m00-start/l02-arch/`

## Цель

Поставить Arch вручную, понять его устройство и научиться чинить систему, которая не грузится. Это база для всего трека: дальше вы будете ломать и восстанавливать Linux постоянно.

## Результат

- Работающая Arch (хост или ВМ) с UEFI, systemd-boot, NetworkManager, sudo и zram.
- Понимание, что делает каждый шаг `pacstrap`/`chroot`.
- Умение зайти с live-ISO, смонтировать систему, сделать `arch-chroot` и починить загрузчик.

## Теория

- Установка Arch = разметка → форматирование → `pacstrap` → `chroot` → конфиги → загрузчик.
- `chroot` меняет корень, но не монтирует `/proc`, `/sys`, `/dev` — для некоторых операций их нужно пробросить.
- systemd-boot читает `/boot/loader/entries/*.conf`; ошибка в UUID = незагружаемая система.
- `mkinitcpio` собирает initramfs; после смены ядра/хуков его нужно пересобрать.
- Локаль `en_US.UTF-8` — не эстетика, а совместимость с парсингом вывода инструментов.
- zram даёт сжатый swap в RAM, что критично на 16 ГБ с виртуалками.

## Лаборатория

### 0. Подготовка

Следуйте [инструкции по установке](../../lab/arch-install.md) до раздела 5 включительно. Если ставите в VMware — 2 vCPU, 4 ГБ RAM, 40 ГБ, UEFI.

### 1. Проверить установку

```bash
bootctl status
systemctl --failed
ip -brief addr
free -h
zramctl
```

Ожидаемо:

```
System:
      Firmware: UEFI 2.70
     Boot Loader: systemd-boot ...
0 loaded units listed.
```

`zramctl` показывает устройство `/dev/zram0` с алгоритмом `zstd`. Если пусто — проверьте `/etc/systemd/zram-generator.conf` и `systemctl status systemd-zram-setup@zram0`.

### 2. Сломать загрузчик (намеренно)

В ВМ, не на железе:

```bash
sudo mv /boot/loader/entries/arch.conf /boot/loader/entries/arch.conf.bak
sudo reboot
```

Ожидаемо: система не грузится, появляется shell systemd-boot или меню без записи.

### 3. Починить с live-ISO

Загрузитесь с ISO, найдите разделы:

```bash
lsblk -f
mount /dev/nvme0n1p3 /mnt
mount /dev/nvme0n1p1 /mnt/boot
arch-chroot /mnt
```

Внутри:

```bash
mv /boot/loader/entries/arch.conf.bak /boot/loader/entries/arch.conf
bootctl install
mkinitcpio -P
exit
umount -R /mnt
reboot
```

Ожидаемо: система снова грузится. Если нет — проверьте UUID:

```bash
blkid -s UUID -o value /dev/nvme0n1p3
grep options /boot/loader/entries/arch.conf
```

UUID в конфиге должен совпадать.

### 4. Снапшот

Выключите ВМ и сделайте снапшот `clean-install`. На железной системе — `timeshift`/`snapper` или хотя бы `tar` конфигов в `~/backup`.

## Атака и защита

- **Атака:** физический доступ + незашифрованный диск = замена `initramfs` или `authorized_keys` и постоянный доступ. Отсюда важность LUKS и пароля на загрузчике.
- **Детект:** изменение файлов в `/boot`, новые UEFI-записи (`efibootmgr`), правка `sudoers`.
- **Фикс:** LUKS, пароль на bootloader, Secure Boot (сложнее с Arch), контроль целостности `/boot`, бэкап.

## Самопроверка

- [ ] Что произойдёт, если в `arch.conf` указать неверный UUID?
- [ ] Зачем нужен `mkinitcpio -P` после обновления ядра?
- [ ] Где хранятся записи загрузчика systemd-boot?
- [ ] Как проверить, что zram реально работает?

## Дальше

[1.3 — Лаборатория на VMware](l03-vmware-lab.md)
