#!/bin/ksh
################################################################################
#
# Documentation
# =============
# This is the install scripts for the BMC SM/PM Installation
# =============
#  Ver 1.0.0 - Created by Franco Bontorin
################################################################################

###################
# VARIABLE DECLARATION   #
###################

OS_TYPE=$(uname -s)
ARCH=$(uname -p)
HOSTNAME=$(uname -n)
RESPONSE_FILE=/appvol/depot/superstacks_smpm_unix-5.1.0.101/SMPM.resp
LOG_FILE=/appvol/depot/superstacks_smpm_unix-5.1.0.101/superstacks_smpm-unix-5.1.0.101-$(date "+%Y-%m-%d").log
. $RESPONSE_FILE

##############################################################################################################################
# GLOBAL INSTALL FUNCTIONS - Here are located the global functions that could be used by all platforms                            #
###############################################################################################################################


  ####################################
	# Install the base package and Service Pack of BMC SM/PM    #
	####################################

		function InstallControlSA {
			
			# BASE INSTALL MODULE
			echo "Installing the Base Module of SM 5.1.00/PM 5.0.01"
			su - $CTRLSA_USER -c "$BIN_PATH/$OS_TYPE/BASE_INSTALL/Install/Disk1/InstData/VM/Setup.bin -i silent -f /opt/$CTRLSA_USER/autoinst.ini" > $LOG_FILE
			
			# SERVICE PACK .100
			echo "Installing Service Pack 5.0.01.100"
			su - $CTRLSA_USER -c "$BIN_PATH/$OS_TYPE/5.1.01.100/install/install_SP.sh" <<EOF >> $LOG_FILE
1
N
EOF
	
		}
			
###############################################################################################################################
# INDIVIDUAL INSTALL FUNCTIONS - Here are located only the functions that have particular configuration according each Platform   #
###############################################################################################################################
	

case $OS_TYPE in

 ###########
 #   AIX   #
 ###########


        (AIX)

	        function ProvisioningModule {

			# PROVISIONING MODULE
			echo "Installing BMC Provisioning Module"
			su - $CTRLSA_USER -c "/opt/$CTRLSA_USER/bmc/idm/ServicesManager/bin/addPM.sh -f "$BIN_PATH/$OS_TYPE/PM/64-bit/AIX42-V5.0.01.pmz" -silent" >> $LOG_FILE
			su - $CTRLSA_USER -c "/opt/$CTRLSA_USER/bmc/idm/ServicesManager/script/addMSCS.sh -pm AIX42 -mscs $HOSTNAME -f /opt/$CTRLSA_USER/$HOSTNAME.properties" >> $LOG_FILE
			
			# SERVICE PACK .101
			echo "Installing Service Pack 5.0.01.101\n"
			cp $BIN_PATH/$OS_TYPE/5.1.01.101/64-bit/* /opt/$CTRLSA_USER/bmc/idm/ServicesManager/bin/.

		}
		
	;;
	
	(Linux)	
                
		function ProvisioningModule {

			if [ "$ARCH" == "x86_64" ]
			then
				ARCH=64-bit
			else
				ARCH=32-bit
			fi
			
			# PROVISIONING MODULE			
			echo "Installing BMC Provisioning Module"
			su - $CTRLSA_USER -c "/opt/$CTRLSA_USER/bmc/idm/ServicesManager/bin/addPM.sh -f "$BIN_PATH/$OS_TYPE/PM/Install/$ARCH/Linux-V5.0.00.pmz" -silent" >> $LOG_FILE
			su - $CTRLSA_USER -c "/opt/$CTRLSA_USER/bmc/idm/ServicesManager/script/addMSCS.sh -pm Linux -mscs $HOSTNAME -f /opt/$CTRLSA_USER/$HOSTNAME.properties" >> $LOG_FILE
			
			# SERVICE PACK .101
			echo "Installing Service Pack 5.0.01.101\n"
			cp $BIN_PATH/$OS_TYPE/5.1.01.101/$ARCH/* /opt/$CTRLSA_USER/bmc/idm/ServicesManager/bin/.
			cp $BIN_PATH/$OS_TYPE/5.1.01.101/CTSACMN.MSG /opt/$CTRLSA_USER/bmc/idm/ServicesManager/messages/.
			cp $BIN_PATH/$OS_TYPE/5.1.01.101/soni_control.sh /opt/$CTRLSA_USER/bmc/idm/ServicesManager/script/.

		}

	;;
		
	(SunOS)

		function ProvisioningModule {
		
			# SERVICE PACK .101
			echo " Installing Service Pack 5.0.01.101"
			cp $BIN_PATH/$OS_TYPE/5.1.01.101/64-bit/* /opt/$CTRLSA_USER/bmc/idm/ServicesManager/bin/.
			cp $BIN_PATH/$OS_TYPE/5.1.01.101/CTSACMN.MSG /opt/$CTRLSA_USER/bmc/idm/ServicesManager/messages/.
			cp $BIN_PATH/$OS_TYPE/5.1.01.101/soni_control.sh /opt/$CTRLSA_USER/bmc/idm/ServicesManager/script/.

			# PROVISIONING MODULE
			echo "Installing BMC Provisioning Module\n"
			su - $CTRLSA_USER -c "/opt/$CTRLSA_USER/bmc/idm/ServicesManager/bin/addPM.sh -f "$BIN_PATH/$OS_TYPE/PM/64-bit/Solaris26-V5.1.00.pmz" -silent" >> $LOG_FILE
			su - $CTRLSA_USER -c "/opt/$CTRLSA_USER/bmc/idm/ServicesManager/script/addMSCS.sh -pm Solaris26 -mscs $HOSTNAME -f /opt/$CTRLSA_USER/$HOSTNAME.properties" >> $LOG_FILE
		
		}
	;;
	esac

#############################################################################################################################

###############################
# INSTALL FUNCTIONS EXECUTION #
###############################

	## INSTALL ##
		
		[ $INSTALL_STATUS -ne 0 ] && echo "ERROR: A failure has been found in the BMC Patrol Previous Scripts." && exit 1
		
		echo "======================================================================"
                echo "Installing BMC SM/PM"
                echo "======================================================================\n"
		
		InstallControlSA
		[ $? -ne 0 ] && echo "ERROR: Please check the log file to verify the problem $LOG_FILE" && perl -e 's,INSTALL_STATUS=0,INSTALL_STATUS=1,g' -p -i $RESPONSE_FILE && exit 1

		ProvisioningModule
		[ $? -ne 0 ] && echo "ERROR: Please check the log file to verify the problem $LOG_FILE" && perl -e 's,INSTALL_STATUS=0,INSTALL_STATUS=1,g' -p -i $RESPONSE_FILE && exit 1
		
		echo "======================================================================"
        echo "BMC SM/PM Install scripts finished"
        echo "======================================================================\n"
		
		
