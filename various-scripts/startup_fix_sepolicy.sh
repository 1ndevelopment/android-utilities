#!/system/bin/sh
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 1
done
## Fix common SELinux non-permissive issues
/system/bin/magisk su -c "/system/bin/magiskpolicy --live 'allow untrusted_app_27 * * {*}' 'allow system_server * * {*}' 'allow system_suspend * * {*}' 'allow mtk_hal_nvramagent * * {*}' 'allow magisk * * {*}' 'allow system_app * * {*}' 'allow mnld * * {*}' 'allow platform_app * * {*}' 'allow untrusted_app * * {*}' 'allow untrusted_app_29 * * {*}' 'allow priv_app * * {*}' 'allow untrusted_app_30 * * {*}' 'allow untrusted_app_25 * * {*}' 'allow audioserver * * {*}' 'allow crash_dump * * {*}' 'allow su * * {*}' 'allow mediaserver * * {*}' 'allow hwservicemanager * * {*}' 'allow mtk_hal_c2 * * {*}' 'allow surfaceflinger * * {*}' 'allow mediaswcodec * * {*}' 'allow shell * * {*}' 'allow gsid * * {*}'"

## Fix SELinux Policies for ArrowOS
/system/bin/magisk su -c "/system/bin/magiskpolicy --live 'allow surfaceflinger * * {*}' 'allow vold * * {*}' 'allow radio * * {*}' 'allow installd * * {*}' 'allow ccci_mdinit * * {*}' 'allow vendor_init * * {*}' 'allow hal_fingerprint_oppo_compat * * {*}' 'allow init * * {*}' 'allow rild * * {*}' 'allow bip * * {*}' 'allow gsm0710muxd * * {*}' 'allow phhsu_daemon * * {*}' 'allow isolated_app * * {*}'"

