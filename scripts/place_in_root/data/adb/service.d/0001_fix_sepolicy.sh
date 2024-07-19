#!/system/bin/sh

# ONCE ROOTED; MOVE THIS FILE TO /data/adb/service.d/

alias su="/system/bin/magisk su"
alias magiskpolicy="/data/adb/magisk/magiskpolicy"

su -c "magiskpolicy --live 'allow untrusted_app_27 * * {*}'"
su -c "magiskpolicy --live 'allow system_server * * {*}'"
su -c "magiskpolicy --live 'allow system_suspend * * {*}'"
su -c "magiskpolicy --live 'allow mtk_hal_nvramagent * * {*}'"
su -c "magiskpolicy --live 'allow magisk * * {*}'"
su -c "magiskpolicy --live 'allow system_app * * {*}'"
su -c "magiskpolicy --live 'allow mnld * * {*}'"
su -c "magiskpolicy --live 'allow platform_app * * {*}'"
su -c "magiskpolicy --live 'allow untrusted_app * * {*}'"
su -c "magiskpolicy --live 'allow untrusted_app_29 * * {*}'"
su -c "magiskpolicy --live 'allow priv_app * * {*}'"

su -c "magiskpolicy --live 'allow untrusted_app_30 * * {*}'"
su -c "magiskpolicy --live 'allow untrusted_app_25 * * {*}'"
su -c "magiskpolicy --live 'allow audioserver * * {*}'"
su -c "magiskpolicy --live 'allow crash_dump * * {*}'"

su -c "magiskpolicy --live 'allow su * * {*}'"
su -c "magiskpolicy --live 'allow mediaserver * * {*}'"
su -c "magiskpolicy --live 'allow hwservicemanager * * {*}'"
su -c "magiskpolicy --live 'allow mtk_hal_c2 * * {*}'"
su -c "magiskpolicy --live 'allow surfaceflinger * * {*}'"
su -c "magiskpolicy --live 'allow mediaswcodec * * {*}'"
su -c "magiskpolicy --live 'allow shell * * {*}'"

su -c "magiskpolicy --live 'allow * { app_data_file privapp_data_file } file { execute_no_trans }'"

su -c "magiskpolicy --live 'allow gsid * * {*}'"

# below is for arrowos GSI
su -c "magiskpolicy --live 'allow surfaceflinger * * {*}'"
su -c "magiskpolicy --live 'allow vold * * {*}'"
su -c "magiskpolicy --live 'allow radio * * {*}'"
su -c "magiskpolicy --live 'allow installd * * {*}'"

su -c "magiskpolicy --live 'allow ccci_mdinit * * {*}'"
su -c "magiskpolicy --live 'allow vendor_init * * {*}'"
su -c "magiskpolicy --live 'allow hal_fingerprint_oppo_compat * * {*}'"
su -c "magiskpolicy --live 'allow init * * {*}'"
su -c "magiskpolicy --live 'allow rild * * {*}'"

su -c "magiskpolicy --live 'allow bip * * {*}'"
su -c "magiskpolicy --live 'allow gsm0710muxd * * {*}'"

