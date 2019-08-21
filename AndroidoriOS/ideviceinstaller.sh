#!/bin/sh

# 打印设备UUID
ideviceinstaller -l
# 卸载 -U
ideviceinstaller -U packagename -u 'uuid'
# 安装.ipa文件
ideviceinstaller -i packagename -u 'UUID'
