#!/bin/bash

set -e

if [ "${DEBUG}" = "true" ]; then
  set -x
fi

shopt -s extglob

server="$HOME/server.sh"
server_sourcemod="$HOME/server_sourcemod.sh"
csgo_dir="$HOME/server/csgo"

# 只安装的插件
nolobbyreservation_url="https://github.com/SummerBeachhh/nolobbyreservation/releases/download/unknown/nolobbyreservation.zip"

call_if_defined() {
  local script="$1"
  local func="$2"
  if grep -qE "^[[:space:]]*${func}[[:space:]]*\\(\\)" "$script"; then
    "$script" "$func"
  fi
}

install_or_update_plugins() {
  if grep -qE "^[[:space:]]*install_or_update_plugin[[:space:]]*\\(" "$server_sourcemod"; then
    "$server_sourcemod" install_or_update_plugin "nolobbyreservation" "$nolobbyreservation_url"
  fi
}

manage_plugins() {
  if grep -qE "^[[:space:]]*manage_plugins[[:space:]]*\\(" "$server_sourcemod"; then
    "$server_sourcemod" manage_plugins
  fi
}

if [ -n "$1" ]; then
  "$1"
else
  "$server" install_or_update
  call_if_defined "$server_sourcemod" install_or_update_mods
  install_or_update_plugins
  manage_plugins
  call_if_defined "$server_sourcemod" manage_admins
  "$server" should_add_server_configs
  call_if_defined "$server" should_disable_bots
  "$server" sync_custom_files
  exec "$server" start
fi
