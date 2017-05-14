# BOTSwana: the [Kalahari](https://en.wikipedia.org/wiki/Central_Kalahari_Game_Reserve) of bots

Run as many bots as you want, with as many chats (Rocket.Chat,  Slack, HipChat, and more...) as you want, painlessly!

BOTSwana enables you to develop, test, manage and run fleets of bots right on your Linux system.

You no longer have to struggle with installing complex bot runtime; or give up privacy and pay dearly for bot SaaS.  

Leverage the connectivity, storage, and multi-core computing power of your Linux system to manage and run tens (or hundreds!) of bots simultaneously.

_*Unleash your personal Kalahari of Bots with BOTSwana TODAY !!*_

# Installation
Until BOTSwana is officially registered at the snap store, download the latest snap file for your architecture and run:  
`sudo snap install botswana_x.x.x_arch.snap --dangerous`

# Authorizing users
Users must first be authorized to deploy and administer bots using BOTSwana. The root user can authorize other users by running:  
`sudo snap run botswana.authorize add 1000`, replacing `1000` with the desired user ID.

To discover your regular user ID, simply run:  
`id`

Sample output:  
`uid=1000(my_user) ...`

## Command reference for botswana.authorize
```
[*] Usage: sudo snap run botswana.authorize <action> [uid]
[*] Possible actions are:
    add         - add uid to the list of authorized users
    remove, rm  - remove uid from the list of authorized users
    delete, del - same as remove
    list        - list all users present in the list of authorized users
    purge       - remove all uids from the list of authorized users
    Note: only the 'list' and 'purge' actions may be used without a uid
```

# Deploying bots
## Interactively
Simply run `snap run botswana.letloose` and follow the prompts!

## Automated deployment
For greater control over your bot, or to control it via scripts:
- Create a directory where to store the bot files; e.g.:  
`mkdir /home/user/mybot`
- Execute the following command, replacing `/home/user/mybot` with the directory you created:  
`snap run botswana.deploy /home/user/mybot`

Sample output:
```
[+] Bot successfully deployed!
[*] Edit, then execute the following file to configure and launch your bot:
    /home/user/mybot/launch.sh
```

Finally, edit the `launch.sh` file to add the desired configuration, then execute it to run your bot as a background process.

# Administering deployed bots
## Listing active bots
To list all active bots, run:  
`snap run botswana.admin list`

### Queries
To find specific bots that may be active, boolean queries are available.

Available query parameters are:
- NAME
- ADAPTER

Available query connectors are:
- IS
- ISNT
- AND
- OR

Examples:
```
# Find all active bots by the name "mybot":
snap run botswana.admin list NAME IS mybot

# Find all active bots by the name "mybot" and adapter "rocketchat":
snap run botswana.admin list NAME IS mybot AND ADAPTER IS rocketchat

# Find all active bots except ones whose adapter is "rocketchat":
snap run botswana.admin list ADAPTER ISNT rocketchat

# For more complex boolean queries, surround the entire query in quotes to allow the use of parentheses.
# Find all active bots except ones named "mybot", unless their adapter is "rocketchat":
snap run botswana.admin list "NAME ISNT mybot OR (NAME IS mybot AND ADAPTER IS rocketchat)"
```

## Deactivating bots
To stop all active bots, run:  
`snap run botswana.admin stop`

### Please note
Bots deployed via `snap run botswana.deploy` cannot be stopped with this command.

### Queries
To stop specific bots, boolean queries are available.

Available query parameters are:
- NAME
- ADAPTER

Available query connectors are:
- IS
- ISNT
- AND
- OR

Examples:
```
# Stop all active bots by the name "mybot":
snap run botswana.admin stop NAME IS mybot

# Stop all active bots by the name "mybot" and adapter "rocketchat":
snap run botswana.admin stop NAME IS mybot AND ADAPTER IS rocketchat

# Stop all active bots except ones whose adapter is "rocketchat":
snap run botswana.admin stop ADAPTER ISNT rocketchat

# For more complex boolean queries, surround the entire query in quotes to allow the use of parentheses.
# Stop all active bots except ones named "mybot", unless their adapter is "rocketchat":
snap run botswana.admin stop "NAME ISNT mybot OR (NAME IS mybot AND ADAPTER IS rocketchat)"
```

## Checking bot logs
To check the logs for a single bot, simply run:  
`snap run botswana.admin diag`  
This will show the logs of the first bot process found by BOTSwana.

If multiple bots are active, use precise queries to select the desired bot:
```
# View logs for bot named "mybot" whose adapter is "rocketchat":
snap run botswana.admin diag NAME IS mybot AND ADAPTER IS rocketchat
```

Piping this command to `less` may be useful:  
`snap run botswana.admin diag | less`

## Command reference for botswana.admin
```
[*] Usage: snap run botswana.admin <action> [bot_name or PID]
[*] Possible actions are:
    list [query] - if [query] is omitted, list all running bots;
                   otherwise, list running bots filtered by [query].
    diag [query] - If [query] is omitted, show the logs for the first active bot found;
                   otherwise, show the logs for the first active bot found via [query].
    stop [query] - if [query] is omitted, stop all running bots;
                   otherwise, stop running bots filtered by [query].

    Query parameters: NAME, ADAPTER
    Query connectors: IS, ISNT, AND, OR
    Query example: "NAME IS mybot AND ADAPTER IS rocketchat"
```

## Adding scripts
### Globally
Using `snap run botswana.letloose` gives you the ability to choose a scripts directory. E.g.:
```
[?] Where are guy_chapman's behavior scripts located?
    Must point to an existing directory within /home/user.
    > /home/user/scripts
```

Therefore, every bot deployed which uses that directory for its scripts will load the same scripts therein contained.

Using `snap run botswana.deploy` gives you the same ability by specifying the scripts directory within the configuration section of `launch.sh`:
```
# If desired, change to a directory where to look for additional scripts
# ./scripts will still be utilized regardless of this setting
scripts_dir="/home/user/scripts"
```

### Individually
Using `snap run botswana.letloose` creates an accessible directory where only this particular bot will look for scripts.

To learn the location of that directory, run:  
`snap run botswana.admin list`

Sample output:
```
>>> mybot <<<
[*] PID     - 12345
[*] Adapter - rocketchat
[*] URL     - https://mychat.com
[*] Home    - /home/user/snap/botswana/common/mybot/aHR0cHM6Ly9teWNoYXQuY29t
[*] Scripts - /home/user/scripts
```

Note the bot's Home directory:  
`[*] Home    - /home/user/snap/botswana/common/mybot/aHR0cHM6Ly9teWNoYXQuY29t`

That directory will contain a scripts directory where only this bot will look for scripts:  
`/home/user/snap/botswana/common/mybot/aHR0cHM6Ly9teWNoYXQuY29t/scripts`

Using `snap run botswana.deploy` creates the bot directory at the specified location, such as:  
`snap run botswana.deploy /home/user/mybot`

In that case, the individual scripts directory will simply be:  
`/home/user/mybot/scripts`

# Redis
BOTSwana automatically spawns a [Redis](https://redis.io/topics/introduction) server, by default only accessible locally, for quick and somewhat persistent storage for all bots.

## Configuration
A sample configuration file is included and accessible at:  
`/var/snap/botswana/current/redis/redis.conf`

To modify Redis' configuration, first stop the service by running:  
`sudo service snap.botswana.redis-server stop`

Then, modify `/var/snap/botswana/current/redis/redis.conf` and start the service:  
`sudo service snap.botswana.redis-server start`

## Administration
To check the status of the embedded Redis server:  
`sudo service snap.botswana.redis-server status`

To restart it:  
`sudo service snap.botswana.redis-server restart`

To check its logs (assuming default configuration):  
`cat /var/snap/botswana/current/redis/redis.log`

