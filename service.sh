#!/system/bin/sh

## The changes made by this script are NOT permanent and,
# thus, need to be repeated on each boot of the device.

ENTWARE_INSTALLATION_PATH="/data/entware-magisk"
ENTWARE_MKSHRC="$ENTWARE_INSTALLATION_PATH/mkshrc"
ENTWARE_PROFILE="$ENTWARE_INSTALLATION_PATH/profile"
ENTWARE="$ENTWARE_INSTALLATION_PATH/entware"

ANDROID_START_ENV_FILE="$ENTWARE/var/run/start-env.sh"

UNSLUNG="/opt/etc/init.d/rc.unslung"

# set umask to a sane value
umask 022

# Check if Entware directory is available
if ! [ -d "$ENTWARE" ]; then
    exit 1
fi

# ensure that some directories exist
ensure_dir_exists()
{
    if [ -n "$1" ] && ! [ -d "$1"  ]; then
        mkdir -p "$1"
        if [ -n "$2" ]; then
            chmod "$2" "$1"
        fi
    fi
}

ensure_dir_exists "$ENTWARE/tmp" 777
ensure_dir_exists "$ENTWARE/var"
ensure_dir_exists "$ENTWARE/var/run" 755

## Here we try to tune the Android's filesystem to be more Unix
## compatible. It is going to work only on devices which use ramdisk
## (rootfs) for their root (/).
if [ "$(grep rootfs /proc/mounts  | cut -d " " -f 2)" = "/" ]; then
    # Make the root file system writable.
    mount -o rw,remount /

    # Link /bin to /system/bin to make /bin/sh accessible (for portable
    # scripts)
    if ! [ -d /bin ]; then
        ln -sf /system/bin /bin
    fi

    # Link /usr/bin to /system/bin to make /usr/bin/env accessible (again,
    # for portable scripts: #!/usr/bin/env ...)
    ENV_LOCATION="$(which env)"
    if ! [ -d /usr ] && [ -n "$ENV_LOCATION" ]; then
        mkdir /usr
        ln -sf "$(dirname "$ENV_LOCATION")" /usr/bin
    fi

    # Link /opt to the Entware directory.
    if ! [ -d /opt  ]; then
        ln -sf "$ENTWARE" /opt
    fi

    # Link /var to /opt/var (mostly for busybox crond, if we are going to
    # use one).
    if ! [ -d /var ]; then
        ln -sf "$ENTWARE/var" /var
    fi

    # Create /tmp (again, mostly for Entware).
    if ! [ -d /tmp ]; then
        ln -sf "$ENTWARE/tmp" /tmp
    fi

    # Create /run.
    if ! [ -d /run ]; then
        ln -sf "$ENTWARE/var/run" /run
    fi

    # Link /lib64 (and /lib, just in case) to the Entware's /opt/lib to
    # run ordinary Linux executables built for conventional distributions
    # (if you are lucky enough to have recent enough kernel and glibc).
    # Additionally to that, one has to install 'ldconfig', if not
    # installed, (opkg install ldconfig) and run it to build the libraries
    # cache (and rerun it after installing and removing libraries).
    if ! [ -d /lib ]; then
        mkdir -p /lib
    fi

    if ! [ -d /lib64 ]; then
        mkdir -p /lib64
    fi

    if [ -d /lib ] && [ -d "$ENTWARE/lib" ]; then
        ln -s "$ENTWARE"/lib/ld-linux*.so* /lib
    fi

    if [ -d /lib64 ] && [ -d "$ENTWARE/lib" ]; then
        ln -s "$ENTWARE"/lib/ld-linux*.so* /lib64
    fi

    # Make the root filesystem read only again.
    mount -o ro,remount /
fi

# check if /opt is available
if ! [ -d /opt ]; then
    # there is no point to continue
    exit 1
fi

# Mount some temporary file systems.
if [ -d "$ENTWARE/tmp" ]; then
    mount -t tmpfs tmpfs "$ENTWARE/tmp"
fi

if [ -d "$ENTWARE/var/run" ]; then
    mount -t tmpfs -o size=1m tmpfs "$ENTWARE/var/run"
fi

## Modify the system shell initialisation files.
augment_rc ()
{
    if [ -d /opt/var/run ] && [ -n "$1" ] && [ -n "$2" ]; then
        SYSRC="$1"
        USERFILE="$2"
        TMPRC="/opt/var/run/$(basename "$SYSRC")"
        if [ -r "$SYSRC" ]; then
            cp  "$SYSRC" "$TMPRC"
        else
            return 1
        fi
        { echo "# modifications to load a system wide initialisation file";
          echo "# from \"$USERFILE\"";
          echo "ANDROID_START_ENV_FILE=\"$ANDROID_START_ENV_FILE\"";
          echo "export ENTWARE=\"$ENTWARE\"";
          echo "export ENTWARE_MKSHRC=\"$ENTWARE_MKSHRC\"";
          echo "export ENTWARE_PROFILE=\"$ENTWARE_PROFILE\"";
          echo "if [ -r  \"$USERFILE\" ]; then";
          echo "    . \"$USERFILE\"";
          echo "fi"; } >> "$TMPRC"
        mount -o bind "$TMPRC" "$SYSRC"
    fi
    return 0
}

# Augment an interactive shell initialisation file to load our file.
augment_rc "/system/etc/mkshrc" "$ENTWARE_MKSHRC"

# Augment a login shell initialisation file to load our file.
augment_rc "/system/etc/profile" "$ENTWARE_PROFILE"

## Save initial environment to restore some variables if they are not
## set. It might be necessary when accessing device via SSH.
if [ -d "$(dirname "$ANDROID_START_ENV_FILE")" ]; then
    env > "$ANDROID_START_ENV_FILE"
fi

# Let's try to generate ld.so.cache for the first time
if ! [ -f /opt/etc/ld.so.cache ] && [ -x /opt/sbin/ldconfig ]; then
    /opt/sbin/ldconfig
fi

## Start Entware services
if [ -x "$UNSLUNG" ]; then
    "$UNSLUNG" start
fi

exit 0
