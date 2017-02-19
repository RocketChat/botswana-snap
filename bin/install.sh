#! /bin/bash

# TODO clean up scripts, leaving only local and future-proof ones
bot_name="chatbot"
bot_dir="${bot_name}"

[[ -d "${bot_dir}" ]] && rm -rf "${bot_dir}"
mkdir -p "${bot_dir}" && cd "${bot_dir}"

initial_adapter="rocketchat"
yo hubot --no-insight --owner="BOTSwana" --description="A wild bot from the BOTSwana Kalahari." --name="${bot_name}" --adapter="${initial_adapter}"

additional_adapters=(
"hubot-slack"
"hubot-hipchat"
)

# Install adapters
for adapter in "${additional_adapters[@]}"
do
    npm install "${adapter}" --save
done

cd ../
cp -r "${bot_dir}" "${SNAPCRAFT_PART_INSTALL}"

