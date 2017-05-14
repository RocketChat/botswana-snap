#! /bin/bash

source ${SNAP}/bin/common_functions.sh
require_nonroot
check_authz

local_bot_dir=${1}

launch=$(cat <<END
#! /bin/bash

############################### Configuration ###############################

# Rocket.Chat
# export ROCKETCHAT_URL=""
# export ROCKETCHAT_USER=""
# export ROCKETCHAT_PASSWORD=""
# export ROCKETCHAT_ROOM=""
# export LISTEN_ON_ALL_PUBLIC=true
# export RESPOND_TO_DM=true
# export RESPOND_TO_EDITED=true

# Discord
# export HUBOT_DISCORD_TOKEN

# HipChat
# export HUBOT_HIPCHAT_JID
# export HUBOT_HIPCHAT_PASSWORD
# export HUBOT_HIPCHAT_ROOMS

# Slack
# export HUBOT_SLACK_TOKEN

# One of: rocketchat, discord, hipchat, slack
adapter=""

# The name to which this bot will respond
bot_name=""

# If desired, change to a directory where to look for additional scripts
# ./scripts will still be utilized regardless of this setting
scripts_dir="${local_bot_dir}/scripts"

#############################################################################


cd ${local_bot_dir}
logpath="${local_bot_dir}/\${bot_name}.log"
env PATH=\${PATH}:/snap/botswana/current/bin ./bin/hubot -a \${adapter} --name ${local_bot_dir} --alias \${bot_name} --require \${scripts_dir} --disable-httpd &> "\${logpath}" &
END
)

launch_path="${local_bot_dir}/launch.sh"
if [[ -d ${local_bot_dir} && ${local_bot_dir} == ${homedir}/* ]]
then
    deploy_bot
    [[ ! -f ${launch_path} ]] && echo "${launch}" > ${launch_path} && chmod 700 ${launch_path}
    echo "[+] Bot successfully deployed!"
    echo "[*] Edit, then execute the following file to configure and launch your bot:"
    echo "    ${local_bot_dir}/launch.sh"
else
    echo "[-] Invalid or inexistent directory!"
    echo "[*] Usage: snap run botswana.deploy <target_directory>"
    echo "    Please note that the target directory must be within ${homedir}"
    abort
fi

