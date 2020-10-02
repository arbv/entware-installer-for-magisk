# Description

This repository contains a [Magisk](https://magiskmanager.com/) module that can be used to install and run [Entware](https://entware.net/), the ultimate repository for embedded devices, on a rooted Android-powered device. The installer is *unofficial* - it is not affiliated with the Entware project directly, but in the process of installation it downloads and uses the latest version of the *official* installer.

Entware, when being installed using this module, actually makes it possible for the [available software packages](https://bin.entware.net/armv7sf-k3.2/Packages.html) to extend the functionality of the Android-powered device and turn it into a more or less real Linux-powered system with a full-featured package manager. Nevertheless, the installation remains *systemless*: it does not make any modifications to the "system" partition and is fully reversible.

The module was announced in [this post](https://chaoticlab.io/posts/entware-installer-for-magisk/).

**This module should be compatible with most devices running Android 8 and below. For devices running Android 9 and newer manual intervention may be required before the installation. More on this below.**

*If you find this project useful, you may want to support the author and make a small [donation](https://chaoticlab.io/donate/).*

# Disclaimer

The code in this repository comes with good intentions in mind but *with no warranty whatsoever*. Android-powered devices are numerous and I cannot physically guarantee that the module is going to work properly on all of them. I embodied numerous sanity checks into the code, and the changes made by the scripts are not destructive by nature. Nevertheless, anything happens. If during your quest you have bricked your device or lost any data and you think that it was caused by my code - sorry, I cannot help you. You may try to open an issue so that I can try to do something to prevent it from happening in the future (if it is in my powers).

# Compatibility

Installing this module on any device should be safe: if the device is not compatible, the installation fails. If it fails, then remove the module from within the "Magisk Manager."

Regarding this module, there are two kinds of Android devices (you can read more on the topic [here](https://topjohnwu.github.io/Magisk/boot.html)):

1. The devices, whose root file system (`/`) is a RAM-drive (`rootfs`) or, in some cases, whose root file system appears as a RAM-drive because of Magisk. The list includes most of the devices running Android 8 and older, and some of the ones, which were released with Android 8 and later updated to Android 9.
2. The devices, whose root file system (`/`) is an actual partition (so-called "system-as-root" devices). The list includes most of the recent devices released with Android version 9 and newer.

On the first kind of devices, this module works just fine. You may install the module and expect it to work without any additional actions from your side.

On the second kind of devices, installation may require manual intervention because currently, Magisk lacks functionality to make reversible modifications to the root file system. You need to manually modify the "system" partition to include at least the following symbolic links before installation:

```
/opt -> /data/entware-magisk/entware
/bin -> /system/bin
```
Please note that modifying the "system" partition makes the installation *non-systemless anymore*. Please do your research on how to make the required changes. As stated [here](https://github.com/topjohnwu/magisk_files/blob/6510533d6a8bb751152539919f57bb616c2405af/notes.md), in some cases, it might be impossible or dangerous. In other cases, it might be as easy as opening a shell with root privileges:

```
$ su -l
```

remounting root file system for reading and writing:

```
# mount -o remount,rw /
```

creating the required links:

```
# ln -sf /data/entware-magisk/entware /opt
# ln -sf /system/bin /bin
```

and remounting root file system read-only:

```
# mount -o remount,ro /
```

After you have figured out how to make the required changes and made them, you may reinstall the module. Installation should complete without any errors. Everything else is taken care of by the module.

# Installation

Currently, this module is not available in the official repository of the Magisk modules. But you can install it manually:

1. Download the module to your phone's storage from the projects' [**Releases** section](../../releases/).
2. In **Magisk Manager**, open the sidebar and select **Modules**.
3. Hit the floating button with a plus sign, then locate the downloaded module.
4. Open it. It will begin installation right away.
5. Reboot your phone when prompted.

The module installs Entware into `/data/entware-magisk/entware` directory. There are also additional support files and directories in the `/data/entware-magisk`, in particular:

* `profile.d` - you can use this directory in the same way you would use `/etc/profile.d` on a conventional Linux installation;
* `bin` - this directory gets added to the `PATH` environmental variable.

Software from the Entware repository uses GNU C Library and, thus, does not use the name resolution facility of the Android OS. By default [Google Public DNS Resolver](https://developers.google.com/speed/public-dns) is used (8.8.8.8, 8.8.4.4) by this installer. You can change this later by editing the `/opt/etc/resolv.conf` file.

Optionally, you may want to enable remote access to the device via SSH. To do so:

1. Open the shell with root privileges: `su -l`
2. Install `dropbear` package: `opkg install dropbear`
3. Set the password for the `root` account mapping: `/opt/bin/passwd`
4. Start the `dropbear` SSH-daemon (it should start automatically on the next boot): `/opt/etc/init.d/S51dropbear start`

Please keep in mind that invoking the `/opt/bin/passwd` command will not change the password for your `root` account on the device. Entware maintains its own mappings for the existing user accounts (`/opt/etc/passwd`) and groups (`/opt/etc/group`). By default, these files contain only mappings for the `root` user account and group, but you can change them to suit your needs.

# Uninstallation

Uninstalling Entware, installed using this module, is straightforward: uninstall the module from within **Magisk Manager** and follow the instructions.

Please note that by default doing so also **removes** the `/data/entware-magisk` directory. If you do not want this behaviour and want to keep the directory, you can create an empty file named `.keep` inside this directory (e.g. by invoking the command `touch /data/entware-magisk/.keep` from within a shell with root privileges).

# See Also
1. [Opkg Package Manager](https://openwrt.org/docs/guide-user/additional-software/opkg)
2. [Entware Wiki](https://github.com/Entware/Entware/wiki)
3. [Magisk Documentation](https://topjohnwu.github.io/Magisk/)
