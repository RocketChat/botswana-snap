#! /bin/bash

source ${SNAP}/bin/common_functions.sh
require_nonroot
check_authz

function usage {
    echo "[*] Usage: snap run botswana.admin <action> [bot_name or PID]"
    echo "[*] Possible actions are:"
    echo "    list - if bot_name/PID is specified, list all bots running by that name/PID"
    echo "             otherwise, list all running bots"
    echo "    stop - if bot_name/PID is specified, stop all bots running by that name/PID"
    echo "             otherwise, stop all running bots"
}

action=${1}
bot_search=${2}

if [[ -z ${action} ]]
then
    echo "[-] No action specified!"
    usage
    abort
fi

   full_rex=""
adapter_rex="[-]a [a-z]{3,32}"
  full_rex+="${adapter_rex} "
    dir_rex="[-]-name [-+/=_@.a-zA-Z0-9]{3,128}"
  full_rex+="${dir_rex} "
   name_rex="[-]-alias [-_@.a-zA-Z0-9]{3,128}"
  full_rex+="${name_rex} "
scripts_rex="[-]-require [-+/=_@.a-zA-Z0-9]{3,128}"
  full_rex+="${scripts_rex}"

IFS=$'\n'
procs=($(pgrep -af "${full_rex}"))
for proc in "${procs[@]}"
do
    proc_id=${proc%% *}
    proc_cmd=${proc#*chatbot }

    bot_name=$(printf ${proc} | egrep -o ${name_rex})
    bot_name=${bot_name#* }

    [[ -n "${bot_search}" && ("${bot_search}" != "${bot_name}" && "${bot_search}" != "${proc_id}") ]] && continue

    bot_adapter=$(printf ${proc} | egrep -o ${adapter_rex})
    bot_adapter=${bot_adapter#* }

    bot_dir=$(printf ${proc} | egrep -o ${dir_rex})
    bot_dir=${bot_dir##*name }
    logpath="${bot_dir}/${bot_name}.log"

    bot_id=${bot_dir##*/}
    bot_url=$(printf ${bot_id} | base64 --decode)

    bot_scripts=$(printf ${proc} | egrep -o ${scripts_rex})
    bot_scripts=${bot_scripts#* }

    case ${action} in
        list)
            echo ">>> ${bot_name} <<<"
            echo "[*] PID     - ${proc_id}"
            echo "[*] Adapter - ${bot_adapter}"
            echo "[*] URL     - ${bot_url}"
            echo "[*] Logs    - ${logpath}"
            echo "[*] Scripts - ${bot_scripts}"
            echo ""
            ;;
        stop)
            kill ${proc_id}
            if [[ $? == 0 ]]
            then
                echo "[+] ${bot_name} deactivated!"
            else
                echo "[-] Could not deactivate ${bot_name} (PID ${proc_id})!"
            fi
            ;;
    esac
done

