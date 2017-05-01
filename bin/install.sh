#! /bin/bash

bot_name="chatbot"
bot_dir="${bot_name}"

[[ -d "${bot_dir}" ]] && rm -rf "${bot_dir}"
mkdir -p "${bot_dir}"
cd "${bot_dir}"

initial_adapter="rocketchat"
yo hubot --no-insight --owner="BOTSwana" --description="A wild bot from the BOTSwana Kalahari." --name="${bot_name}" --adapter="${initial_adapter}"

additional_adapters=(
"hubot-discord"
"hubot-hipchat"
"hubot-slack"
)

# Install adapters
for adapter in "${additional_adapters[@]}"
do
    npm install --save "${adapter}"
done

# Cleanup scripts
rm ./hubot-scripts.json

default_scripts=(
'['
'  "hubot-diagnostics",'
'  "hubot-help"'
']'
)
printf '%s\n' "${default_scripts[@]}" > ./external-scripts.json

cd ../
cp -r "${bot_dir}" "${SNAPCRAFT_PART_INSTALL}"

