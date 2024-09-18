#!/bin/bash 
# for az login and open storage ip in case it is closed 


az_login () {

	export AZ_Tenant=$1 
	az ad signed-in-user show > /dev/null
	export RC=$?

	while [ "$RC" -gt 0 ] 
	do 
		az login --use-device-code --tenant  "${AZ_Tenant}"  > /dev/null 
		az ad signed-in-user show > /dev/null
		export RC=$?
	done 
} 

az_open_storage_ip () { 

	if [ "${OpenPubIP4Load}" == "Y" -o "${OpenPubIP4Load}" == "y" ]
	then 
		#-----------------------------------------------------------------------------------------------------
		# enable public ip for strorage account 
		export MyPubIP=`curl ipinfo.io/ip 2>/dev/null`  # get public ip to enable ip in storage account 
		export StorageIP=`az storage account network-rule list  --account-name ${AZ_StorageAccount} | grep  ${MyPubIP} | sed 's/\( \|"ipAddressOrRange": "\|"\)//g'`
		export originalPublicNetworkAccess=`az storage account show --name ${AZ_StorageAccount} | grep "publicNetworkAccess" | sed 's/\( \|"publicNetworkAccess": "\|"\|,\)//g'`

		# check and store, the public-network-access policy 
		if [ "${originalPublicNetworkAccess}" == "Disabled" ]
		then
			echo "update storage account \"${AZ_StorageAccount}\" public-network-access \"Enabled\""
			az storage account update --name "${AZ_StorageAccount}" --public-network-access "Enabled" > /dev/null 
			[ "$?" == "1" ] && echo "Error during update public-network-access for storage account \"${AZ_StorageAccount}\"" >&2 && exit 1 
			az storage account update --name "${AZ_StorageAccount}" > /dev/null 
			[ "$?" == "1" ] && echo "Error during update network rule for for storage account \"${AZ_StorageAccount}\"" >&2 && exit 1 
			
		fi 

		export publicNetworkAccess=`az storage account show --name ${AZ_StorageAccount} | grep "publicNetworkAccess" | sed 's/\( \|"publicNetworkAccess": "\|"\|,\)//g'`
		echo "status of storage account \"${AZ_StorageAccount}\" public-network-access \"${publicNetworkAccess}\""
		while [ "${publicNetworkAccess}"  == "Disabled" ] 
		do
			sleep 3
			export publicNetworkAccess=`az storage account show --name ${AZ_StorageAccount} | grep "publicNetworkAccess" | sed 's/\( \|"publicNetworkAccess": "\|"\|,\)//g'`
			echo "status of storage account \"${AZ_StorageAccount}\" public-network-access \"${publicNetworkAccess}\""
		done 

		# enable the ip for storage access 
		export StorageIP=`az storage account network-rule list  --account-name ${AZ_StorageAccount} | grep  ${MyPubIP} | sed 's/\( \|"ipAddressOrRange": "\|"\)//g'`
		if [ "${StorageIP}" == "" ] 
		then
			echo "Add ${MyPubIP} to network-rule"
			az storage account network-rule add  --account-name "${AZ_StorageAccount}" --ip-address "${MyPubIP}"  --action "Allow"  > /dev/null 
			[ "$?" == "1" ] && echo "Error during create network-rule ${MyPubIP} for storage account \"${AZ_StorageAccount}\"" >&2 && exit 1 
			az storage account update --name "${AZ_StorageAccount}"  > /dev/null 
			[ "$?" == "1" ] && echo "Error during update network rule for for storage account \"${AZ_StorageAccount}\"" >&2 && exit 1 
		fi 

		export StorageIP=`az storage account network-rule list  --account-name ${AZ_StorageAccount} | grep  ${MyPubIP} | sed 's/\( \|"ipAddressOrRange": "\|"\)//g'`
		while [ "$StorageIP" == "" ] 
		do
			sleep 3
			export StorageIP=`az storage account network-rule list  --account-name ${AZ_StorageAccount} | grep  ${MyPubIP} | sed 's/\( \|"ipAddressOrRange": "\|"\)//g'`
		done
		echo originalPublicNetworkAccess > /tmp/$0.$$.originalPublicNetworkAccess
	fi 
} 



az_close_storage_ip () { 

	if [ "${OpenPubIP4Load}" == "Y" -o "${OpenPubIP4Load}" == "y" ]
	then 
	
		export originalPublicNetworkAccess=`cat /tmp/$0.$$.originalPublicNetworkAccess`
		rm /tmp/$0.$$.originalPublicNetworkAccess
		#-----------------------------------------------------------------------------------------------------
		# restore origion public-network-access policy  
		if [ "${originalPublicNetworkAccess}" == "Disabled" ]
		then
			echo "remove public-network-access from \"${AZ_StorageAccount}\""
			az storage account update --name "${AZ_StorageAccount}" --public-network-access "Disabled" > /dev/null 
			[ "$?" == "1" ] && echo "Error during update public-network-access for storage account \"${AZ_StorageAccount}\"" >&2 && exit 1 
		fi 

		#-----------------------------------------------------------------------------------------------------
		# remove ip address 
		echo "remove ip-address \"${MyPubIP}\" from \"${AZ_StorageAccount}\""
		az storage account network-rule remove --account-name "${AZ_StorageAccount}" --ip-address "${MyPubIP}" > /dev/null 
		[ "$?" == "1" ] && echo "Error: during remove network-rule ${MyPubIP} for storage account \"${AZ_StorageAccount}\"" >&2 && exit 1 

		echo "update \"${AZ_StorageAccount}\""
		az storage account update --name "${AZ_StorageAccount}" > /dev/null 
		[ "$?" == "1" ] && echo "Error: during update network rule for for storage account \"${AZ_StorageAccount}\"" >&2 && exit 1 
	fi 
} 

