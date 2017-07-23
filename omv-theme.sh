#!/bin/sh
# omv-theme https://github.com/Wolf2000Pi/wolf2000-tools
# Version 1.0
# by Wolf2000

INTERACTIVE=True
ASK_TO_REBOOT=0
#BLACKLIST=/etc/modprobe.d/raspi-blacklist.conf
#CONFIG=/boot/config.txt

calc_wt_size() {
  # NOTE: it's tempting to redirect stderr to /dev/null, so supress error 
  # output from tput. However in this case, tput detects neither stdout or 
  # stderr is a tty and so only gives default 80, 24 values
  WT_HEIGHT=17
  WT_WIDTH=$(tput cols)

  if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" ]; then
    WT_WIDTH=25
  fi
  if [ "$WT_WIDTH" ]; then
    WT_WIDTH=35
  fi
  WT_MENU_HEIGHT=$(($WT_HEIGHT-7))
}

do_about() {
  whiptail --msgbox "\
Ich hoffe ihr seid zufrieden?
Für Schäden übernehme ich Keine Haftung!
@Wolf2000.\
Ich möchte mich für die mithilfe auch Bedanken bei 
@DeepB für [CSS] Black OMV GUI v5, @The Master
" 20 70 1
}


set_config_var() {
  lua - "$1" "$2" "$3" <<EOF > "$3.bak"
local key=assert(arg[1])
local value=assert(arg[2])
local fn=assert(arg[3])
local file=assert(io.open(fn))
local made_change=false
for line in file:lines() do
  if line:match("^#?%s*"..key.."=.*$") then
    line=key.."="..value
    made_change=true
  end
  print(line)
end

if not made_change then
  print(key.."="..value)
end
EOF
mv "$3.bak" "$3"
}

get_config_var() {
  lua - "$1" "$2" <<EOF
local key=assert(arg[1])
local fn=assert(arg[2])
local file=assert(io.open(fn))
for line in file:lines() do
  local val = line:match("^#?%s*"..key.."=(.*)$")
  if (val ~= nil) then
    print(val)
    break
  end
end
EOF
}

do_finish() {
  #disable_raspi_config_at_boot
  if [ $ASK_TO_REBOOT -eq 1 ]; then
    whiptail --yesno "Would you like to reboot now?" 20 60 2
    if [ $? -eq 0 ]; then # yes
      sync
      reboot
    fi
  fi
  exit 0
}



do_omv_triton() {
echo 'OMV_WEBUI_THEME=triton' >> /etc/default/openmediavault
cp /root/omv-theme/theme-custom.css /var/www/openmediavault/css/
rm -r /var/www/openmediavault/css/theme-custom.css
exec omv-theme
}

do_omv_gray() {
echo 'OMV_WEBUI_THEME=gray' >> /etc/default/openmediavault
cp /root/omv-theme/theme-custom.css /var/www/openmediavault/css/
rm -r /var/www/openmediavault/css/theme-custom.css
exec omv-theme
}

do_omv_black() {
echo 'OMV_WEBUI_THEME=triton' >> /etc/default/openmediavault
cp /root/omv-theme/theme-custom.css /var/www/openmediavault/css/
exec omv-theme
}

do_update_omv-theme() {
  rm -r /root/omv-theme/ &&
  git clone git clone https://github.com/Wolf2000Pi/omv-theme.git &&
  cd /root/omv-theme &&
  chmod +x omv-theme.sh &&
  cd /usr/bin/ &&
  rm -r omv-theme &&
  cp /root/omv-theme/omv-theme.sh /usr/bin/omv-theme &&
  cd &&
  exec omv-theme
}


#
# Interactive use loop
#
calc_wt_size
while true; do
  FUN=$(whiptail --title "OMV GUI-Theme config" --menu "Setup Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
    "1 Gray" "" \
    "2 Triton" "" \
    "3 Black" "" \
	"4 About" ""\
	"5 Update" ""\
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    do_finish
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      1\ *) do_omv_gray ;;
      2\ *) do_omv_triton ;;
      3\ *) do_omv_black ;;
	  4\ *) do_about ;;
	  5\ *) do_update_omv-theme ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 40 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 40 1
  else
    exit 1
  fi
done


