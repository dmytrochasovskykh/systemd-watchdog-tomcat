#!/bin/bash
#

getPid() {
	pid=$(pgrep -a agetty | awk '/keep-baud/{print $1}')
}

healthCheck() {
    echo "hello" > /dev/console && HEALTH_STATUS="success" || HEALTH_STATUS="fail" 
}

watchdog() {
    # INITIAL OF WATCHDOG
    # go to watchdog logic when conditions down satisfied
    #   - pid exist
    #   - first health check status success
    while : ; do
        [[ -n $pid ]] && {
            healthCheck
            [[ $HEALTH_STATUS -eq "success" ]] && {
                echo "healthCheck >>> notify systemd READY=1" # debug
                systemd-notify  --ready
                break
            }
        } || {
            getPid
            echo "getPid >>> PID:[${pid}]"                    # debug
        }
    done

    # WATCHDOG START
    while : ; do
        interval=$(($WATCHDOG_USEC / $((2 * 1000000))))

        healthCheck
        if [[ $HEALTH_STATUS -eq "success" ]] ; then
            echo "watchdog test succeeded" #debug
            systemd-notify  WATCHDOG=1
            sleep ${interval}
        else
            echo "watchdog test failed"  #debug
            sleep 1
        fi
    done
}


watchdog &
