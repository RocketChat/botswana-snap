#! /bin/bash

source ${SNAP}/bin/common_functions.sh
require_root

auth_file="${SNAP_COMMON}/.authorized_users"
touch "${auth_file}"

function on_exit {
    chmod 004 "${auth_file}"
}
trap on_exit EXIT

function usage {
    echo "[*] Usage: sudo snap run botswana.authorize <action> [uid]"
    echo "[*] Possible actions are:"
    echo "    add         - add uid to the list of authorized users"
    echo "    remove, rm  - remove uid from the list of authorized users"
    echo "    delete, del - same as remove"
    echo "    list        - list all users present in the list of authorized users"
    echo "    purge       - remove all uids from the list of authorized users"
    echo "    Note: only the 'list' and 'purge' actions may be used without a uid"
}

action=${1}
uid=${2}

if [[ -z ${action} ]]
then
    echo "[-] No action specified!"
    usage
    abort
fi

if [[ -n ${uid} && ( ! ${uid} =~ [0-9]{1,8} || -z $(id "${uid}") ) ]]
then
    echo "[-] Invalid uid or user does not exist!"
    abort
fi

chmod 600 "${auth_file}"

# Overwrite if purging or if file has no size
[[ ${action} == "purge" || ! -s "${auth_file}" ]] && echo "# BOTSwana authorized users" > "${auth_file}"

# Exit if purging or listing
[[ ${action} == "purge" ]] && exit 0
if [[ ${action} == "list" ]]
then
    while read line
    do
        [[ -z ${line} || ${line} == \#* ]] && continue
        echo "(${line}) $(id -u -n ${line})"
    done < ${auth_file}
    exit 0
fi

# If not purging or listing, we need a uid!
if [[ -z ${uid} ]]
then
    echo "[-] No uid specified for add/remove action!"
    usage
    abort
fi

[[ ${action} =~ del|delete|rm|remove ]] && sed -i -e "/${uid}/d" ${auth_file}
[[ ${action} == "add" ]] && sed -i -e "s/${uid}/${uid}/" -e t -e "$ a ${uid}" ${auth_file}

