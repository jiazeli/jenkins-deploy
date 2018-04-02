#!/usr/bin/env bash

set -e

WORK_DIR=/home/spec/spec-all/spec

SPEC_DIR=$WORK_DIR/spec-web
OLD_DIR=$WORK_DIR/spec-web-old

#check jar file
LIB_DIR=$(cd $SPEC_DIR && find . -name "lib" -type d)
echo "lib dir is: $LIB_DIR"

for jarFile in $(cd $SPEC_DIR && ls $LIB_DIR/ )
do
    if [ -f $SPEC_DIR/$LIB_DIR/$jarFile ]; then
        if [ -f $OLD_DIR/$LIB_DIR/$jarFile ];then
            sha1sum_new=$(sha1sum $SPEC_DIR/$LIB_DIR/$jarFile |awk '{print $1}')
            sha1sum_old=$(sha1sum $OLD_DIR/$LIB_DIR/$jarFile |awk '{print $1}')
            if [ "$sha1sum_new" != "$sha1sum_old" ];then
                echo "modify $jarFile" >> $SPEC_DIR/$LIB_DIR/changelog.txt
                rm -rf $OLD_DIR/$LIB_DIR/$jarFile
            else
                rm -rf $SPEC_DIR/$LIB_DIR/$jarFile && rm -rf $OLD_DIR/$LIB_DIR/$jarFile
            fi
        else
            echo "add $jarFile" >> $SPEC_DIR/$LIB_DIR/changelog.txt
        fi
    fi
done

for jarFile in $(cd $OLD_DIR && ls $LIB_DIR/ )
do
    if [ -f $OLD_DIR/$LIB_DIR/$jarFile ]; then
        if [ ! -f $SPEC_DIR/$LIB_DIR/$jarFile ];then
            echo "del $jarFile" >> $SPEC_DIR/$LIB_DIR/changelog.txt
            rm -rf $OLD_DIR/$LIB_DIR/$jarFile
        fi
    fi
done

echo "new jar file is: $(cd $SPEC_DIR && ls $LIB_DIR/ )"
echo "old jar file is: $(cd $OLD_DIR && ls $LIB_DIR/ )"