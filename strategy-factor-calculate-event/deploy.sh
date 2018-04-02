
JAVA_OPT="${JAVA_OPT} -server -Xms768m -Xmx1g -Xmn256m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m"
JAVA_OPT="${JAVA_OPT} -XX:+UseConcMarkSweepGC -XX:+UseCMSCompactAtFullCollection -XX:CMSInitiatingOccupancyFraction=70 -XX:+CMSParallelRemarkEnabled -XX:SoftRefLRUPolicyMSPerMB=0 -XX:+CMSClassUnloadingEnabled -XX:SurvivorRatio=8 -XX:+DisableExplicitGC"
JAVA_OPT="${JAVA_OPT} -verbose:gc -Xloggc:./gc.log -XX:+PrintGCDetails"
JAVA_OPT="${JAVA_OPT} -Dspring.profiles.active=$PROJECT_ENV"

#JAVA_OPT="${JAVA_OPT} -Xdebug -Xrunjdwp:transport=dt_socket,address=9555,server=y,suspend=n"

stop(){
    pid=`ps ax | grep -i $PROJECT_NAME |grep java | grep -v grep | awk '{print $1}'`
    if [ ! -z "$pid" ] ; then
        echo "The $PROJECT_NAME (${pid}) is running..."
        kill ${pid}
        echo "Send shutdown request to $PROJECT_NAME(${pid}) OK"
    fi
}

start(){
    cd $WORK_DIR/$PROJECT_NAME/work
    nohup java ${JAVA_OPT} -jar $PROJECT_NAME-$PROJECT_VERSION-exec.jar > $PROJECT_NAME.log 2>&1 &
}


restart(){
    echo "restart app!!"
}


check(){
    _pid=`ps ax | grep -i $PROJECT_NAME |grep java | grep -v grep | awk '{print $1}'`
    echo "$_pid"
}
