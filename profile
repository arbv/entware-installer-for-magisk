#!/bin/sh
# In most cases, you do NOT want to load this file directly.  It is
# better to use /etc/profile as usual (which should in turn load this
# file).  Also, it is better to not modify this file. Please put your
# customisation files into "profile.d" directory.

PROFILE_SCRIPT_LOADED="$(id -u)" # see mkshrc for details.
export PROFILE_SCRIPT_LOADED

# ANDROID_START_ENV_FILE and ENTWARE_PROFILE are defined in
# /system/etc/mkshrc and in /system/etc/profile.  See the Magisk's
# Entware startup script for additional details (usually
# /data/adb/modules/entware-magisk/service.sh).
print_start_env ()
{
    if [ -n "$1" ] && [ -r "$ANDROID_START_ENV_FILE" ]; then
        grep -e "^$1=" "$ANDROID_START_ENV_FILE"
    fi
}

load_start_env_var()
{
    if [ -n "$1" ]; then
        LOADED_VAR="$(print_start_env "$1")"
        if [ -n "$LOADED_VAR" ]; then
            eval "export $LOADED_VAR"
        fi
    fi
    unset LOADED_VAR
}

load_start_env_var_if_empty()
{
    if [ -z "$(eval echo \"\$"$1"\")" ]; then
        load_start_env_var "$1"
    fi
}

# Set umask to a sane value.
if [ "$(id -u)" -eq 0 ]; then
    umask 022
else
    umask 077
fi

# Set HOME to the one defined in Entware.
INITIAL_HOME="$HOME" # save the old value
ENTWARE_HOME="$(su 0 -c cat /opt/etc/passwd | cut -d ':' -f 3,6 | grep -e "^$(id -u):" | cut -d ':' -f 2)"
if [ -n "$ENTWARE_HOME" ]; then
    export HOME="$ENTWARE_HOME"
    if [ "$PWD" != "$HOME" ] && [ "$(echo "$0" | dd count=1 bs=1 2> /dev/null)" = "-" ]; then
        cd "$HOME" || echo "Cannot change directory to \"$HOME\"."
    fi
fi
unset ENTWARE_HOME

# Default Android PATH
load_start_env_var PATH

# Entware
if [ -d /opt/bin ]; then
    PATH="$PATH:/opt/bin"
fi

if [ "$(id -u)" -eq 0 ] && [ -d /opt/sbin ]; then
    PATH="$PATH:/opt/sbin"
fi

# Add the "bin" directory to PATH
LOCALBIN="$(dirname "$ENTWARE_PROFILE")/bin"
if [ -d "$LOCALBIN" ]; then
    PATH="$PATH:$LOCALBIN"
fi
unset LOCALBIN

# Add the ~/bin directory to PATH
USERBIN="$HOME/bin"
if [ -n "$HOME" ] && [ -d "$USERBIN" ]; then
    PATH="$PATH:$USERBIN"
fi
unset USERBIN

export PATH

if [ -d /opt/share/terminfo ]; then
    export TERMINFO=/opt/share/terminfo
fi

# Set location of the temporary directory.
# Please notice that we are going to prefer ~/tmp if it exist.
# It might be necessary because of SELinux limitations.
if [ -n "$HOME" ] && [ -d "$HOME/tmp" ]; then
    export TMP="$HOME/tmp"
    export TEMP="$HOME/tmp"
elif [ -d /opt/tmp ]; then
    export TMP=/opt/tmp
    export TEMP=/opt/tmp
fi

# Load values of some Android environmental variables.  Native android
# tools might complain if these are not set.  This might happen when
# accessing the device via SSH.
load_start_env_var_if_empty ANDROID_ROOT
load_start_env_var_if_empty ANDROID_DATA
load_start_env_var_if_empty ANDROID_ASSETS
load_start_env_var_if_empty EXTERNAL_STORAGE
load_start_env_var_if_empty ANDROID_PROPERTY_WORKSPACE
load_start_env_var_if_empty ASEC_MOUNTPOINT

unset ANDROID_START_ENV_FILE

# Load files from profile.d
if [ -d "$ENTWARE_PROFILE.d" ]; then
    for profile in "$ENTWARE_PROFILE.d/"*.sh; do
        [ -r "$profile" ] && . "$profile"
    done
    unset profile
fi

# Try to load ~/.profile if no such file were loaded before setting
# HOME to ENTWARE_HOME.
if [ "$INITIAL_HOME" != "$HOME" ] && ! [ -r "$INITIAL_HOME/.profile" ] && [ -r "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

unset INITIAL_HOME
