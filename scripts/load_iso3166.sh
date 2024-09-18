#!/bin/bash 
# The Source of the data you can find https://unstats.un.org/unsd/methodology/m49/overview/
# where you have to download the CSV 
# we have removed some of the columns and also the country "antarctica" 
# we have add a column AzureRegion, because the goal of the table was to map countries to our AzureRegions we use. 


SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
. ${SCRIPT_DIR}/az_cli.sh


#export AZ_Tenant="" 
#export OpenPubIP4Load="Y" 
#export TableName="iso3166codes" 
#export AZ_StorageAccount=""
#export ISO3166_File="./UNSD_Methodology.csv"
#export EuropeRegion=""
#export OtherRegion=""
. ${SCRIPT_DIR}/iso3166.inc 


az_login ${AZ_Tenant}

az_open_storage_ip 

#-----------------------------------------------------------------------------------------------------
# create table 

# get storage key 
export AZ_StorageAccount_Key=`az storage account keys list -n ${AZ_StorageAccount} | grep "value" | head -1  | sed 's/"value"://'`
[ "${AZ_StorageAccount_Key}" == "" ] && echo "Error during get Storage Key" >&2 && exit 1
echo "AZ_StorageAccount_Key $AZ_StorageAccount_Key"


# check if table exits -> exit 
export TableExits=`az storage table exists --name "${TableName}" --account-name "${AZ_StorageAccount}" --account-key "${AZ_StorageAccount_Key}" | grep "exists" | sed 's/\( \|"exists":\)//g'`
[ "${TableExits}" == "true" ] && echo "Table \"${TableName}\" alread exits in Storage Account \"${AZ_StorageAccount}\" " >&2 && exit 0
echo "table exists \"${TableName}\" account-name \"${AZ_StorageAccount}\" result \"${TableExits}\""

echo "create table \"${TableName}\" account-name \"${AZ_StorageAccount}\""
az storage table create --name "${TableName}" --account-name "${AZ_StorageAccount}" --account-key "${AZ_StorageAccount_Key}"
[ "$?" == "1" ] && echo "Error during create table \"${TableName}\" in \"${AZ_StorageAccount}\"" >&2 && exit 1 

export TableExits=`az storage table exists --name "${TableName}" --account-name "${AZ_StorageAccount}" --account-key "${AZ_StorageAccount_Key}" | grep "exists" | sed 's/\( \|"exists":\)//g'`
while [ "$TableExits" == "false" ] 
do
	sleep 3
	export TableExits=`az storage table exists --name "${TableName}" --account-name "${AZ_StorageAccount}" --account-key "${AZ_StorageAccount_Key}" | grep "exists" | sed 's/\( \|"exists":\)//g'`
done

# start to populate table 
export TableCol="Region_Code Region_Name Sub_region_Code Sub_region_Name Country_or_Area ISO_alpha2_Code ISO_alpha3_Code" 
declare -a aTableCol=(${TableCol}) 

tail -n +2 ${ISO3166_File} | sed  -z 's/$/\n/g' | sed 's/ /_/g' | sed 's/;;/;NULL;/g' | sed 's/;;/;NULL;/g' | sed 's/;;/;NULL;/g' |  sed 's/;/ /g' | while read a b c d e f g h i j k l m n  
do 
	if [ "$a" != "" -o "c" != "NULL" ]
	then 
		export line="$c $d $e $f $i $j $k $l" 
		declare -a aRawCol=($line) 
		export TableEntity1="PartitionKey=${aRawCol[0]} RowKey=${aRawCol[5]}"

		echo "insert $TableEntity1"
		
		if [ "${aRawCol[0]}" == "150" ] 
		then
			export AzureRegion=$EuropeRegion
		else 
			export AzureRegion=$OtherRegion
		fi 
		export CMD="insert"
		for j in "${!aTableCol[@]}" 
		do 
			export TableEntity2="${aTableCol[$j]}=${aRawCol[$j]}"
			
			az storage entity $CMD --entity ${TableEntity1} ${TableEntity2} --table-name "${TableName}" --account-name "${AZ_StorageAccount}" --account-key "${AZ_StorageAccount_Key}" > /dev/null 
			export CMD="merge"
		done 
		az storage entity $CMD --entity ${TableEntity1} AzureRegion="${AzureRegion}" --table-name "${TableName}" --account-name "${AZ_StorageAccount}" --account-key "${AZ_StorageAccount_Key}" > /dev/null 
	fi
done

az_close_storage_ip

exit 0