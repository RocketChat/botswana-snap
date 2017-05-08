#! /bin/bash

function on_exit {
    unset HUBOT_DISCORD_TOKEN
    unset HUBOT_HIPCHAT_JID
    unset HUBOT_HIPCHAT_PASSWORD
    unset HUBOT_HIPCHAT_ROOMS
    unset HUBOT_SLACK_TOKEN
    unset LISTEN_ON_ALL_PUBLIC
    unset RESPOND_TO_DM
    unset RESPOND_TO_EDITED
    unset ROCKETCHAT_PASSWORD
    unset ROCKETCHAT_ROOM
    unset ROCKETCHAT_URL
    unset ROCKETCHAT_USER
}
trap on_exit EXIT

source ${SNAP}/bin/common_functions.sh
require_nonroot
check_authz

PS3="> "

echo "[?] What is your chat engine?"
select engine in "Rocket.Chat" "Discord" "HipChat" "Slack"
do
    case ${engine} in
        Rocket.Chat)
            adapter="rocketchat"
            break;;
        Discord)
            adapter="discord"
            break;;
        HipChat)
            adapter="hipchat"
            break;;
        Slack)
            adapter="slack"
            break;;
    esac
done

fname="${SNAP_USER_COMMON}/.prev_bot_name"
touch "${fname}"
prev_bot_name=$(cat "${fname}")
while [[ ! "${bot_name}" =~ ^[-_@.a-zA-Z0-9]{3,128}$ ]]
do
    read -ei "${prev_bot_name}" -p "[?] What is the bot account's user name or ID?
> " bot_name
    which "${bot_name}" > /dev/null && bot_name="" && continue
    case ${adapter} in
        rocketchat)
            export ROCKETCHAT_USER=${bot_name}
            ;;
        hipchat)
            if [[ ! ${bot_name} =~ ^[0-9]{1,10}_[0-9]{1,10}@chat.hipchat.com$ ]]
            then
                [[ ${bot_name} =~ ^[0-9]{1,10}_[0-9]{1,10}$ ]] && bot_name+="@chat.hipchat.com"
                echo "[-] Invalid ID for HipChat! Please specify the bot account's Jabber ID."
                echo "    E.g.: 123_456@chat.hipchat.com"
                prev_bot_name=${bot_name}
                bot_name=""
            fi
            export HUBOT_HIPCHAT_JID=${bot_name}
            ;;
    esac
done
printf "${bot_name}" > ${fname}

fname="${SNAP_USER_COMMON}/${bot_name}/.prev_url"
mkdir -p $(dirname ${fname})
touch ${fname}
prev_url=$(cat "${fname}")
while [[ ! "${engine_url}" =~ ^https?://[-_#.a-zA-Z0-9:/\&?=]{3,128}$ ]]
do
    # Setting IFS to a space since URLs should never have a space
    IFS=" " read -ei "${prev_url}" -p "[?] What is your ${engine} URL?
> " engine_url
done
printf ${engine_url} > ${fname}
case ${adapter} in
    rocketchat) export ROCKETCHAT_URL=${engine_url};;
esac
bot_id=$(printf ${engine_url} | base64)

local_bot_dir="${SNAP_USER_COMMON}/${bot_name}"
[[ -n ${bot_id} ]] && local_bot_dir+="/${bot_id}"
mkdir -p "${local_bot_dir}"

function warn_error {
    msg=("$@")
    echo "[-] Something's not right..."
    [[ -n ${msg} ]] && printf '[!] %s\n' "${msg[@]}"
    echo "[*] Please check ${logpath} for more details."
}

function exit_if_running {
    pid=$(pgrep -f "${adapter} --name ${local_bot_dir} --alias ${bot_name}")
    if [[ -n ${pid} ]]
    then
        msg="${1}"
        [[ -n ${msg} ]] && echo "${msg}"
        echo "    PID: ${pid}"
        exit 0
    fi
}

exit_if_running "[+] ${bot_name} is already running wild on ${engine}!"

   password_mask=2#0001
      token_mask=2#0010
 join_rooms_mask=2#0100
#    unused_mask=2#1000

function set_config_options {
    selected_options=2#0000
    case ${adapter} in
        rocketchat)
            selected_options=$((${selected_options} | ${password_mask}))
            selected_options=$((${selected_options} | ${join_rooms_mask}))
            ;;
        discord)
            selected_options=$((${selected_options} | ${token_mask}))
            ;;
        hipchat)
            selected_options=$((${selected_options} | ${password_mask}))
            selected_options=$((${selected_options} | ${join_rooms_mask}))
            ;;
        slack)
            selected_options=$((${selected_options} | ${token_mask}))
            ;;
    esac
}

function set_variables {
    if [[ $((${selected_options} & ${token_mask})) > 0 ]]
    then
        read -p "[?] What is your ${engine} bot token?
> " bot_token
        case ${adapter} in
            discord) export HUBOT_DISCORD_TOKEN=${bot_token};;
            slack  ) export HUBOT_SLACK_TOKEN=${bot_token};;
        esac
        unset bot_token
    fi

    if [[ $((${selected_options} & ${password_mask})) > 0 ]]
    then
        read -s -p "[?] What is ${bot_name}'s password?
    It will not be displayed as you type.
> " bot_password
        echo ""
        case ${adapter} in
            rocketchat) export ROCKETCHAT_PASSWORD=${bot_password};;
            hipchat   ) export HUBOT_HIPCHAT_PASSWORD=${bot_password};;
        esac
        unset bot_password
    fi

    if [[ $((${selected_options} & ${join_rooms_mask})) > 0 ]]
    then
        fname="${local_bot_dir}/.prev_rooms"
        touch ${fname}
        prev_rooms=$(cat "${fname}")
        [[ -z ${prev_rooms} ]] && prev_rooms="all"
        while [[ ! "${bot_rooms}" =~ ^[-_,a-zA-Z0-9]{3,128}$ ]]
        do
            read -ei "${prev_rooms}" -p "[?] Which channel(s) should ${bot_name} automatically join?
    Separate multiple channels with commas (no spaces); enter \"all\" for all public channels.
> " bot_rooms
        done
        printf "${bot_rooms}" > ${fname}
        case ${adapter} in
            rocketchat)
                if [[ ${bot_rooms,,} == "all" ]]
                then
                    export ROCKETCHAT_ROOM=""
                    export LISTEN_ON_ALL_PUBLIC="true"
                else
                    export ROCKETCHAT_ROOM=${bot_rooms}
                fi
                export RESPOND_TO_DM="true"
                export RESPOND_TO_EDITED="true"
                ;;
            hipchat)
                [[ ${bot_rooms,,} == "all" ]] && bot_rooms="All"
                export HUBOT_HIPCHAT_ROOMS=${bot_rooms}
                ;;
        esac
    fi
}

set_config_options
# For troubleshooting:
# echo "obase=2; ${selected_options}" | bc; exit;

set_variables

fname="${SNAP_USER_COMMON}/.prev_scripts_dir"
touch "${fname}"
prev_scripts_dir=$(cat "${fname}")
while [[ ! -d ${scripts_dir} || ${scripts_dir} != ${homedir}/* ]]
do
    read -ei "${prev_scripts_dir}" -p "[?] Where are ${bot_name}'s behavior scripts located?
    Must point to an existing directory within ${homedir}.
> " scripts_dir
done
mkdir -p ${scripts_dir}
# Ensure we're grabbing the absolute path just in case
scripts_dir=$(readlink -e ${scripts_dir})
printf "${scripts_dir}" > ${fname}

logpath="${local_bot_dir}/${bot_name}.log"
deploy_bot
cd "${local_bot_dir}"

echo "[*] Releasing ${bot_name}..."
./bin/hubot -a ${adapter} --name ${local_bot_dir} --alias ${bot_name} --require ${scripts_dir} --disable-httpd &> "${logpath}" &

IFS=$'\n'
delay=10
echo "[*] Observing ${bot_name}'s behavior... Please wait ${delay} seconds"
for i in $(seq 1 ${delay})
do
    sleep 1
    errors=($(cat "${logpath}" | grep -i error))
done

[[ -n ${errors} ]] && warn_error "${errors[@]}"
exit_if_running "[+] ${bot_name} is now running wild on ${engine}!"
echo "[-] ${bot_name} has not been activated!"
exit 1

