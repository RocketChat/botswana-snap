#! /bin/bash

# TODO script templates

function on_exit {
    unset HUBOT_HIPCHAT_HOST
    unset HUBOT_HIPCHAT_JID
    unset HUBOT_HIPCHAT_PASSWORD
    unset HUBOT_HIPCHAT_ROOMS
    unset HUBOT_SLACK_TOKEN
    unset LISTEN_ON_ALL_PUBLIC
    unset ROCKETCHAT_PASSWORD
    unset ROCKETCHAT_ROOM
    unset ROCKETCHAT_URL
    unset ROCKETCHAT_USER
}
trap on_exit EXIT

PS3="> "

fname="${SNAP_USER_COMMON}/.prev_bot_name"
touch "${fname}"
prev_bot_name=$(cat "${fname}")
# TODO use which here maybe?
while [[ ! ${bot_name} =~ ^[a-zA-Z0-9_-]{3,16}$ ]]
do
    read -ei "${prev_bot_name}" -p "[?] What is the bot account's user name or ID?
> " bot_name
done
printf "${bot_name}" > ${fname}

echo "[?] What is your chat engine?"
select engine in "Rocket.Chat" "Slack" "HipChat"
do
    case ${engine} in
        Rocket.Chat)
            adapter="rocketchat"
            export ROCKETCHAT_USER=${bot_name}
            break;;
        Slack)
            adapter="slack"
            break;;
        HipChat)
            adapter="hipchat"
            export HUBOT_HIPCHAT_JID=${bot_name}
            break;;
    esac
done

        url_mask=2#00000001
   password_mask=2#00000010
      token_mask=2#00000100
 join_rooms_mask=2#00001000
#    unused_mask=2#00010000
#    unused_mask=2#00100000
#    unused_mask=2#01000000
#    unused_mask=2#10000000

function set_config_options {
    selected_options=2#00000000
    case ${adapter} in
        rocketchat)
            selected_options=$((${selected_options} | ${url_mask}))
            selected_options=$((${selected_options} | ${password_mask}))
            selected_options=$((${selected_options} | ${join_rooms_mask}))
            ;;
        hipchat)
            selected_options=$((${selected_options} | ${url_mask}))
            selected_options=$((${selected_options} | ${password_mask}))
            selected_options=$((${selected_options} | ${join_rooms_mask}))
            ;;
        slack)
            selected_options=$((${selected_options} | ${token_mask}))
    esac
}

function exit_if_running {
    msg=${1}
    pid=$(pgrep -f "\--name ${proc_id} -a ${adapter}")
    if [[ -n ${pid} ]]
    then
        echo "[!] ${bot_name} is happily running wild on ${engine}!"
        echo "[*] Prior to making further changes, please tranquilize ${bot_name} by running:"
        echo "    kill ${pid} (sounds lethal, but it's not)"
        [[ -n ${msg} ]] && echo "${msg}"
        exit
    fi
}

function set_variables {
    if [[ $((${selected_options} & ${url_mask})) > 0 ]]
    then
        fname="${SNAP_USER_COMMON}/${bot_name}/.prev_url"
        mkdir -p $(dirname ${fname})
        touch ${fname}
        prev_url=$(cat "${fname}")
        # TODO finish this URL input validation, then finish the rest
        while [[ ! ${engine_url} =~ ^https?://[]]
        do
            IFS=" " read -ei "${prev_url}" -p "[?] What is your ${engine} URL?
> " engine_url
        done
        printf ${engine_url} > ${fname}
        case ${adapter} in
            rocketchat) export ROCKETCHAT_URL=${engine_url};;
            hipchat   ) export HUBOT_HIPCHAT_HOST=${engine_url};;
        esac
        proc_id=$(printf ${engine_url} | sha256sum | head -c 16)
    fi

    if [[ $((${selected_options} & ${token_mask})) > 0 ]]
    then
        read -p "[?] What is your ${engine} bot token?
> " bot_token
        case ${adapter} in
            slack) export HUBOT_SLACK_TOKEN=${bot_token};;
        esac
        proc_id=$(printf ${bot_token} | sha256sum | head -c 16)
        unset bot_token
    fi

    local_bot_dir="${SNAP_USER_COMMON}/${bot_name}/${proc_id}"
    mkdir -p "${local_bot_dir}"
    exit_if_running

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
        read -ei "${prev_rooms}" -p "[?] Which channel(s) should ${bot_name} automatically join?
Separate multiple channels with commas; enter \"all\" for all public channels.
> " bot_rooms
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


logname="${local_bot_dir}/${bot_name}.log"
cp -frsv ${SNAP}/chatbot/* "${local_bot_dir}" > ${logname}

function warn_error {
    msg=("$@")
    echo "[!] Something's not right..."
    [[ -n ${msg} ]] && printf '[!] %s\n' "${msg[@]}"
    echo "[*] Please check ${logname} for more details."
    echo "[-] ${bot_name} is inactive!"
}

cd "${local_bot_dir}"
env BOTSWANA_DIR="${local_bot_dir}" BOTSWANA_NAME="${bot_name}" ./bin/hubot --name "${proc_id}" -a "${adapter}" &>> "${local_bot_dir}/${bot_name}.log" &

IFS=$'\n'
echo "[*] Observing ${bot_name}'s behavior in ${engine}..."
for i in {1..5}
do
    sleep 1
    error=($(tail -n 50 ${logname} | grep ERROR))
done

exit_if_running "[+] ${bot_name} is active!"

warn_error "${error[@]}"

