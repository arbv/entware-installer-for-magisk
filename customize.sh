#!/system/bin/sh

# where we are going to put the support files
ENTWARE_INSTALLATION_PATH="/data/entware-magisk"
ENTWARE="${ENTWARE_INSTALLATION_PATH}/entware"

# default DNS resolvers
DNS1="8.8.8.8"
DNS2="8.8.4.4"

# print error message and exit
die ()
{
    ui_print "$1"
    if [ -d "$ENTWARE_INSTALLATION_PATH" ] && [ -n "$(find "$ENTWARE_INSTALLATION_PATH" -mindepth 1 -maxdepth 1)" ]; then
        ui_print "You may want to clear \"$ENTWARE_INSTALLATION_PATH\", reboot your device, and start anew."
    fi
    abort "Installation has been aborted."
}

die_on_error ()
{
    STATUS=$?
    if [ "$STATUS" -ne 0 ]; then
        unset STATUS
        die "$1"
    fi
    $?=$STATUS
    unset STATUS
}

# Let's detect the compatible Entware architecture
KERNEL_VERSION="$(cut -d ' ' -f 3 /proc/version)"
KERNEL_VERSION_MAJOR="$(echo "$KERNEL_VERSION" | cut -d '.' -f 1)"
KERNEL_VERSION_MINOR="$(echo "$KERNEL_VERSION" | cut -d '.' -f 2)"

if [ "$ARCH" = "arm" ] && [ "$KERNEL_VERSION_MAJOR" -ge "3" ] && [ "$KERNEL_VERSION_MINOR" -ge "2" ]; then
    ENTWARE_ARCH="armv7sf-k3.2"
elif [ "$ARCH" = "arm" ]; then
    ENTWARE_ARCH="armv7sf-k2.6"
elif [ "$ARCH" = "arm64" ] && [ "$KERNEL_VERSION_MAJOR" -ge "3" ] && [ "$KERNEL_VERSION_MINOR" -ge "10" ]; then
    ENTWARE_ARCH="aarch64-k3.10"
elif [ "$ARCH" = "arm64" ]; then
    ENTWARE_ARCH="armv7sf-k3.2"
elif [ "$ARCH" = "x64" ] && [ "$KERNEL_VERSION_MAJOR" -ge "3" ] && [ "$KERNEL_VERSION_MINOR" -ge "2" ]; then
    ENTWARE_ARCH="x64-k3.2"
elif [ "$ARCH" = "x64" ]; then
    ENTWARE_ARCH="x86-k2.6"
elif [ "$ARCH" = "x86" ] && [ "$KERNEL_VERSION_MAJOR" -ge "3" ] && [ "$KERNEL_VERSION_MINOR" -ge "2" ] && [ "$(grep -c x86_64 /proc/version)" -gt 0 ]; then
    # Some x86 devices (most notably ASUS Zenfone 2) might have 32-bit
    # userspace, but 64-bit kernel and, thus, capable of running
    # 64-bit version of Entware.
    ui_print "Guessing that kernel is x86_64 compatible."
    ENTWARE_ARCH="x64-k3.2"
elif [ "$ARCH" = "x86" ]; then
    ENTWARE_ARCH="x86-k2.6"
fi

if [ -z "$ENTWARE_ARCH" ]; then
    die "Cannot guess the Entware installation architecture!"
fi

ui_print "Entware $ENTWARE_ARCH is going to be installed into \"$ENTWARE\" with support files placed into \"$ENTWARE_INSTALLATION_PATH\"."
ui_print "You can change the default primary and secondary DNS resolvers ($DNS1, $DNS2) after the installation by editing \"$ENTWARE\etc\resolv.conf\" (/opt/etc/resolv.conf)."
ui_print "Make sure that you have a working Internet connection!"

# Let's initialise the "system/etc" directory
if ! [ -d "$MODPATH/system/etc" ]; then
    mkdir -p "$MODPATH/system/etc"
    die_on_error "Cannot create \"system/etc\"!"
fi

# resolv.conf link
ln -sf "/opt/etc/resolv.conf" "$MODPATH/system/etc/resolv.conf"
die_on_error "Cannot create \"system/etc/resolv.conf\" link!"

# Let's initialise the "system/bin" directory
if ! [ -d "$MODPATH/system/bin" ]; then
    mkdir -p "$MODPATH/system/bin"
    die_on_error "Cannot create \"system/bin\"!"
fi

# /bin/bash - for unportable scripts
ln -sf "/opt/bin/bash" "$MODPATH/system/bin/bash"
die_on_error "Cannot create \"system/bin/bash\" link!"

# Initialise the installation directory
for dir in bin profile.d entware
do
    DIR="${ENTWARE_INSTALLATION_PATH}/${dir}"
    if ! [ -d "$DIR" ]; then
        mkdir -p "$DIR"
        die_on_error "Cannot create \"$DIR\"!"
    fi
done
unset DIR

# install scripts
for script in profile mkshrc
do
    SCRIPT_SOURCE="${MODPATH}/${script}"
    SCRIPT_TARGET="${ENTWARE_INSTALLATION_PATH}/${script}"
    if ! [ -r "$SCRIPT_TARGET" ]; then
        cp -f "$SCRIPT_SOURCE" "$SCRIPT_TARGET"
        die_on_error "Cannot copy \"${script}\"!"
        chmod 644 "$SCRIPT_TARGET"
        die_on_error "Cannot set permissions on \"${script}\"!"
    fi
done
unset SCRIPT_SOURCE SCRIPT_TARGET


# Install Entware
if ! [ -x "${ENTWARE_INSTALLATION_PATH}/entware/bin/opkg" ]; then
    if [ "$(grep rootfs /proc/mounts  | cut -d " " -f 2)" = "/" ]; then
        mount -o remount,rw /
        die_on_error "Cannot remount \"\\\" for read and write!"
        ln -sf "$ENTWARE" /opt
        die_on_error "Cannot create /opt!"
        if ! [ -d /bin ]; then
            ln -sf /system/bin /bin
            die_on_error "Cannot create /bin (-> /system/bin)!"
        fi
        mount -o remount,ro /
        die_on_error "Cannot remount \"\\\" readonly!"
    else
        ui_print "Your device appears to have a real-partition as the root file system. Hopefully, you have created the required links beforehand (see the module's documentation for details)."
    fi
    # check if /bin/sh available
    if ! [ -x /bin/sh ]; then
        die "POSIX-compatible shell is not available as \"/bin/sh\". It is impossible to continues the installation."
    fi

    # check if /opt points to Entware
    if ! [ -L /opt ] || ! [ "$(readlink /opt)" = "$ENTWARE" ]; then
        die "\"/opt\" does not exist or does not point to \"$ENTWARE\"."
    fi

    OLD_PWD="$PWD"
    cd "$ENTWARE" || die "Cannot change the working directory to \"$ENTWARE\"!"

    wget -O - "http://bin.entware.net/$ENTWARE_ARCH/installer/generic.sh" | sh
    die_on_error "Entware installation has failed!"

    echo "nameserver $DNS1" > /opt/etc/resolv.conf
    die_on_error "Cannot set the first DNS resolver!"
    echo "nameserver $DNS2" >> /opt/etc/resolv.conf
    die_on_error "Cannot set the second DNS resolver!"

    if [ -f /opt/etc/profile ]; then
        mv /opt/etc/profile /opt/etc/profile.bak
        die_on_error "Renaming \"/opt/etc/profile\" has failed!"
    fi
    ln -sf /etc/profile /opt/etc/profile
    die_on_error "Cannot link /opt/etc/profile to /etc/profile!"

    # create home for root
    if ! [ -d /opt/root ]; then
        mkdir -p /opt/root
        die_on_error "Creating /opt/root has failed!"
        chmod 700 /opt/root
        die_on_error "Setting permissions on /opt/root has failed!"
    fi

    # create a user mapping for the root user
    echo "root:x:0:0::/opt/root:/system/bin/sh" > /opt/etc/passwd
    die_on_error "Cannot create the user \"root\"!"
    echo "root:x:0:root" > /opt/etc/group
    die_on_error "Cannot create the group \"root\"!"

    export TERMINFO=/opt/share/terminfo
    export TEMP=/opt/tmp
    export TMP=/opt/tmp

    /opt/bin/opkg install wget ldconfig bash shadow logger
    cd "$OLD_PWD" || die "Cannot change the working directory to \"$OLD_PWD\"!"
    unset OLD_PWD
    ui_print "Entware has been installed. Please reboot the device!"
fi

unset ENTWARE_INSTALLATION_PATH ENTWARE ENTWARE_ARCH
unset DNS1 DNS2
