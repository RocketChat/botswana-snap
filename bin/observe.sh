#! /bin/bash

IFS=$'\n'
rex="[-]-name chatbot --name [-_@./a-zA-Z0-9]{3,128}"

proc_ids=($(pgrep -f "${rex}"))

bot_search=${1}

for proc_id in "${proc_ids[@]}"
do
    name_id=$(ps -au | grep "${proc_id}" | egrep -o "${rex}")
    name_id=${name_id##* }
    bot_name=${name_id%/*}
    bot_id=${name_id#*/}
    [[ -n "${bot_search}" && "${bot_search}" != "${bot_name}" ]] && continue
    echo "--- ${bot_name} (pid ${proc_id}) ---"
    logpath="${SNAP_USER_COMMON}/${bot_name}/${bot_id}/${bot_name}.log"
    echo "[*] Log location: ${logpath}"
    echo "[*] Connection details:"
    head -n 8 "${logpath}"
    echo "[*] Log tail:"
    tail -n 5 "${logpath}"
    echo ""
done

