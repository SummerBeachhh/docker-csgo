#!/bin/bash

set -e

if [ "${DEBUG}" = "true" ]; then
  set -x
fi

shopt -s extglob

server=$HOME/server.sh
server_sourcemod=$HOME/server_sourcemod.sh
csgo_dir=$HOME/server/csgo

# 新增：nolobbyreservation 插件
nolobbyreservation_url="https://github.com/SummerBeachhh/nolobbyreservation/releases/download/unknown/nolobbyreservation.zip"

install_or_update_plugins() {
  $server_sourcemod install_or_update_plugin 'nolobbyreservation' $nolobbyreservation_url
}

manage_plugins() {
  if [ "${PUG_PRACTICE_MINIMAL_PLUGINS-"false"}" = "true" ]; then
    enabledPlugins="admin-flatfile,botmimic,csutils,nolobbyreservation"

    if [ -n "${SOURCEMOD_PLUGINS_ENABLED}" ]; then
      enabledPlugins+=",${SOURCEMOD_PLUGINS_ENABLED}"
    fi

    SOURCEMOD_PLUGINS_DISABLED="*" SOURCEMOD_PLUGINS_ENABLED="${enabledPlugins}" $server_sourcemod manage_plugins
  else
    $server_sourcemod manage_plugins
  fi
}

if [ ! -z $1 ]; then
  $1
else
  $server install_or_update
  $server_sourcemod install_or_update_mods
  install_or_update_plugins
  manage_plugins
  $server_sourcemod manage_admins
  $server should_add_server_configs
  $server sync_custom_files
  exec $server start
fi
