#!/bin/bash
#
#  ca_json_separator.sh
#
#  Author: Ryosuke KUTSUNA <kutsuna@serverworks.co.jp>
#  CloudAutomatorからダウンロードしたJOBのJSONを、JOB毎に分割するスクリプト
#

if [ $# -lt 2 ]; then
  echo "Usage: $0 input_json prefix_output_file"
  exit 0
fi

IN_FILE=$1
OUT_FILE=$2
GROUP_ID=853
AWS_ID=1142
tmpfile=$(mktemp)

array_count=$( expr $(cat $IN_FILE | jq '. | length') - 1  )

cat ${IN_FILE} | tr -d '\\' | \
sed -e '/job_id.*$/d' \
	-e "s/\(\"group_id\": \).*$/\1${GROUP_ID},/"      \
	-e "s/\(\"aws_account_id\": \).*$/\1${AWS_ID},/"  \
	-e "s/\"\[\"\",/\[/" \
	-e "s/day\"\]\",$/day\" \],/" \
	> ${tmpfile}

for i in $(seq 0 ${array_count}); do
  cat ${tmpfile} | jq ".[$i]" > ${OUT_FILE}_$( printf %02d $i ).json
done
