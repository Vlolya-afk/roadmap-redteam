# Установка Arch Linux с нуля

Два пути: **быстрый** (`archinstall`) и **ручной** (рекомендуется для первого раза — вы поймёте, из чего состоит система). Ниже — ручной, с пояснениями. Всё выполняется с установочного ISO.

> [!WARNING]
> **Куда ставить**
> Если Arch — ваша основная ОС, сначала сделайте бэкап. Если страшно — поставьте Arch **виртуальной машиной** в VMware (2 vCPU, 4 ГБ RAM, 40 ГБ диск, UEFI). Для лаб этого достаточно, но для комфортной работы с 2–3 ВМ лучше железо.

## 0. Подготовка

1. Скачайте ISO: <https://archlinux.org/download/>.
2. Проверьте подпись (обязательно, если качаете с зеркала):

```bash
gpg --keyserver keyserver.ubuntu.com --recv-keys 68B3537F39A313B3E574D06777193AEC4DB9C4EF
gpg --verify archlinux-2026.xx.xx-x86_64.iso.sig archlinux-2026.xx.xx-x86_64.iso
```

3. Запишите на USB (`dd` или Rufus/balenaEtcher), загрузитесь в **UEFI**-режиме.

## 1. Загрузка и сеть

```bash
# Убедиться, что загрузились в UEFI (выведет 64)
cat /sys/firmware/efi/fw_platform_size

# Wi-Fi (если нет кабеля)
iwctl
# station wlan0 scan
# station wlan0 connect "SSID"
# exit

# Проверка
ip a
ping -c 3 archlinux.org
timedatectl set-ntp true
```

## 2. Разметка диска

Определите диск:

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
```

Разметьте (`cfdisk` проще, чем `fdisk`):

```bash
cfdisk /dev/nvme0n1
```

Схема для UEFI + ext4:

| Раздел | Размер | Тип |
|---|---|---|
| `p1` | 1 ГБ | EFI System |
| `p2` | 8 ГБ | Linux swap |
| `p3` | остаток | Linux filesystem |

Форматирование и монтирование:

```bash
mkfs.fat -F 32 /dev/nvme0n1p1
mkswap /dev/nvme0n1p2
mkfs.ext4 /dev/nvme0n1p3

mount /dev/nvme0n1p3 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
swapon /dev/nvme0n1p2
```

### Вариант с LUKS (рекомендуется для ноутбука)

```bash
cryptsetup luksFormat /dev/nvme0n1p3
cryptsetup open /dev/nvme0n1p3 cryptroot
mkfs.ext4 /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
```

Тогда в `mkinitcpio.conf` нужно `HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)`, а в параметрах загрузки — `cryptdevice=UUID=<uuid>:cryptroot root=/dev/mapper/cryptroot`.

## 3. Базовая система

```bash
pacstrap -K /mnt \
  base base-devel linux linux-firmware intel-ucode \
  networkmanager sudo vim git man-db openssh nftables \
  zram-generator bash-completion less which
```

- AMD CPU: замените `intel-ucode` на `amd-ucode`.
- `-K` обновляет keyring в live-среде.

Генерация fstab:

```bash
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab   # проверьте, что разделы на месте
```

## 4. chroot и настройка

```bash
arch-chroot /mnt
```

### Время и локаль

```bash
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

# Локаль: интерфейс можно на русском, но вывод инструментов — на английском.
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
sed -i 's/^#ru_RU.UTF-8/ru_RU.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

> [!TIP]
> **Почему LANG=en_US.UTF-8**
> Русская локаль ломает парсинг вывода `nmap`, `ip`, `systemctl` в скриптах и меняет формат дат. Русский интерфейс можно включить в DE отдельно. Это не «нелюбовь к русскому», а практика: инструменты ИБ ожидают английский вывод.

### Имя хоста

```bash
echo "arch-lab" > /etc/hostname
cat > /etc/hosts <<'EOF'
127.0.0.1   localhost
::1         localhost
127.0.1.1   arch-lab.localdomain arch-lab
EOF
```

### Пользователь и sudo

```bash
passwd                      # пароль root
useradd -m -G wheel -s /bin/bash vlad
passwd vlad
EDITOR=vim visudo           # раскомментировать: %wheel ALL=(ALL:ALL) ALL
```

### Загрузчик systemd-boot

```bash
bootctl install

cat > /boot/loader/loader.conf <<'EOF'
default arch.conf
timeout 3
editor no
EOF

ROOT_UUID=$(blkid -s UUID -o value /dev/nvme0n1p3)
cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=$ROOT_UUID rw
EOF

mkinitcpio -P
```

Если используется LUKS — добавьте `cryptdevice=...` в `options` и hook `encrypt`.

### Сеть и SSH

```bash
systemctl enable NetworkManager
systemctl enable sshd        # если нужен удалённый доступ
exit
```

### Завершение

```bash
umount -R /mnt
swapoff /dev/nvme0n1p2
reboot
```

Выньте ISO. Если система не грузится — проверьте `efibootmgr -v` и порядок загрузки в BIOS.

## 5. Первый вход и базовые пакеты

```bash
sudo pacman -Syu

sudo pacman -S --needed \
  neovim tmux htop btop tree jq ripgrep fd fzf unzip p7zip \
  python python-pip nodejs npm go rustup \
  docker docker-compose podman \
  nmap openbsd-netcat socat tcpdump whois bind traceroute mtr \
  gdb strace ltrace binutils file \
  firefox chromium keepassxc obsidian \
  wireshark-qt

sudo usermod -aG docker,wireshark "$USER"
```

AUR-хелпер (нужен для VMware, Burp и т.п.):

```bash
git clone https://aur.archlinux.org/paru.git
cd paru && makepkg -si
```

## 6. Оптимизация под 16 ГБ и ВМ

```bash
# zram: сжатый swap в памяти
sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service

# swappiness: для zram агрессивнее выгружаем анонимные страницы
echo 'vm.swappiness = 100' | sudo tee /etc/sysctl.d/99-lab.conf
echo 'vm.vfs_cache_pressure = 50' | sudo tee -a /etc/sysctl.d/99-lab.conf
sudo sysctl --system

# Проверка
zramctl
free -h
```

## 7. Гостевая ВМ VMware

Если Arch стоит внутри VMware:

```bash
sudo pacman -S open-vm-tools
sudo systemctl enable --now vmtoolsd
vmware-toolbox-cmd -v
```

Для общих папок: `vmhgfs-fuse` (пакет `open-vm-tools`), монтирование через `/etc/fstab` или вручную.

## 8. Минимальный firewall

```bash
sudo tee /etc/nftables.conf >/dev/null <<'EOF'
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
  chain input {
    type filter hook input priority 0; policy drop;
    ct state established,related accept
    iif "lo" accept
    ip protocol icmp accept
    ip6 nexthdr ipv6-icmp accept
    tcp dport 22 accept comment "SSH — уберите, если не нужен"
  }
  chain forward {
    type filter hook forward priority 0; policy accept;
    # accept нужен, чтобы VMnet8/NAT и контейнеры работали.
    # Для параноидального режима: policy drop + разрешить vmnet8.
  }
  chain output { type filter hook output priority 0; policy accept; }
}
EOF

sudo systemctl enable --now nftables
sudo nft list ruleset
```

> [!WARNING]
> **Проверьте сеть ВМ**
> Если после включения nftables виртуальные машины потеряли интернет — верните `forward` в `accept` или добавьте правила для интерфейса `vmnet8`. Сначала поднимите лабораторию, потом ужесточайте firewall.

## 9. Быстрый путь: archinstall

Для второй/третьей ВМ, когда лень:

```bash
archinstall
```

Выберите: диск → btrfs/ext4 → профиль `minimal` → ядро `linux` → сеть `NetworkManager` → пользователь в `wheel` → загрузчик systemd-boot. После установки всё равно пройдите шаги 5–8.

## 10. Типовые проблемы

| Симптом | Причина | Решение |
|---|---|---|
| `pacstrap` падает на ключах | устаревший keyring | `pacman-key --init && pacman-key --populate archlinux` |
| Система не грузится | нет записи UEFI | `efibootmgr -v`, `bootctl install` заново |
| Нет сети после сна/снапшота | NetworkManager не поднял линк | `systemctl restart NetworkManager` |
| VMware-модули не собираются после обновления ядра | нет headers | `sudo pacman -S linux-headers`, переустановить `vmware-workstation` |
| Часы уехали после снапшота | рассинхрон | `sudo hwclock --hctosys`, в ВМ включить timesync |
| Русские буквы в TTY — кракозябры | нет шрифта | `sudo pacman -S terminus-font`, `setfont ter-v32n` |

## Чек-лист

- [ ] Загрузка UEFI, `fw_platform_size = 64`
- [ ] Разделы смонтированы, fstab корректен
- [ ] Пользователь в `wheel`, sudo работает
- [ ] `ping archlinux.org` и `pacman -Syu` работают
- [ ] `systemctl status NetworkManager` — active
- [ ] zram включён, `free -h` показывает swap в RAM
- [ ] Снапшот/бэкап рабочей системы сделан
