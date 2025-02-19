#!/bin/bash
#######################################################
#
#        File: mycommands.sh.clean
#
# copy to mycommands.sh and add all your commands and functions here ...
#
#       Usage: will be executed when a bot command is received 
#
#     License: WTFPLv2 http://www.wtfpl.net/txt/copying/
#      Author: KayM (gnadelwartz), kay@rrr.de
#
#### $$VERSION$$ v1.52-1-g0dae2db
#######################################################
# shellcheck disable=SC1117

####################
# Config has moved to bashbot.conf
# shellcheck source=./commands.sh
[ -r "${BASHBOT_ETC:-.}/mycommands.conf" ] && source "${BASHBOT_ETC:-.}/mycommands.conf"  "$1"


##################
# lets's go
if [ "$1" = "startbot" ];then
    ###################
    # this section is processed on startup

    # run once after startup when the first message is received
    my_startup(){
        :
    }
    touch .mystartup
else
    # call my_startup on first message after startup
    # things to do only once
    [ -f .mystartup ] && rm -f .mystartup && _exec_if_function my_startup

    #############################
    # your own bashbot commands
    # NOTE: command can have @botname attached, you must add * to case tests...
    mycommands() {

    ##############
    # a service Message was received
    # add your own stuff here
    if [ -n "${SERVICE}" ]; then
        # example: delete every service message
        if [ "${SILENCER}" = "yes" ]; then
            delete_message "${CHAT[ID]}" "${MESSAGE[ID]}"
        fi
    fi

    # remove keyboard if you use keyboards
    [ -n "${REMOVEKEYBOARD}" ] && remove_keyboard "${CHAT[ID]}" &
    [[ -n "${REMOVEKEYBOARD_PRIVATE}" &&  "${CHAT[ID]}" == "${USER[ID]}" ]] && remove_keyboard "${CHAT[ID]}" &

    # uncommet to fix first letter upper case because of smartphone auto correction
    #[[ "${MESSAGE}" =~  ^/[[:upper:]] ]] && MESSAGE="${MESSAGE:0:1}$(tr '[:upper:]' '[:lower:]' <<<"${MESSAGE:1:1}")${MESSAGE:2}"
    case "${MESSAGE}" in
        ##########
        # command overwrite examples
        # return 0 -> run default command afterwards
        # return 1 -> skip possible default commands
        '/info '*) # output date in front of regular info
            send_normal_message "${CHAT[ID]}" "$(date)"
            return 0
            ;;

        '/start')
            send_normal_message "${CHAT[ID]}" "$(fastfetch --logo none)"
            return 1
            ;;

        '/cw '*)
            collectd-web ${MESSAGE#/cw } | while read P; do
                [[ $P =~ ^/ ]] && send_file "${CHAT[ID]}" $P && rm $P || echo $P
            done | send_normal_message "${CHAT[ID]}" "$(cat)"
            return 1
            ;;

        *)
            send_normal_message "${CHAT[ID]}" "$(msg_as_cmd "${MESSAGE}")"
            return 1
            ;;
    esac
    
    } # mycommands()

    #######################
    # callbacks from buttons attached to messages will be  processed here
    mycallbacks() {
    
    case "${iBUTTON[USER_ID]}+${iBUTTON[CHAT_ID]}" in
        *)  # all other callbacks are processed here
            local callback_answer
            : # your processing here ...
            :
            # Telegram needs an ack each callback query, default empty
            answer_callback_query "${iBUTTON[ID]}" "${callback_answer}"
            ;;
    esac
    
    } # mycallbacks()

    #######################
    # this fuinction is called only if you has set INLINE=1 !!
    # shellcheck disable=SC2128
    myinlines() {
    
    iQUERY="${iQUERY,,}"

    case "${iQUERY}" in
        ##################
        # example inline command, replace it by your own
        "image "*) # search images with yahoo
            local search="${iQUERY#* }"
            answer_inline_multi "${iQUERY[ID]}" "$(my_image_search "${search}")"
            ;;
    esac

    } # myinlines()

    #####################
    # place your processing functions here

    #####################
    # execute shell command
    msg_as_cmd() {

    set -o pipefail
    cd

    RES=$(timeout 3600 bash -c "$@" 2>&1 | head -c 3072)
    RET=$?

    echo "$RES"

    [[ $RET == 141 ]] && echo "😳"  # overflow
    [[ $RET == 143 ]] && echo "😡"  # timeout

    [[ -z $RES && $RET == 0 ]] && echo "😊" # success
    [[ -z $RES && $RET != 0 ]] && echo "😞" # failure

    } # msg_as_cms()

    #####################    
    # example inline processing function, not really useful
    # $1 search parameter
    my_image_search(){

    local image result sep="" count="1"
    result="$(wget --user-agent 'Mozilla/5.0' -qO - "https://images.search.yahoo.com/search/images?p=$1" |  sed 's/</\n</g' | grep "<img src=")"
    while read -r image; do
        [ "${count}" -gt "20" ] && break
        image="${image#* src=\'}"; image="${image%%&pid=*}"
        [[ "${image}" = *"src="* ]] && continue
        printf "%s\n" "${sep}"; inline_query_compose "${RANDOM}" "photo" "${image}"; sep=","
        count=$(( count + 1 ))
    done <<<"${result}"
    
    } # my_image_search()

    ###########################
    # example error processing
    # called when delete Message failed
    # func="$1" err="$2" chat="$3" user="$4" emsg="$5" remaining args
    bashbotError_delete_message() {
    
    log_debug "custom errorProcessing delete_message: ERR=$2 CHAT=$3 MSGID=$6 ERTXT=$5"
    
    }

    # called when error 403 is returned (and no func processing)
    # func="$1" err="$2" chat="$3" user="$4" emsg="$5" remaining args
    bashbotError_403() {
    
    log_debug "custom errorProcessing error 403: FUNC=$1 CHAT=$3 USER=${4:-no-user} MSGID=$6 ERTXT=$5"

    }
fi

