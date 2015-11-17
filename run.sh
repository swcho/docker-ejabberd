#!/bin/bash
set -e

source "${EJABBERD_HOME}/scripts/lib/base_config.sh"
source "${EJABBERD_HOME}/scripts/lib/config.sh"
source "${EJABBERD_HOME}/scripts/lib/base_functions.sh"
source "${EJABBERD_HOME}/scripts/lib/functions.sh"

# discover hostname
readonly nodename=$(get_nodename)

is_zero ${ERLANG_NODE} \
    && export ERLANG_NODE="ejabberd"

## backward compatibility
# if ERLANG_NODE is true reset it to "ejabberd" and add
# hostname to the nodename.
# else: export ${ERLANG_NODE} with nodename
if (is_true ${ERLANG_NODE}); then
    export ERLANG_NODE="ejabberd@${nodename}"
else
    #export ERLANG_NODE="${ERLANG_NODE}@${nodename}"
    export ERLANG_NODE="${ERLANG_NODE}@${nodename}"
    echo "nodename=${nodename}"
    echo "ERLANG_NODE=${ERLANG_NODE}"
fi


run_scripts() {
    local run_script_dir="${EJABBERD_HOME}/scripts/${1}"
    for script in ${run_script_dir}/*.sh ; do
        if [ -f ${script} -a -x ${script} ] ; then
            ${script}
        fi
    done
}


pre_scripts() {
    run_scripts "pre"
}


post_scripts() {
    run_scripts "post"
}

stop_scripts() {
    run_scripts "stop"
}


ctl() {
    local action="$1"
    ${EJABBERDCTL} ${action} >/dev/null
}


_trap() {
    echo "Stopping ejabberd..."
    stop_scripts
    if ctl stop ; then
        local cnt=0
        sleep 1
        while ctl status || test $? = 1 ; do
            cnt=`expr $cnt + 1`
            if [ $cnt -ge 60 ] ; then
                break
            fi
            sleep 1
        done
    fi
}


# Catch signals and shutdown ejabberd
trap _trap SIGTERM SIGINT

echo "EJABBERDCTL=${EJABBERDCTL}"

## run ejabberd
case "$@" in
    start)
        echo "DBG: pre_scripts"
        pre_scripts
        tail -F ${LOGDIR}/crash.log \
                ${LOGDIR}/error.log \
                ${LOGDIR}/erlang.log &
        echo "DBG: ${EJABBERDCTL} start"
        exec ${EJABBERDCTL} "live" &
        #exec ${EJABBERDCTL} "start" &
        child=$!
        echo "DBG: ${EJABBERDCTL} started"
        ${EJABBERDCTL} "started"
        sleep 30
        echo "DBG: post_scripts"
        post_scripts
        echo "DBG: wait $child"
        wait $child
    ;;
    live)
        echo "Starting ejabberd in 'live' mode..."
        exec ${EJABBERDCTL} "live"
    ;;
    shell)
        exec "/bin/bash"
    ;;
    *)
        exec $@
    ;;
esac
