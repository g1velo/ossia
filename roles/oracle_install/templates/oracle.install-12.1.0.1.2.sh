#!/bin/ksh
# VERSION 0.1
# Loic Fura
# Last update : 2011-03-08
# Oracle 10gR2 base (10.2.0.1), Oracle 10gR2 patchset2 (10.2.0.3), Oracle 10gR2 patchset3 (10.2.0.4)
# Oracle 11gR1 base (11.1.0.6) and Oracle 11gR1 patchset 1 (11.1.0.7) installation  
# VERSION 0.1
# SNAVARRO 
# Adding 11.2.0.4 support 
# Adding 12 Support 


### SCRIPT INIT ************************************************************************************* ###


# Directory from where the script is being executed
#SCRIPT_BASE_DIR=$(dirname $0)
SCRIPT_BASE_DIR=$PWD 

# Directory that contains list of required filesets and their versions
AIX_PREREQS_DIR=${SCRIPT_BASE_DIR}/prereqs

# Functions Location
FUNCTIONS_LOC=${SCRIPT_BASE_DIR}/functions
FPATH=${FUNCTIONS_LOC}

#Including all fuctions located in FPATH directory
autoload checkFilesets
autoload findFilesets
autoload checkEFix
autoload installEfix
autoload checkSystemParams
autoload checkSpecialCmds
autoload createFS
autoload createGroup
autoload createUser
autoload gen_oracle_profile
autoload help
#autoload gen_oracle_rsp_file_11_2_0_4
autoload gen_oracle_rsp_file_12_1_0_2_0


#Get the system date and time for ora_respfile and orapatch_respfile
DATE=$(date +%y%m%d%H%M%S)

PREREQS_ONLY=0

# Default parameters 

ORA_VERSION=12.1.0.2.0
ORA_INSTALL_TYPE=DB
ORA_MEM=4096
ORA_SID=DB2
ORA_PWD=port2peche
ORA_CHARACTER_SET=WE8MSWIN1252
ORA_FS=/oracle
ORA_DATA_FS=/oradata
ORA_DATA_FS_SIZE=12G
ORA_DATA_VG=datavg
ORA_DATA_LV=oradata
ORA_FS_SIZE=16G
ORA_LV=oraclelv
ORA_FS_VG=rootvg
ORA_INVENTORY=/home/oracle/oraInventory
ORA_BASE=${ORA_FS}
ORA_HOME=${ORA_BASE}/product/${ORA_VERSION}/database
ORA_USER=oracle
ORA_USER_UID=500
ORA_HOME_PROFILE=/home/oracle
ORA_PASSWD=oracle
ORA_GROUP=dba
ORA_GROUP_GID=500
ORA_OINSTALL_GROUP=oinstall
ORA_OINSTALL_GROUP_GID=501
#CODE_BASE_DIR=${PWD}/${SCRIPT_BASE_DIR}/../code
CODE_BASE_DIR=/tmp/ossia/code
ORA_CODE=${CODE_BASE_DIR}/database/
ORA_ROOTPRE=${CODE_BASE_DIR}/database/
## added for test on 22012015
ORACLE_HOME_NAME=DB2_NAME


# Parametres transfert de fichiers 
CODE_TRANSFERT_METHOD=scp
CODE_TRANSFERT_USER=service
CODE_HOST=10.16.1.1
CODE_DIR=/images/products/oracle/oracle12c_aix/12.1.0.2.0

mkdir -p ${CODE_BASE_DIR}


#while getopts "f:pd:" option
#do
        #case $option in
		#d)  ORA_SID=$OPTARG ;;
                #f) paramsFile=$OPTARG;;
		#p) PREREQS_ONLY=1;;

        #esac
#done

#${CODE_TRANSFERT_METHOD}  ${CODE_TRANSFERT_USER}@${CODE_HOST}:${CODE_DIR}/p17694377_121020_AIX64-5L_1of8.zip  ${CODE_BASE_DIR}
#${CODE_TRANSFERT_METHOD}  ${CODE_TRANSFERT_USER}@${CODE_HOST}:${CODE_DIR}/p17694377_121020_AIX64-5L_2of8.zip  ${CODE_BASE_DIR}

#cd /${CODE_BASE_DIR}
#for i in $(ls *.zip)
	#do
	#unzip -qq -o  $i
	#rm $i 
	#done 

print "ORA_USER : " ${ORA_USER}
RESPFILE_NAME="/tmp/oracle-respfile_${ORA_VERSION}_${DATE}.rsp"

gen_oracle_rsp_file_12_1_0_2_0


# Checking parameter file
# TODO

print "\n*** Oracle version ${ORA_VERSION} selected for installation"

### CHECK SYSTEM PREREQUISITES - filesets, kernel parameters, ... *********************************** ###

print "\n*** Checking AIX filesets prerequisite"
checkFilesets ${ORA_VERSION}

print "\n*** Checking AIX system parameters prerequisite"
checkSystemParams ${ORA_VERSION}

print "\n*** Checking efix prerequisite"
checkEFix ${ORA_VERSION}

print "\n*** Checking if any special commands to execute"
checkSpecialCmds ${ORA_VERSION}


### CREATE USER & GROUPS **************************************************************************** ###

createGroup ${ORA_GROUP_GID} ${ORA_GROUP}
createGroup ${ORA_OINSTALL_GROUP_GID} ${ORA_OINSTALL_GROUP}

createUser ${ORA_USER} ${ORA_USER_UID} ${ORA_GROUP} ${ORA_HOME_PROFILE} ${ORA_PASSWD} ${ORA_OINSTALL_GROUP}

### CREATE FILESYSTEMS & DIRECTORIES **************************************************************** ###

createFS ${ORA_FS} ${ORA_FS_SIZE} ${ORA_LV} ${ORA_FS_VG} ${ORA_USER} ${ORA_OINSTALL_GROUP}

### Create VG and FS for Oracle Data
print " CREATING LULTI FS " createMultiFS ${ORA_DATA_FS} ${ORA_DATA_FS_SIZE} ${ORA_DATA_LV} ${ORA_DATA_VG} ${ORA_USER} ${ORA_OINSTALL_GROUP} ${ORA_SID}

createMultiFS ${ORA_DATA_FS} ${ORA_DATA_FS_SIZE} ${ORA_DATA_LV} ${ORA_DATA_VG} ${ORA_USER} ${ORA_OINSTALL_GROUP} ${ORA_SID}

### GENERATE ORACLE INSTALLATION RESPONSE FILE ****************************************************** ###

RESPFILE_NAME="/tmp/oracle-respfile_${ORA_VERSION}_${DATE}.rsp"

print "\n*** Generating Oracle Installation response file : ${RESPFILE_NAME} ... \c"
#${SCRIPT_BASE_DIR}/responseFiles/gen-respfile_${ORA_VERSION}.${ORA_INSTALL_TYPE} ${paramsFile} > ${RESPFILE_NAME}

if [ -f ${RESPFILE_NAME} ]
then
	print "DONE"
else
	print "FAILED"
	exit 1
fi

### STOP HERE IF PREREQS_ONLY=1 ********************************************************************* ###
if [ ${PREREQS_ONLY} -eq 1 ]
then
	print "\n*** Prerequisites done"
	exit 0
fi

### GENERATE ${ORA_USER} PROFILE ******************************************************************** ###

print "\n*** Generating oracle user .profile"
gen_oracle_profile
### INSTALL ORACLE BINARIES ************************************************************************* ###

print "\n*** START of Oracle ${ORA_VERSION} installation\n"

print " ORACLE_HOME :                           ${ORA_HOME}"
print " inventory location :                    ${ORA_INVENTORY}"
print " Response file for DB installation :     ${RESPFILE_NAME}"

print "\n*** Executing rootpre.sh"
cd ${ORA_ROOTPRE};./rootpre.sh
cd -

print "\n*** Starting Oracle ${ORA_VERSION} Installation "
su - ${ORA_USER} -c "export SKIP_ROOTPRE=TRUE; cd ${ORA_CODE}/;./runInstaller -force -ignorePrereq -waitforcompletion -silent -responseFile ${RESPFILE_NAME} "

print "\n*** Running ${ORA_INVENTORY}/orainstRoot.sh"
#
${ORA_INVENTORY}/orainstRoot.sh

print "\n*** Running ${ORA_HOME}/root.sh"
${ORA_HOME}/root.sh -silent

print "\n*** END of Oracle ${ORA_VERSION} installation"

### PATCHSET INSTALLATION IF ANY********************************************************************* ###

if [ -n "${ORA_PATCHSET_VERSION}" ]
then
	print "\n*** Patchset ${ORA_PATCHSET_VERSION} selected for installation"
	print "\n*** Checking AIX filesets prerequisite"
	checkFilesets ${ORA_PATCHSET_VERSION}

	print "\n*** Checking AIX system parameters prerequisite"
	checkSystemParams ${ORA_PATCHSET_VERSION}

	print "\n*** Checking efix prerequisite"
	checkEFix ${ORA_PATCHSET_VERSION}

	print "\n*** Checking if any special commands to execute"
        checkSpecialCmds ${ORA_PATCHSET_VERSION}

	PATCHSET_RESPFILE_NAME="/tmp/oracle-patchset-respfile_${ORA_PATCHSET_VERSION}_${DATE}.rsp"
	print "\n*** Generating Oracle Patchset Installation response file : ${PATCHSET_RESPFILE_NAME} ... \c"	
	${SCRIPT_BASE_DIR}/responseFiles/gen-respfile_${ORA_PATCHSET_VERSION}.PS ${paramsFile} > ${PATCHSET_RESPFILE_NAME}
	if [ -f ${PATCHSET_RESPFILE_NAME} ]
	then
        	print "DONE"
	else
        	print "FAILED"
        	exit 1
	fi
	/usr/sbin/slibclean
	su - ${ORA_USER} -c "export SKIP_SLIBCLEAN=TRUE; cd ${ORA_PATCHSET_CODE} ; ./runInstaller -silent -ignoreSysPrereqs  -waitforcompletion -responseFile ${PATCHSET_RESPFILE_NAME}"
	print "\n*** Running ${ORA_HOME}/root.sh"
	${ORA_HOME}/root.sh -silent
	print "\n*** END of Oracle patchset ${ORA_PATCHSET_VERSION} installation"
fi


### END OF INSTALLATION ***************************************************************************** ###

print "\n*** End of automatic installation"


#print chown ${ORA_USER}:${ORA_GROUP} ${SCRIPT_BASE_DIR}/oracrt
#chown ${ORA_USER}:${ORA_GROUP} ${SCRIPT_BASE_DIR}/oracrt
#print chown -R ${ORA_USER}:${ORA_GROUP} ${SCRIPT_BASE_DIR}/oracrt
#chown -R ${ORA_USER}:${ORA_GROUP} ${SCRIPT_BASE_DIR}/oracrt
#
#print su - ${ORA_USER} -c ${SCRIPT_BASE_DIR}/oracrt/createdb.ksh


#print su - ${ORA_USER} -c ${SCRIPT_BASE_DIR}/oracrt/createdb.12.ksh -d ${ORA_SID} -p port2peche -b ${ORA_DATA_FS}
#su - ${ORA_USER} -c ${SCRIPT_BASE_DIR}/oracrt/createdb.12.mfs.ksh -d ${ORA_SID} -p ${ORA_PWD} -b ${ORA_DATA_FS}
