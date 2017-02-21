#! /bin/bash

IFS=$'\n'

proc_ids=($(pgrep -f "hubot \--name chatbot --name"))

for proc_id in "${proc_ids[@]}"
do
    eval $(strings -f "/proc/${proc_id}/environ" | egrep -o "BOTSWANA_DIR=/.+")
    eval $(strings -f "/proc/${proc_id}/environ" | egrep -o "BOTSWANA_NAME=.+")
    echo "${BOTSWANA_NAME} (pid ${proc_id}):"
    strings -f "/proc/${proc_id}/environ" | egrep -o "[A-Z]*(ROCKETCHAT|HIPCHAT|LISTEN)_[^P].+"
    tail -n 5 "${BOTSWANA_DIR}/${BOTSWANA_NAME}.log"
    echo ""
done

