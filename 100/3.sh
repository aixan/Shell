#!/bin/bash
#每周五早上3点使用tar命令备份/var/log下的所有日志文件
#vim /aixan/tools/3.sh
#编写备份脚本，备份后的文件包含日期标签，防止后面的备份将前面的备份数据覆盖
#注意data命令需要使用反引号括起来，反引号在键盘<tab>上面
tar -czf log-`data +%Y%m%d`.tar.gz /var/log

#crontab -e #编写计划任务，执行备份脚本
00 03 * * 5 /bin/bash /aixan/tools/3.sh
