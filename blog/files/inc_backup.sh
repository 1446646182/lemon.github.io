#!/bin/bash
source ./backup.cnf
#全量备份最后一次坐标记录
last_full_file=$full_back_last_index_file
#全量备份目录
full_basedir=$full_backup_path
#增量备份目录
inc_basedir=$inc_backup_path
#日志文件名称及大小
logfile="/var/mysql/backup/inc.log"
#字节数
logsize=2000000

exec 2>>$logfile

#日志函数
#参数
  #参数一，级别，INFO ,WARN,ERROR
    #参数二，内容
#返回值
function log()
{
  #判断格式
  if [ 2 -gt $# ]
  then
    echo "parameter not right in log function" ;
    return ;
  fi
  if [ -e "$logfile" ]
  then
    touch $logfile
  fi

  #当前时间
  local curtime;
  curtime=`date +"%Y-%m-%d-%H:%M:%S"`

  #判断文件大小
  local cursize ;
  cursize=`cat $logfile | wc -c` ;

  if [ $logsize -lt $cursize ]
  #if [ `echo $logsize | awk -v cur=$cursize '{print($1<cur)?"1":"0"}'` -eq "1" ]
  then
    mv $logfile $curtime".out"
    touch $logfile ;
  fi
  #写入文件
  echo "$curtime $*" >> $logfile;
}

log INFO "===================================================================start==================================================================="
echo "开始备份"

currentdate=$(date -d today +"%Y_%m_%d_%H_%M_%S")

if [ -e $last_full_file ];then
  last_full_index=$(cat $full_back_last_index_file)

  if [ ! -n "$last_full_index" ]; then
    echo "备份失败，找不到最后一次全量备份坐标，在"$full_back_last_index_file"中"
    log ERROR "备份失败，找不到最后一次全量备份坐标，在"$full_back_last_index_file"中"
  else
    echo "全量备份坐标："$last_full_index
    log INFO "全量备份坐标："$last_full_index

    inc_dirname=$inc_basedir"/"$last_full_index"/"$currentdate
    if [ ! -d $inc_dirname  ];then
      mkdir -p $inc_dirname

      echo "创建增量备份目录："$inc_dirname
      log INFO "创建增量备份目录："$inc_dirname

      echo "备份中......"
      log INFO "备份中......"
      xtrabackup \
        --host=$mysql_host --user=$mysql_user --port=$mysql_port --password=$mysql_password \
        --backup \
        --target-dir=$inc_dirname \
        --incremental-basedir=$full_basedir"/"$last_full_index

      echo "备份完成，请检查日志文件："$logfile"，查看是否备份成功！"
      log INFO "备份完成"
    else
      echo "备份失败，增量备份文件已存在"
      log ERROR "备份失败，增量备份文件已存在"
    fi
  fi
else
  echo "备份失败，没有找到全量备份文件"
  log ERROR "备份失败，没有找到全量备份文件"
fi
log INFO "=================================================================== end ==================================================================="
