#! /bin/bash

homedir=$(getent passwd "${USER}" | cut -d: -f6)

function abort {
    echo "[!] Aborted!"
    exit 1
}

function require_root {
    if [[ ${EUID} != 0 ]]
    then
        echo "[-] This command must be run as root."
        abort
    fi
}

function require_nonroot {
    if [[ ${EUID} == 0 ]]
    then
        echo "[-] This command may not be run as root."
        abort
    fi
}

function check_authz {
    auth_file="${SNAP_COMMON}/.authorized_users"
    if [[ -z $(egrep "^${EUID}$" ${auth_file}) ]]
    then
        echo "[-] You are not authorized to handle our wild bots!"
        echo "[*] To authorize a user, please run:"
        echo "    sudo snap run botswana.authorize add [uid]"
        abort
    fi
}

function deploy_bot {
    ext="external-scripts.json"
    local_ext="${local_bot_dir}/${ext}"
    local_ext_bak="${local_bot_dir}/${ext}.bak"

    [[ -f ${local_ext} ]] && mv ${local_ext} ${local_ext_bak}

    cp -frs ${SNAP}/chatbot/* "${local_bot_dir}" > /dev/null
    rm ${local_ext}

    if [[ -f ${local_ext_bak} ]]
    then
        mv ${local_ext_bak} ${local_ext}
    else
        cp ${SNAP}/chatbot/${ext} "${local_bot_dir}" > /dev/null
    fi
}

