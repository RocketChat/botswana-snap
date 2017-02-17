#! /bin/bash

# TODO check for existing processes! maybe across all users, if possible

adapter=""
echo "What is your chat engine?"
select engine in "Rocket.Chat" "Slack" "HipChat" "Quit"
do
    case $engine in
        Rocket.Chat) adapter="rocketchat"; break;;
        Slack      ) adapter="slack"; break;;
        HipChat    ) adapter="hipchat"; break;;
        Quit       ) exit;;
    esac
done

selected_options=2#00000000
        url_mask=2#00000001
  auth_type_mask=2#00000010
   password_mask=2#00000100
      token_mask=2#00001000
 join_rooms_mask=2#00010000
#    unused_mask=2#00100000
#    unused_mask=2#01000000
#    unused_mask=2#10000000

case $adapter in
    rocketchat)
        selected_options=$(($selected_options | $auth_type_mask))
        selected_options=$(($selected_options | $url_mask))
        selected_options=$(($selected_options | $password_mask))
        selected_options=$(($selected_options | $join_rooms_mask))
        ;;
    hipchat)
        selected_options=$(($selected_options | $url_mask))
        selected_options=$(($selected_options | $password_mask))
        selected_options=$(($selected_options | $join_rooms_mask))
        ;;
    slack)
        selected_options=$(($selected_options | $token_mask))
esac

# For troubleshooting:
# echo "obase=2; $selected_options" | bc; exit;

function set_variables {
    # We need a name for the bot in all cases
    bot_name=""
    while [[ -z $bot_name ]]
    do
        read -p "What is the bot account's user name or ID?
> " bot_name
    done
    case $adapter in
        rocketchat) export ROCKETCHAT_USER=$bot_name;;
        hipchat   ) export HUBOT_HIPCHAT_JID=$bot_name;;
    esac

    if [[ $(($selected_options & $url_mask)) > 0 ]]
    then
        answer=""
        read -p "What is your ${engine}'s URL?
> " answer
        case $adapter in
            rocketchat) export ROCKETCHAT_URL=$answer;;
            hipchat   ) export HUBOT_HIPCHAT_HOST=$answer;;
        esac
    fi

    if [[ $(($selected_options & $auth_type_mask)) > 0 ]]
    then
        answer=""
        echo "What authentication type does your $engine utilize?"
        select pl in "Password" "LDAP"
        do
            case $pl in
                Password) answer="password"; break;;
                LDAP    ) answer="ldap"; break;;
            esac
        done
        case $adapter in
            rocketchat) export ROCKETCHAT_AUTH=$answer;;
        esac
    fi

    if [[ $(($selected_options & $password_mask)) > 0 ]]
    then
        answer=""
        read -s -p "What is the bot account's password?
> " answer
        echo ""
        case $adapter in
            rocketchat) export ROCKETCHAT_PASSWORD=$answer;;
            hipchat   ) export HUBOT_HIPCHAT_PASSWORD=$answer;;
        esac
    fi

    if [[ $(($selected_options & $token_mask)) > 0 ]]
    then
        answer=""
        read -p "What is your $engine bot token?
> " answer
        case $adapter in
            slack) export HUBOT_SLACK_TOKEN=$answer;;
        esac
    fi

    if [[ $(($selected_options & $join_rooms_mask)) > 0 ]]
    then
        answer=""
        read -p "In which channel(s) should the bot listen and respond?
Separate multiple channels with commas.
> " answer
        case $adapter in
            rocketchat) export ROCKETCHAT_ROOM=$answer;;
            hipchat   ) export HUBOT_HIPCHAT_ROOMS=$answer;;
        esac
    fi
}

set_variables

# TODO this logic flow should include the ability to reconfigure any options previously chosen
# before actually running the bot (perhaps after presenting a config summary)
# it should also allow modification of loaded options from the config file (see notes at the bottom of this file)

# TODO help options with details explanations for each adapter


# TODO detect existing, load config file, then overwrite (or ask for overwrite in the first place)
local_bot_dir=$SNAP_USER_COMMON/$bot_name/
mkdir -p $local_bot_dir
cp -rsu $SNAP/chatbot/* $local_bot_dir > /dev/null
cd $local_bot_dir

# TODO pipe this output to a log file
# TODO come up with a way to detect whether this actually started ok
# if not, tell the user to retry? Try to detect what happened?
bin/hubot --name $bot_name -a $adapter &> /dev/null &

# TODO save a config file for the bot
# that way, if someone specifies an existing bot name,
# they can simply reconfigure it rather than overwrite it

