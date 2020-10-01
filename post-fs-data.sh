#!/system/bin/sh

if [ -z "$MODPATH" ]; then
    MODPATH="/data/adb/modules/entware-magisk"
fi

# Create empty login shell and interactive shell initialisation script files if necessary.
for script in profile mkshrc
do
    SCRIPT_FILE="/system/etc/$script"
    if ! [ -r "$SCRIPT_FILE" ] && ! [ -r "${MODPATH}${SCRIPT_FILE}" ]; then
        echo "# This is a dummy \"$SCRIPT_FILE\" file created by \"$MODPATH/post-fs-data.sh\"." > "${MODPATH}${SCRIPT_FILE}"
    elif [ -r "$SCRIPT_FILE" ] && [ -r "${MODPATH}${SCRIPT_FILE}" ]; then
        rm -f "${MODPATH}${SCRIPT_FILE}"
    fi
    unset SCRIPT_FILE
done
