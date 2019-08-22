# 多条件 或 与
# 1.或
grep -E "versionCode|versionName"
# example
adb shell dumpsys package com.etiantian.pclass | grep -E "versionCode|versionName"

# 2.与


# 拓展
#"或" 查找
#方法一: ( 注意大写E 需要加引号 )
grep -E 'A|B' 和 grep -e A -e B
#方法二:
egrep 'A|B'
#方法三: ( 注意 需要加  "/" )
awk '/A|B/'
