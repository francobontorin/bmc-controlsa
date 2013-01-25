#!/bin/bash
################################################################################
#
# Documentation
# =============
# This is the pre script used to prepare the environment for the BMC SM/PM Installation
# =============
#  Ver 1.0.0 - Created by Franco Bontorin
################################################################################

###################
# VARIABLE DECLARATION   #
###################
OS_TYPE=$(uname -s)
HOSTNAME=$(uname -n)
RESPONSE_FILE=/appvol/depot/superstacks_smpm_unix-5.1.0.101/SMPM.resp
. $RESPONSE_FILE


  #############################################################
	# Identify whether SM/PM is already installed or not, if is installed the new installation will be aborted    #
	#############################################################
	
                function SMPMAlreadyInstalled {

                        if [ -f /opt/$CTRLSA_USER/bmc/idm/ServicesManager/script/sm-details.sh ]
                        then
                                echo "BMC SM/PM is already Installed"
				perl -e 's,INSTALL_STATUS=0,INSTALL_STATUS=1,g' -p -i $RESPONSE_FILE
				return 1
                        else
                                echo "None version of SM/PM were found on this server\n"
				return 0
                        fi
                }

		
	#########################################################
	# Searches for previous Control-SA versions. If find it starts automatically the uninstall process  #
	#########################################################
		
                function ControlsaAlreadyInstalled {

                        if [ -f /opt/ctsa/control-sa/scripts/agent-details.sh ]
			then
				CTRLSA_OWNER=ctsa
				
			elif [ -f /opt/ctprdagt/control-sa/scripts/agent-details.sh ]
			then
				CTRLSA_OWNER=ctprdagt
			fi	

                        if [ ! -z "$CTRLSA_OWNER" ]
                        then
                               	if [ -f /opt/$CTRLSA_OWNER/control-sa/USA-API/*/usaapi.dat ]
				then
					CTRLSA_VERSION=$(egrep "^UA_VERSION" /opt/$CTRLSA_OWNER/control-sa/USA-API/*/usaapi.dat |awk -F= '{ print $2 }'| cut -c1-6)
				fi

				if [ -f /opt/$CTRLSA_OWNER/control-sa/install/fdnum.txt ]
				then
					CTRLSA_VERSION=$(cat /opt/$CTRLSA_OWNER/control-sa/install/fdnum.txt | awk '{ print $1 }' | cut -c 7-16)
				fi
	
                                echo "There is an other version of Control-SA running on this box"
                                echo "Installed version: $CTRLSA_VERSION"
                                echo "This version will be upgraded to SM/PM 5.1.00.101\n"
				sleep 5
                                ControlSAUninstall
			else
				echo "No previous versions of Control-SA were found in this server ($HOSTNAME)\n"
                        fi
                }		

		
	##############################################
	# When previous versions of Control-SA is found the uninstall process starts    #
	##############################################
	
                function ControlSAUninstall {

			echo "Stopping Control-SA agent to start the upgrade process"
			su - $CTRLSA_OWNER -c "/opt/$CTRLSA_OWNER/control-sa/scripts/stop-ctsa" > /dev/null
			sleep 15
			
			echo "Control-SA $CTRLSA_VERSION Uninstallation Process Initialized"
			if [ -f /opt/$CTRLSA_OWNER/control-sa/install/uninstall_ctsa ]
			then
				/opt/$CTRLSA_OWNER/control-sa/install/uninstall_ctsa <<EOF
/opt/$CTRLSA_OWNER/control-sa
Y
EOF
				
			fi

			#Removing user home
			if [ "$OS_TYPE" == "AIX" ]
			then
				if [ "$CTRLSA_OWNER" == "ctsa" ]
				then
					rm -rf /opt/$CTRLSA_OWNER/* 
				else
					rm -rf /opt/$CTRLSA_OWNER 
				fi
			else
				rm -rf /opt/$CTRLSA_OWNER 
			fi

			case $OS_TYPE in

				(AIX)
					rmuser -p $CTRLSA_OWNER 
					rmgroup -p $CTRLSA_OWNER 

				;;

				(SunOS | Linux)

					userdel $CTRLSA_OWNER 
					groupdel $CTRLSA_OWNER 

				;;
			esac
			echo "Control-SA ($CTRLSA_VERSION) uninstalled with success\n"
			                      
                }
		
	######################
	# Creating SM/PM Group and User    #
	######################

                function ControlsaCreateUserAndGroup {

                        # Create ctsa Group
                        grep "^$CTRLSA_GRP:" /etc/group >> /dev/null
                        if [ $? -ne 0 ]
                        then
                                if [ "$OS_TYPE" == "AIX" ]
                                then
                                        mkgroup -A id=$CTRLSA_GRP_ID $CTRLSA_GRP 
                                else
                                        groupadd -g $CTRLSA_GRP_ID $CTRLSA_GRP 
                                fi
				echo "Group $CTRLSA_GRP ID:$CTRLSA_GRP_ID created with success"
                        else
                                echo "Group $CTRLSA_GRP already created"
                        fi
			
                        # Create the user agent
                        grep "^$CTRLSA_USER:" /etc/passwd >> /dev/null
                        if [ $? -ne 0 ]
                        then
                                useradd -m -d /opt/$CTRLSA_USER -s /bin/csh -g $CTRLSA_GRP -u $CTRLSA_USER_ID $CTRLSA_USER 
                                chown $CTRLSA_USER:$CTRLSA_GRP /opt/$CTRLSA_USER >> /dev/null
                                echo "User $CTRLSA_USER ID:$CTRLSA_USER_ID created with success"
                        else
                                if [ ! -d /opt/$CTRLSA_USER ]
                                then
                                        mkdir /opt/$CTRLSA_USER
                                        chown $CTRLSA_USER:$CTRLSA_GRP /opt/$CTRLSA_USER >> /dev/null
                                else
                                        echo "Directory already created"
                                fi
                        fi
                }
	
	################################
	# Creates the response file that drives the installation #
	################################		
		
		
		function ControlsaPrepareAutoResponse {
		
			tail -13 $RESPONSE_FILE  > /opt/$CTRLSA_USER/autoinst.ini
						
			# Copying .login and .cshrc.org files from Gold Library
			cp $BIN_PATH/$OS_TYPE/.cshrc.org /opt/$CTRLSA_USER/.
			cp $BIN_PATH/$OS_TYPE/.login /opt/$CTRLSA_USER/.
			
			cp $BIN_PATH/$OS_TYPE/host.properties /opt/$CTRLSA_USER/$HOSTNAME.properties
			cat /opt/$CTRLSA_USER/$HOSTNAME.properties | sed "s/CTRLSA_USER/$CTRLSA_USER/"  > /opt/$CTRLSA_USER/properties
			mv /opt/$CTRLSA_USER/properties /opt/$CTRLSA_USER/$HOSTNAME.properties
			chmod 755 /opt/$CTRLSA_USER/$HOSTNAME.properties
			
			if [ -z "$ENCRY_PATH" ] || [ ! -f "$ENCRY_PATH" ]
			then
				cat /opt/$CTRLSA_USER/autoinst.ini | sed "s,ENCRY_STATUS=Y,ENCRY_STATUS=N," \
				| sed "s,ENCRY_PATH=$ENCRY_PATH,#ENCRY_PATH=$ENCRY_PATH," > /opt/$CTRLSA_USER/auto.ini
				mv /opt/$CTRLSA_USER/auto.ini /opt/$CTRLSA_USER/autoinst.ini
			else
				chmod 755 $ENCRY_PATH
			fi
			
			chmod a+x /opt/$CTRLSA_USER/autoinst.ini
			chown -R $CTRLSA_USER:$CTRLSA_GRP /opt/$CTRLSA_USER >> /dev/null			
		}
		
#############################################################################################################################

#####################
# PRE FUNCTIONS EXECUTION #
#####################


                ## PREVIOUS INSTALLATIONS

                        echo "======================================================================"
                        echo "Searching for previous versions of Control-SA"
                        echo "======================================================================\n"
                                         
			ControlsaAlreadyInstalled

                ## PRE SCRIPTS ##
			
                        echo "======================================================================"
                        echo "Verifying if BMC SM/PM is already installed"
                        echo "======================================================================\n"
                      		
                        SMPMAlreadyInstalled
                        [ $? -ne 0 ] && return 2

			echo "======================================================================"
                        echo "Initializing BMC SM/PM Pre Installation Scripts"
                        echo "======================================================================"
                      		
                        echo "Creating User and Group"
                        ControlsaCreateUserAndGroup

                        echo "Preparing Auto Resp Files"
                        ControlsaPrepareAutoResponse
			
                        echo "======================================================================"
                        echo "BMC SM/PM Pre Installation Scripts finished"
                        echo "======================================================================"
      
