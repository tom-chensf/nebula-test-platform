#! /usr/bin/env bash
curr_path=$(readlink -f "$(dirname "$0")")
pip3 install --user -r  ${curr_path}/requirements.txt  -i https://mirrors.aliyun.com/pypi/simple/
