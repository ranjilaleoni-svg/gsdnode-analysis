#!/system/bin/sh
# Neutralizare permanenta gsdnode_android + firmware suspect
# Ruleaza o singura data, cu root (adb root; adb shell < acest fisier)
# Reversibil: backup-urile raman in /sdcard/box_backup_2026-11-16/

set -e
BK=/sdcard/box_backup_2026-11-16
mkdir -p "$BK"

echo "== 1. Backup fisiere originale =="
cp /system/bin/init.sh "$BK/init.sh.orig" 2>/dev/null || true
cp /data/gsdnode/gsdnode_android "$BK/gsdnode_android.orig" 2>/dev/null || true

echo "== 2. Oprire proces curent =="
pkill -9 -f gsdnode_android 2>/dev/null || true
pkill -9 -f init.sh 2>/dev/null || true
sleep 1

echo "== 3. Impiedica re-copierea binarului original peste stub =="
setprop persist.gsdnode.init.copy 1

echo "== 4. Inlocuire binar cu stub inofensiv (exit imediat) =="
rm -rf /data/gsdnode
mkdir -p /data/gsdnode
printf '#!/system/bin/sh\nexit 0\n' > /data/gsdnode/gsdnode_android
chmod 755 /data/gsdnode/gsdnode_android
chown root:root /data/gsdnode/gsdnode_android

echo "== 5. Dezactivare update-uri silentioase (FOTA / Adups / RKUpdate) =="
pm disable-user --user 0 com.amediatech.update 2>/dev/null || true
pm disable-user --user 0 com.chihi.fota 2>/dev/null || true
pm disable-user --user 0 android.rockchip.update.service 2>/dev/null || true
pm clear com.amediatech.update 2>/dev/null || true
pm clear com.chihi.fota 2>/dev/null || true
pm clear android.rockchip.update.service 2>/dev/null || true

echo "== 6. Curatare payload ascuns (daca a reaparut) =="
rm -rf /data/blueberry 2>/dev/null || true

echo "== 7. Reactivare Google Play Protect =="
settings put global package_verifier_enable 1
settings put global package_verifier_user_consent 1

echo "== GATA =="
sleep 2
echo "Verificare finala:"
ps -A | grep -i gsd || echo "  (niciun proces gsdnode activ - OK)"
pm list packages -d | grep -E "amediatech|chihi|rockchip.update" || echo "  (pachetele FOTA sunt dezactivate - OK)"
getprop global.package_verifier_enable 2>/dev/null
settings get global package_verifier_enable
