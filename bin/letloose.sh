#! /bin/bash

# TODO check for existing processes! maybe across all users, if possible

PS3="> "
adapter=""
echo "What is your chat engine?"
select engine in "Rocket.Chat" "Slack" "HipChat" "Quit"
do
    case ${engine} in
        Rocket.Chat) adapter="rocketchat"; break;;
        Slack      ) adapter="slack"; break;;
        HipChat    ) adapter="hipchat"; break;;
        Quit       ) exit;;
    esac
done

bot_name=""
while [[ -z ${bot_name} ]]
do
    read -p "What is the bot account's user name or ID?
> " bot_name
done
case ${adapter} in
    rocketchat) export ROCKETCHAT_USER=${bot_name};;
    hipchat   ) export HUBOT_HIPCHAT_JID=${bot_name};;
esac

pid=$(pgrep -f "\--name ${bot_name} -a ${adapter}")
if [[ -n ${pid} ]]
then
    echo "${bot_name} is already running wild on ${engine}!"
    echo "If you wish to make changes, please halt the bot by issuing:"
    echo "kill ${pid}"
    exit
fi

selected_options=2#00000000
        url_mask=2#00000001
   password_mask=2#00000010
      token_mask=2#00000100
 join_rooms_mask=2#00001000
#    unused_mask=2#00010000
#    unused_mask=2#00100000
#    unused_mask=2#01000000
#    unused_mask=2#10000000

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

# For troubleshooting:
# echo "obase=2; ${selected_options}" | bc; exit;

function set_variables {
    if [[ $((${selected_options} & ${url_mask})) > 0 ]]
    then
        read -p "What is your ${engine}'s URL?
> " engine_url
        case ${adapter} in
            rocketchat) export ROCKETCHAT_URL=${engine_url};;
            hipchat   ) export HUBOT_HIPCHAT_HOST=${engine_url};;
        esac
    fi

    if [[ $((${selected_options} & ${password_mask})) > 0 ]]
    then
        read -s -p "What is the bot account's password?
It will not be displayed as you type.
> " bot_password
        echo ""
        case ${adapter} in
            rocketchat) export ROCKETCHAT_PASSWORD=${bot_password};;
            hipchat   ) export HUBOT_HIPCHAT_PASSWORD=${bot_password};;
        esac
        bot_password=""
    fi

    if [[ $((${selected_options} & ${token_mask})) > 0 ]]
    then
        read -p "What is your ${engine} bot token?
> " bot_token
        case ${adapter} in
            slack) export HUBOT_SLACK_TOKEN=${bot_token};;
        esac
        bot_token=""
    fi

    if [[ $((${selected_options} & ${join_rooms_mask})) > 0 ]]
    then
        read -p "Which channel(s) should the bot automatically join?
Separate multiple channels with commas; type \"all\" for all public channels.
> " bot_rooms
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


set_variables

done="no"
while [[ $done == "no" ]]
do
    selected_options=2#00000000
    change_url="Change URL (${engine_url})"
    change_rooms="Change rooms (${bot_rooms})"
    echo "Please confirm:"
    select option in "${change_url}" "${change_rooms}" "Done"
    do
        case ${option} in
            ${change_url})
                selected_options=$((${selected_options} | ${url_mask}))
                set_variables
                break;;
            ${change_rooms})
                selected_options=$((${selected_options} | ${join_rooms_mask}))
                set_variables
                break;;
            Done)
                done="yes"
                break;;
        esac
    done
done

# TODO this logic flow should include the ability to reconfigure any options previously chosen
# before actually running the bot (perhaps after presenting a config summary)
# it should also allow modification of loaded options from the config file (see notes at the bottom of this file)

# TODO help options with details explanations for each adapter


# TODO detect existing, load config file, then overwrite (or ask for overwrite in the first place)
local_bot_dir="${SNAP_USER_COMMON}/${bot_name}/"
mkdir -p "${local_bot_dir}"
cp -frs ${SNAP}/chatbot/* "${local_bot_dir}" > /dev/null
cd "${local_bot_dir}"

# TODO pipe this output to a log file
# TODO come up with a way to detect whether this actually started ok
# if not, tell the user to retry? Try to detect what happened?
bin/hubot --name "${bot_name}" -a "${adapter}" &> "${local_bot_dir}/${bot_name}.log" &

# TODO save a config file for the bot
# that way, if someone specifies an existing bot name,
# they can simply reconfigure it rather than overwrite it

