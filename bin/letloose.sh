#! /bin/bash

# TODO script templates (use --require hubot flag?)

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

if [[ ${EUID} == 0 ]]
then
    echo "[-] This command may not be run as root."
    exit
fi

PS3="> "

fname="${SNAP_USER_COMMON}/.prev_bot_name"
touch "${fname}"
prev_bot_name=$(cat "${fname}")
while [[ ! "${bot_name}" =~ ^[-_@.a-zA-Z0-9]{3,64}$ ]]
do
    read -ei "${prev_bot_name}" -p "[?] What is the bot account's user name or ID?
> " bot_name
    which "${bot_name}" && bot_name="" && continue
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
    pid=$(pgrep -f "${bot_id} --alias ${bot_name} -a ${adapter}")
    if [[ -n ${pid} ]]
    then
        msg="${1}"
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
        while [[ ! "${engine_url}" =~ ^https?://[-_#.a-zA-Z0-9:\&?=]{3,64}$ ]]
        do
            IFS=" " read -ei "${prev_url}" -p "[?] What is your ${engine} URL?
> " engine_url
        done
        printf ${engine_url} > ${fname}
        case ${adapter} in
            rocketchat) export ROCKETCHAT_URL=${engine_url};;
            hipchat   ) export HUBOT_HIPCHAT_HOST=${engine_url};;
        esac
        bot_id=$(printf ${engine_url} | sha256sum | head -c 16)
    fi

    if [[ $((${selected_options} & ${token_mask})) > 0 ]]
    then
        read -p "[?] What is your ${engine} bot token?
> " bot_token
        case ${adapter} in
            slack) export HUBOT_SLACK_TOKEN=${bot_token};;
        esac
        bot_id=$(printf ${bot_token} | sha256sum | head -c 16)
        unset bot_token
    fi

    local_bot_dir="${SNAP_USER_COMMON}/${bot_name}/${bot_id}"
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
        while [[ ! "${bot_rooms}" =~ ^[-_,a-zA-Z0-9]{3,64}$ ]]
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


logpath="${local_bot_dir}/${bot_name}.log"
cp -frs ${SNAP}/chatbot/* "${local_bot_dir}" > /dev/null

function warn_error {
    msg=("$@")
    echo "[!] Something's not right..."
    [[ -n ${msg} ]] && printf '[!] %s\n' "${msg[@]}"
    echo "[*] Please check ${logpath} for more details."
    echo "[-] ${bot_name} is inactive!"
}

cd "${local_bot_dir}"

echo "[*] Running checks on ${bot_name}..."
./bin/hubot --config-check -a "${adapter}" --disable-httpd &> "${logpath}"
if [[ $? != 0 ]]
then
    echo "[!] Checks failed! Please check ${logpath} for details."
    echo "[-] Aborted!"
    exit
fi

echo "[*] Releasing ${bot_name}..."
./bin/hubot --name "${local_bot_dir}" --alias "${bot_name}" -a "${adapter}" --disable-httpd &> "${logpath}" &

IFS=$'\n'
echo "[*] Observing ${bot_name}'s behavior..."
for i in {1..5}
do
    sleep 1
    error=($(tail -n 50 "${logpath}" | grep ERROR))
done

exit_if_running "[+] ${bot_name} is active!"

warn_error "${error[@]}"

