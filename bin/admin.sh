#! /bin/bash

source ${SNAP}/bin/common_functions.sh
require_nonroot
check_authz

function usage {
    echo "[*] Usage: snap run botswana.admin <action> [bot_name or PID]"
    echo "[*] Possible actions are:"
    echo "    list [query] - if [query] is omitted, list all running bots;"
    echo "                   otherwise, list running bots filtered by [query]."
    echo "    diag [query] - If [query] is omitted, show the logs for the first active bot found;"
    echo "                   otherwise, show the logs for the first active bot found via [query]."
    echo "    stop [query] - if [query] is omitted, stop all running bots;"
    echo "                   otherwise, stop running bots filtered by [query]."
    echo ""
    echo "    Query parameters: NAME, ADAPTER"
    echo "    Query connectors: IS, ISNT, AND, OR"
    echo "    Query example: \"NAME IS mybot AND ADAPTER IS rocketchat\""
}

action=${1}
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

    bot_adapter=$(printf ${proc} | egrep -o ${adapter_rex})
    bot_adapter=${bot_adapter#* }

    shift
    bot_search=("$@")
    for term in "${bot_search[@]}"
    do
        which ${term} &> /dev/null && echo "[-] Invalid search terms!" && abort
    done

    # Make it a string for replacements and eval command
    bot_search="${bot_search[@]}"

    if [[ -n ${bot_search} ]]
    then
        bot_search=${bot_search//"AND"/"&&"}
        bot_search=${bot_search//"OR"/"||"}
        bot_search=${bot_search//"ISNT"/"!="}
        bot_search=${bot_search//"IS"/"=="}
        bot_search=${bot_search//"NAME"/"${bot_name}"}
        bot_search=${bot_search//"ADAPTER"/"${bot_adapter}"}
        eval "[[ ! (${bot_search}) ]] && continue"
    fi

    bot_dir=$(printf ${proc} | egrep -o ${dir_rex})
    bot_dir=${bot_dir##*name }
    logpath="${bot_dir}/${bot_name}.log"

    bot_id=${bot_dir##*/}
    bot_url=$(printf ${bot_id} | base64 --decode 2> /dev/null)
    [[ $? != 0 ]] && bot_url="Unable to retrieve (likely due to deployment via botswana.deploy)"

    bot_scripts=$(printf ${proc} | egrep -o ${scripts_rex})
    bot_scripts=${bot_scripts#* }

    case ${action} in
        list)
            echo ">>> ${bot_name} <<<"
            echo "[*] PID     - ${proc_id}"
            echo "[*] Adapter - ${bot_adapter}"
            echo "[*] URL     - ${bot_url}"
            echo "[*] Home    - ${bot_dir}"
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
        diag)
            cat "${logpath}"
            exit 0
            ;;
    esac
done

