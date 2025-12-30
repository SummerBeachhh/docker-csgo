#!/bin/bash
set -e
if [ "${DEBUG}" = "true" ]; then
  set -x
fi
shopt -s extglob

steam_dir="${HOME}/Steam"
server_dir="${HOME}/server"
server_installed_lock_file="${server_dir}/installed.lock"
csgo_dir="${server_dir}/csgo"
csgo_custom_files_dir="${CSGO_CUSTOM_FILES_DIR-"/usr/csgo"}"

install() {
  echo '> Installing server ...'
  set -x
  $steam_dir/steamcmd.sh \
    +force_install_dir $server_dir \
    +login anonymous \
    +app_update 740 validate \
    +quit
  set +x
  echo '> Done'
  touch $server_installed_lock_file
}

sync_custom_files() {
  echo "> Checking for custom files at \"$csgo_custom_files_dir\" ..."
  if [ -d "$csgo_custom_files_dir" ]; then
    echo "> Found custom files. Syncing with \"${csgo_dir}\" ..."
    set -x
    cp -asf $csgo_custom_files_dir/* $csgo_dir # Copy custom files as soft links
    find $csgo_dir -xtype l -delete # Find and delete broken soft links
    set +x
    echo '> Done'
  else
    echo '> No custom files found'
  fi
}

start() {
  echo '> Starting server ...'
  additionalParams=""

  # 检查 GSLT 是否设置
  if [ -z "$CSGO_GSLT" ]; then
    echo
    echo "*******************************************************"
    echo "***                                                 ***"
    echo "***       WARNING: CSGO_GSLT NO SET 未设置！        ***"
    echo "***                                                 ***"
    echo "***   公网服务器必须设置有效的 GSLT 令牌             ***"
    echo "***   否则服务器将无法在互联网上被发现和加入          ***"
    echo "***                                                 ***"
    echo "***   请使用 -e CSGO_GSLT=\"your_token_here\" 启动容器 ***"
    echo "***                                                 ***"
    echo "*******************************************************"
    echo
  else
    additionalParams+=" +sv_setsteamaccount $CSGO_GSLT"
  fi

  if [ -n "$CSGO_PW" ]; then
    additionalParams+=" +sv_password $CSGO_PW"
  fi
  if [ -n "$CSGO_HOSTNAME" ]; then
    additionalParams+=" +hostname $CSGO_HOSTNAME"
  fi
  if [ -n "$CSGO_WS_API_KEY" ]; then
    additionalParams+=" -authkey $CSGO_WS_API_KEY"
  fi
  if [ "${CSGO_FORCE_NETSETTINGS-"false"}" = "true" ]; then
    additionalParams+=" +sv_minrate 786432 +sv_mincmdrate 128 +sv_minupdaterate 128"
  fi
  if [ "${CSGO_TV_ENABLE-"false"}" = "true" ]; then
    additionalParams+=" +tv_enable 1"
    additionalParams+=" +tv_delaymapchange ${CSGO_TV_DELAYMAPCHANGE-1}"
    additionalParams+=" +tv_delay ${CSGO_TV_DELAY-45}"
    additionalParams+=" +tv_deltacache ${CSGO_TV_DELTACACHE-2}"
    additionalParams+=" +tv_dispatchmode ${CSGO_TV_DISPATCHMODE-1}"
    additionalParams+=" +tv_maxclients ${CSGO_TV_MAXCLIENTS-10}"
    additionalParams+=" +tv_maxrate ${CSGO_TV_MAXRATE-0}"
    additionalParams+=" +tv_overridemaster ${CSGO_TV_OVERRIDEMASTER-0}"
    additionalParams+=" +tv_snapshotrate ${CSGO_TV_SNAPSHOTRATE-128}"
    additionalParams+=" +tv_timeout ${CSGO_TV_TIMEOUT-60}"
    additionalParams+=" +tv_transmitall ${CSGO_TV_TRANSMITALL-1}"
    if [ -n "${CSGO_TV_NAME}" ]; then
      additionalParams+=" +tv_name ${CSGO_TV_NAME}"
    fi
    if [ -n "${CSGO_TV_PORT}" ]; then
      additionalParams+=" +tv_port ${CSGO_TV_PORT}"
    fi
    if [ -n "${CSGO_TV_PASSWORD}" ]; then
      additionalParams+=" +tv_password ${CSGO_TV_PASSWORD}"
    fi
  fi

  set -x
  exec $server_dir/srcds_run \
    -game csgo \
    -console \
    -norestart \
    -usercon \
    -nobreakpad \
    +ip "${CSGO_IP-0.0.0.0}" \
    -port "${CSGO_PORT-27015}" \
    -tickrate "${CSGO_TICKRATE-128}" \
    -maxplayers_override "${CSGO_MAX_PLAYERS-16}" \
    +game_type "${CSGO_GAME_TYPE-0}" \
    +game_mode "${CSGO_GAME_MODE-1}" \
    +mapgroup "${CSGO_MAP_GROUP-mg_active}" \
    +map "${CSGO_MAP-de_dust2}" \
    +rcon_password "${CSGO_RCON_PW-changeme}" \
    $additionalParams \
    $CSGO_PARAMS
}

if [ ! -z $1 ]; then
  $1
else
  # 首次运行安装服务器文件，后续直接启动
  if [ ! -f "$server_installed_lock_file" ]; then
    install
  fi
  sync_custom_files
  start
fi