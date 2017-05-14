#! /bin/bash

bot_name="chatbot"
bot_dir="${bot_name}"

[[ -d "${bot_dir}" ]] && rm -rf "${bot_dir}"
mkdir -p "${bot_dir}"
cd "${bot_dir}"

initial_adapter="rocketchat"
yo hubot --no-insight --owner="BOTSwana" --description="A wild bot from the BOTSwana Kalahari." --name="${bot_name}" --adapter="${initial_adapter}"

# Additional adapters and scripts (to pre-load dependencies)
desired_packages=(
"hubot-auth"
"hubot-cron-events"
"hubot-diagnostics"
"hubot-discord"
"hubot-help"
"hubot-hipchat"
"hubot-redis-brain"
"hubot-scripts"
"hubot-seen"
"hubot-slack"
"hubot-trello"
)

# Install desired packages
for package in "${desired_packages[@]}"
do
    npm install --save "${package}"
done

# Cleanup scripts
rm ./hubot-scripts.json

default_scripts=(
'['
'  "hubot-diagnostics",'
'  "hubot-help",'
'  "hubot-redis-brain"'
']'
)
printf '%s\n' "${default_scripts[@]}" > ./external-scripts.json

cd ../
cp -r "${bot_dir}" "${SNAPCRAFT_PART_INSTALL}"

