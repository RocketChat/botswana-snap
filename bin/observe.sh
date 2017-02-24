#! /bin/bash

IFS=$'\n'
rex="[-]-name [-_@./a-zA-Z0-9]{3,128} --alias [-_@.a-zA-Z0-9]{3,64}"

bot_search=${1}
procs=($(pgrep -af "${rex}"))
for proc in "${procs[@]}"
do
    proc_id=${proc%% *}
    proc_cmd=$(echo "${proc#* }" | egrep -o "${rex}")

    # Grab the local bot directory, excluding the "--name " part...
    bot_dir=${proc_cmd#* }
    # ...then excluding everything up to and including " --alias"
    bot_dir=${bot_dir%% *}

    # Grab just the bot name, excluding everything up to and including "--alias "
    bot_name=${proc_cmd##* }

    [[ -n "${bot_search}" && "${bot_search}" != "${bot_name}" ]] && continue
    echo ">>> ${bot_name} (pid ${proc_id}) <<<"
    logpath="${bot_dir}/${bot_name}.log"
    echo "[*] Log location: ${logpath}"
    if [[ -O ${logpath} ]]
    then
        echo "[*] Connection details:"
        head -n 8 "${logpath}"
        echo "[*] Log tail:"
        tail -n 5 "${logpath}"
    else
        echo "[!] Cannot read log file: belongs to another user!"
    fi
    echo ""
done

