#!/bin/bash
source ./backup.cnf
#备份文件存放目录
basedir=$full_backup_path
#日志文件名称及大小
logfile="/var/mysql/backup/full.log"
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


dirname=$basedir$currentdate
echo "此次备份文件夹路径： $dirname"
if [ ! -d $dirname  ];then
  mkdir -p $dirname
  log INFO "创建备份文件夹成功"
  echo "创建备份文件夹成功"
  echo "$currentdate" > $full_back_last_index_file
  log INFO "备份坐标写入成功"
  echo "备份坐标写入成功"
  log INFO "备份中......"
  echo "备份中......"

  xtrabackup \
  	--user=$mysql_user \
  	--port=$mysql_port \
  	--password=$mysql_password \
  	--backup \
  	--target-dir=$dirname \
  	--datadir=$mysql_data_path

  log INFO "备份完成"
  echo "备份完成，请检查日志文件："$logfile"，查看是否备份成功！"
else
  echo dir exist
  log ERROR "备份失败：备份文件夹："$dirnam" 已存在"
  echo "备份失败：备份文件夹："$dirnam" 已存在"
fi
log INFO "=================================================================== end ==================================================================="
