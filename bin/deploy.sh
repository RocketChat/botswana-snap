#! /bin/bash

source ${SNAP}/bin/common_functions.sh
require_nonroot
check_authz

local_bot_dir=${1}

homedir=$(getent passwd "${USER}" | cut -d: -f6)
if [[ -d ${local_bot_dir} && ${local_bot_dir} == ${homedir}/* ]]
then
    cp -frs ${SNAP}/chatbot/* "${local_bot_dir}" > /dev/null
    echo "env PATH=\${PATH}:/snap/botswana/current/bin ${local_bot_dir}/bin/hubot"
else
    echo "[-] Invalid or inexistent directory!"
    echo "[*] Usage: snap run botswana.deploy <target_directory>"
    echo "    Please note that the target directory must be within ${homedir}"
    abort
fi

