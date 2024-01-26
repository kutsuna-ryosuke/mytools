#!/bin/bash
#
#  txt2sgyml.sh
#
#  Generate part of security group.
#
#  INPUT FROMAT.... each item separate SPACE. 
#
#    TYPE               IPversion    Type         Protocol     FromPort ToPort Network/Host     Description
#    Inbound/Outbound   IPv4/IPv6    HTTP,RDS...  TCP/ICMP/UDP 0        65535  192.168.10.0/24  description_of_rule.
#
#  WARNING: Don't use Multibyte Character in Description.
#
test -f $1 || exit


# Configuration
#DESC="DEFAULT_NAME"
title=$(basename $1 .csv)
DESC="DEFAULT_NAME"


input=$1
test -z $DESC && exit

printHeader() {
	echo "AWSTemplateFormatVersion: \"2010-09-09\""
	echo "Description: \"${title}\""
	echo "Parameters:"
	echo "  VpcId:"
	echo "    Description: \"Required. Select VPC\""
	echo "    MinLength: \"12\""
	echo "    Type: \"AWS::EC2::VPC::Id\""
}

printResourceHeader() {
	echo "Resources:"
        echo "  ${DESC}:"
        echo "    Type: \"AWS::EC2::SecurityGroup\""
        echo "    DeletionPolicy: \"Delete\""
        echo "    Properties:"
        echo "      GroupDescription: \"for ${title}\""
        echo "      GroupName: \"${title}\""
}

convertDescription() {
	DESC=$(echo $input | tr -d "-" | tr '[:lower:]' '[:upper:]' | cut -d"." -f 1 )
}

printResourceFooter() {
	echo "      VpcId: !Ref VpcId"
}

convertDescription
printHeader
printResourceHeader
for action in "Inbound" "Outbound"; do
	if [ $(grep ^${action} $1 | wc -l )  -ne 0 ]; then
		if [ ${action} = "Inbound" ]; then
			echo "      SecurityGroupIngress:"
		else
			echo "      SecurityGroupEgress:"
		fi
		grep ^${action} $1 | while read line; do

			# pre action
			l1=$line
			line=$(echo $l1 | sed -e "s/すべての /すべての/" -e "s/カスタム /カスタム/" -e "s/ICMP - IPv4/ICMP/")

			protocol=$(echo $line | cut -d " " -f 4 | sed -e "s/\s//" -e "s/すべての//" -e "s/カスタム//" -e "s/すべて/-1/")
			if [ $protocol == "-" ]; then
				protocol="ICMP"
			fi
			targetip=$(echo $line | cut -d " " -f 7)
			fromport=$(echo $line | cut -d " " -f 5 | sed -e "s/すべて/0/" -e "s/Any/0/")
			toport=$(echo $line | cut -d " " -f 6 | sed -e "s/すべて/65535/" -e "s/Any/65535/")
			#desc=$(echo $line | cut -d " " -f 8- | tr -d '\r\n')
			desc=$(echo $line | cut -d " " -f 8- | tr -d '\r\n' | tr -d "–" )
			if [ "$desc" == "ping" ]; then
				fromport="-1"
				toport="-1"
			fi
		
			echo "        - IpProtocol: \"${protocol}\""
			echo "          CidrIp: \"${targetip}\""
			echo "          Description: \"${desc}\""
			echo "          FromPort: \"${fromport}\""
			echo "          ToPort: \"${toport}\""
			echo ""
		done
	fi
done
printResourceFooter
