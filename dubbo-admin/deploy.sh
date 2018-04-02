export TOMCAT_REMOTE_URL=http://download.forex.com.cn/source/%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%8E%AF%E5%A2%83%E5%8C%85/apache-tomcat-7.0.56.tar.gz

stop(){
    echo "stop app!!"
    bash $TOMCAT_DIR/bin/shutdown.sh

    sleep 3s
    _pid=$(check)
    if [ "$_pid" != "" ];then
        kill $_pid
        echo "kill tomcat.........$_pid"
    fi
}

start(){
    echo "start app!!"
    _pid=$(check)
    if [ "$_pid" == "" ];then
        bash $TOMCAT_DIR/bin/startup.sh
    else
        echo "$pid already is running please check....."
    fi
}

restart(){
    echo "restart app!!"

}


check(){
    _pid=`ps -ef |grep tomcat |grep -v grep |grep "$TOMCAT_DIR"| awk '{print $2}'`
    echo "$_pid"
}

# 为应用准备tomcat容器
# 如果没有tomcat,首次下载tomcat,做tomcat部署
# 如有则校验server.xml配置是否有改动,有的话进行升级
prepareContainer(){
    if  [ ! -d $TOMCAT_DIR ] || [ ! -f $TOMCAT_DIR/bin/startup.sh ]; then
        mkdir -p $TOMCAT_DIR
        cd /www

        if [ ! -f /www/apache-tomcat-7.0.56.tar.gz ]; then
            curl -o apache-tomcat-7.0.56.tar.gz $TOMCAT_REMOTE_URL
        fi

        tar -zxvf apache-tomcat-7.0.56.tar.gz
        mv ./apache-tomcat-7.0.56/* $TOMCAT_DIR
        ls -lh $TOMCAT_DIR

        echo "prepare tomcat env finish";
    fi

    deployContainerConfig
}

#部署容器用得配置文件,这里主要是server.xml
deployContainerConfig(){
    echo "===========start deploy tomcat config file !============"
    cd $WORK_DIR/$PROJECT_NAME/tmp/tomcat/
    for file in `ls`
    do
        sha1sum_new=$(sha1sum $file |awk '{print $1}')
        sha1sum_old=""
        if [ -f $TOMCAT_DIR/conf/$file ];then
            sha1sum_old=$(sha1sum $TOMCAT_DIR/conf/$file |awk '{print $1}')
        fi

        if [ "$sha1sum_new" != "$sha1sum_old" ];then
            echo "deploy tomcat configfile: $file"
            if [ -f $TOMCAT_DIR/conf/$file ];then mv $TOMCAT_DIR/conf/$file $TOMCAT_DIR/conf/$file.bak; fi
            mv $file $TOMCAT_DIR/conf/
        fi
    done
    echo "===========finish deploy tomcat config file !============"
}
