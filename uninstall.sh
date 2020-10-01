#!/system/bin/sh

ENTWARE_INSTALLATION_PATH="/data/entware-magisk"
if ! [ -f "$ENTWARE_INSTALLATION_PATH/.keep" ]; then
    rm -rf "$ENTWARE_INSTALLATION_PATH"
fi

unset ENTWARE_INSTALLATION_PATH
