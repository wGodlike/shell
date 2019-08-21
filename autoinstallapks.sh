#!/usr/bin/env bash

# 程序目录
# 1.获取adb devices列表
# 2.获取apk列表
# 3.多进程 按设备数量生成进程并发数 安装apk列表
# 4. adb -s device install -r -d path.apk

# 使用说明:
#   1) AutoApks.sh文件必须和要安装的apk放在同一目录下
#   2) ***.APK文件名不允许有空格
#   3) PC(win、mac、linux)必须安装Android SDK并已配好环境变量
#   4) 若安装的设备数量超过100台，可适当修改减少进程并发数量${proc_num}，具体性能问题和PC配置高低相关

# 使用declare -a 命令定义数组（数组的索引是从0开始计数的）
declare -a arr_deviceList
declare -a arr_appsList

# 获取adb devices列表
function getDevices(){
		declare -i num1=0
		declare -i num3=0
		declare -i num4=0
		declare -a arr_unauthorizedList
#    killServer=`adb kill-server`
#    startServer=`adb start-server`
    idsList=`adb devices`
    # IFS 按行 \n 拆分字符串并存储到数组array_id
    old_ifs="$IFS"
    IFS=$'\n'
    arr_idsList=(${idsList})
    for line in ${arr_idsList[*]}
     do
        # 按device取ID
        case "$line" in
            *"device")
                arr_deviceList[num1]=${arr_deviceList[num1]}${line%"device"}
                num1=`expr ${num1} + 1`
            ;;
            *"unauthorized")
                arr_unauthorizedList[num3]=${arr_unauthorizedList[num3]}${line%"unauthorized"}
                num3=`expr ${num3} + 1`
            ;;
            *)
                num4=`expr ${num4} + 1`
#                break
#                continue
            ;;
        esac
     done
    # 别忘了把IFS改回去
    IFS="$old_ifs"

    # 异常判断处理
    if [[ ${num1} -eq 0 ]]
    then
    	echo "已连接的有效设备数："${num1}
    	echo "已连接的未授权设备数："${num3}
    	if [[ ${num3} -eq 0 ]]
    	then
    	    echo "未检测到有效授权设备，请检查设备连接情况"
    	    echo "adb devices"
    	    adb devices
    	else
    	    echo ${arr_unauthorizedList[*]}
    	    echo "未检测到有效授权设备，请检查设备连接情况"
    	fi

    	exit
    else
    	echo "已连接的有效设备数："${num1}
    	if [[ ${num3} -eq 0 ]]
    	then
    	    echo "已连接的未授权设备数："${num3}
    	else
    	    echo "已连接的未授权设备数："${num3}
    	    echo ${arr_unauthorizedList[*]}
    	fi
    fi
}

# 取apk列表
function readDir(){

   declare -a arr_unAppsList
   declare -i num2=0
   declare -i num5=0

   work_path=$(dirname $0)
   cd ${work_path}  # 当前位置跳到脚本位置
   work_path=$(pwd)   # 取到脚本目录
   apkDir=${work_path}
   cd ${apkDir}
   appsList=`ls $1`
   for app in ${appsList}
    do
        extension="${app##*.}"
        if [[ "$extension" = "apk" ]]
        then
            arr_appsList[num2]=${arr_appsList[num2]}${app}
            num2=`expr ${num2} + 1`
        else
            arr_unAppsList[num5]=${arr_unAppsList[num5]}${app}
            num5=`expr ${num5} + 1`
        fi
    done

    # 异常判断处理
    if [[ ${num2} -eq 0 ]]
    then
    	echo "此目录"${apkDir}"下无可用apk文件"
    	echo "ls -alth"
    	ls -alth
    	exit
    else
        echo "已检测apk数量count："${#arr_appsList[*]}
        for apk in ${arr_appsList[*]}; do
            echo ${apk}
        done
    fi
}

# 多进程并发安装apk ---> 一个设备为一个进程，每个设备子进程串行安装apk
function getInstallApk(){
    fd_fifo=/tmp/fd_1
    mkfifo ${fd_fifo}      #创建命令管道(pipe类型文件)
    exec 6<>${fd_fifo}     #将管道的fd与6号fd绑定
    proc_num=${arr_deviceList[*]}         #进程并发个数
    count=0;
    #预分配资源
    for id in ${arr_deviceList[*]}
    do
        echo >& 6        #写入一个空行
    done

    start=`date +"%s"`
    for id in ${arr_deviceList[*]}
    do
      read -u 6          #读取一个空行
      {
          for apk in ${arr_appsList[*]}; do
                echo "-->正在${id}设备上安装${apk}"
                cmd=`adb -s ${id} install -r -d ${apk}`
                # echo "设备${id}安装${apk}完成<--"
           done
           sleep 1
          echo >& 6      #完成任务，写入一个空行
      }&                 #后台执行
    done
    wait                 #等待所有的任务完成
    exec 6>&-           #关闭fd 6描述符，stdou和stdin
    exec 6<&-
    rm -rf ${fd_fifo}        #删除管道
    end=`date +"%s"`
    echo "time: " `expr ${end} - ${start}`
}

getDevices
readDir
getInstallApk
