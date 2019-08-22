#!/bin/sh
# 给定一个文本文件 file.txt，请只打印这个文件中的第十行
awk 'NR==10' file.txt
sed -n 10p file.txt
