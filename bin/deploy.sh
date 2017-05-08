#! /bin/bash

source ${SNAP}/bin/common_functions.sh
require_nonroot
check_authz

local_bot_dir=${1}

if [[ -d ${local_bot_dir} && ${local_bot_dir} == ${homedir}/* ]]
then
    deploy_bot
    echo "[+] Bot successfully deployed!"
    echo "[*] Execute the following command with desired options to run your bot:"
    echo "    cd ${local_bot_dir} && env PATH=\${PATH}:/snap/botswana/current/bin ./bin/hubot"
else
    echo "[-] Invalid or inexistent directory!"
    echo "[*] Usage: snap run botswana.deploy <target_directory>"
    echo "    Please note that the target directory must be within ${homedir}"
    abort
fi

