
#JAVA_OPT="${JAVA_OPT} -server -Xms768m -Xmx1g -Xmn256m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m"
#JAVA_OPT="${JAVA_OPT} -XX:+UseConcMarkSweepGC -XX:+UseCMSCompactAtFullCollection -XX:CMSInitiatingOccupancyFraction=70 -XX:+CMSParallelRemarkEnabled -XX:SoftRefLRUPolicyMSPerMB=0 -XX:+CMSClassUnloadingEnabled -XX:SurvivorRatio=8 -XX:+DisableExplicitGC"
#JAVA_OPT="${JAVA_OPT} -verbose:gc -Xloggc:./gc.log -XX:+PrintGCDetails"
#JAVA_OPT="${JAVA_OPT} -Dspring.profiles.active=$PROJECT_ENV"

#JAVA_OPT="${JAVA_OPT} -Xdebug -Xrunjdwp:transport=dt_socket,address=9555,server=y,suspend=n"

start(){
cd $WORK_DIR/$PROJECT_NAME/work
cp cdp/$PROJECT_NAME-$PROJECT_VERSION.cdp $PROJECT_NAME.cdp

classPath=""
for file in $WORK_DIR/$PROJECT_NAME/work/lib/*
do
if [ -f "$file" ]
then
  classPath=$classPath"$file\:"
fi
done

tmp=`echo $classPath |sed 's#\/#\\\/#g'`

sed -i "s/%{TASK_FLAG}%/$TASK_FLAG/" $WORK_DIR/$PROJECT_NAME/work/conf/**/CorrelatorConfig.yaml
sed -i "s/%{TRADE_JAVA_CLASS_PATH}%/$tmp/" $WORK_DIR/$PROJECT_NAME/work/conf/**/CorrelatorConfig.yaml

}

stop(){
echo "1"
}

check(){
return 0
}
