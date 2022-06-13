#!/bin/bash

## =================
## 定数
## =================

CHANNEL_ACCESS_TOKEN="YOUR_TOKEN"
WEATHER_DATA_FILE="path/to/weather_data_$(date %Y%m%d).txt"
LOG_FILE="path/to/precipitation.log"
WEATHER_INFOMATION="https://www.google.com/search?q=%E6%9D%B1%E4%BA%AC+%E5%A4%A9%E6%B0%97"
JQ_COMMAND_PATH="/path/to/jq"

## =================
## 関数
## =================

# 天気予報APIから最大降水量取得[mm/hour]
function get_wether_data() {
  curl "https://api.open-meteo.com/v1/forecast?latitude=35.6785&longitude=139.6823&hourly=precipitation" > ${WEATHER_DATA_FILE}
  MAX_PRECIPITATION=$(cat ${WEATHER_DATA_FILE} |${JQ_COMMAND_PATH} '.hourly.precipitation[24:48] | max'
  MAX_PRECIPITATION_INT=$(echo ${MAX_PRECIPITATION} |awk -F '.' '{print $1}')
}

# LINE Messaging APIへPOST
function post_line() {
  MESSAGE=${1}
  curl -v -X POST https://api.line.me/v2/bot/message/broadcast \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer {"'${CHANNEL_ACCESS_TOKEN}'"}' \
  -d '{
    "messages":[
      {
        "type":"text",
        "text":"'${MESSAGE}'"
      }
    ]
  }'
}

## =================
## 主処理
## =================

get_wether_data
if [ 0 -eq ${MAX_PRECIPITATION_INT} ]; then
  :
elif [ 1 -eq ${MAX_PRECIPITATION_INT} ]; then
  MESSAGE="ちょっと降るカモ〜\n最大降水量:${MAX_PRECIPITATION}[mm/hour]\n${WEATHER_INFOMATION}"
  post_line $MESSAGE
elif [ 2 -eq ${MAX_PRECIPITATION_INT} ]; then
  MESSAGE="割と降るカモ〜\n最大降水量:${MAX_PRECIPITATION}[mm/hour]\n${WEATHER_INFOMATION}"
  post_line $MESSAGE
else
  MESSAGE="やばいカモ〜\n最大降水量:${MAX_PRECIPITATION}[mm/hour]\n${WEATHER_INFOMATION}"
  post_line $MESSAGE
fi

# ログ出力
echo "$(date +%Y%m%d), ${MAX_PRECIPITATION}" >> ${LOG_FILE}

exit 0
