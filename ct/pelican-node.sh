#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# Co-author: vrozaksen
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ____       ___                        _   __          __   
   / __ \___  / (_)________ _____        / | / /___  ____/ /__ 
  / /_/ / _ \/ / / ___/ __ `/ __ \______/  |/ / __ \/ __  / _ \
 / ____/  __/ / / /__/ /_/ / / / /_____/ /|  / /_/ / /_/ /  __/
/_/    \___/_/_/\___/\__,_/_/ /_/     /_/ |_/\____/\__,_/\___/ 
                                                               
EOF
}
header_info
echo -e "Loading..."
APP="Pelican-Node"
var_disk="16"
var_cpu="2"
var_ram="2048"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
header_info
if [[  ! -f /usr/local/bin/wings ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(wget -q https://github.com/pelican-dev/wings/releases/latest -O - | grep "title>Release" | cut -d " " -f 4 | sed 's/^v//')
msg_info "Updating $APP to ${RELEASE}"
systemctl stop wings
curl -L -o /usr/local/bin/wings "https://github.com/pelican-dev/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
chmod u+x /usr/local/bin/wings
systemctl restart wings
msg_ok "Updated $APP Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "Now you need to add your node to the Pelican panel. \n
Then run the command '${BL}sudo wings --debug${CL}' to test if it's working. \n
If it's working, you need to enable the Wings service using the command '${BL}systemctl enable --now wings${CL}'. \n"
