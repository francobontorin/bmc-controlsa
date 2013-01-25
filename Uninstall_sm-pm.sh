#!/bin/ksh
################################################################################
#
# Documentation
# =============
# This is the Uninstall scripts for the BMC SM/PM Installation
# =============
#  Ver 1.0.0 - Created by Franco R Bontorin Silva
################################################################################

##########################
# VARIABLE DECLARATION   #
##########################

OS_TYPE=$(uname -s)
RESPONSE_FILE=/appvol/depot/superstacks_smpm_unix-5.1.0.101/SMPM.resp
LOG_FILE=/appvol/depot/superstacks_smpm_unix-5.1.0.101/uninstall-superstacks_smpm-unix-5.1.0.101-$(date "+%Y-%m-%d").log
. $RESPONSE_FILE

#################################################################################################################
# GLOBAL UNINSTALL FUNCTIONS - Here are located the global functions used by all platforms                      #
#################################################################################################################


        ##################
        #   CONTROL-SA   #
        ##################

              function ControlsaStoppingAgent {

                        if [ -f /opt/$CTRLSA_USER/bmc/idm/ServicesManager/script/stop-sm.sh ]
                        then
                                su - $CTRLSA_USER -c "/opt/$CTRLSA_USER/bmc/idm/ServicesManager/script/stop-sm.sh" >> $LOG_FILE 2>&1
                                sleep 10
                                su - $CTRLSA_USER -c "/opt/$CTRLSA_USER/bmc/idm/ServicesManager/script/kill-sm.sh" >> $LOG_FILE 2>&1

                                case $OS_TYPE in

                                        (AIX)
                                          # Switching back the encryption to SHA256
                                                chsec -f /etc/security/login.cfg -s usw -a "pwd_algorithm=ssha256"

                                        ;;

                                        (SunOS)

                                                # Switching back the encryption to SHA256
                                                perl -e 's,CRYPT_DEFAULT=2a,CRYPT_DEFAULT=5,' -p -i /etc/security/policy.conf
                                        
					;;

                                        (Linux)

                                                # Switching back the encryption to SHA256
                                                perl -e 's,CRYPT_FILES=blowfish,CRYPT_FILES=sha256,' -p -i /etc/default/passwd
                                        ;;
                                esac

                        fi

               }


               function UninstallControlSA {

			if [ -f /opt/$CTRLSA_USER/bmc/idm/ServicesManager/install/Uninstall.sh ]
                        then
                                su - $CTRLSA_USER -c "/opt/$CTRLSA_USER/bmc/idm/ServicesManager/install/Uninstall.sh -i silent" >> $LOG_FILE
                        fi

			
                }

                function ControlsaRemovingUsers {

                        #Remove the user home
                        if [ -d /opt/$CTRLSA_USER ] && [ ! -z $CTRLSA_USER ]
                        then
                               	if [ "$(uname)" == "AIX" ]
				then
					if [ "$CTRLSA_USER" == "ctsa" ]
					then	
						rm -rf /opt/$CTRLSA_USER/* >> $LOG_FILE 2>&1
					else
						rm -rf /opt/$CTRLSA_USER >> $LOG_FILE 2>&1
					fi
				else
					rm -rf /opt/$CTRLSA_USER >> $LOG_FILE 2>&1
				fi
				
			fi	
					case $OS_TYPE in
					
					(AIX)
						rmuser -p $CTRLSA_USER >> $LOG_FILE 2>&1
						rmgroup -p $CTRLSA_GRP >> $LOG_FILE 2>&1
					
					;;
					(SunOS | Linux)
	
						userdel $CTRLSA_USER >> $LOG_FILE 2>&1
                        			groupdel $CTRLSA_GRP >> $LOG_FILE 2>&1
					;;
					esac
                }

		function ControlsaRemovingInit {

                        if [ -f /etc/init.d/ControlSA ]
                        then
                                chkconfig ControlSA off >> $LOG_FILE 2>&1
                                rm -rf /etc/init.d/ControlSA >> $LOG_FILE 2>&1
                        fi

                        if [ -f /etc/init.d/SMPM ]
                        then
                                case $OS_TYPE in

                                (Linux)
                                        chkconfig SMPM off >> $LOG_FILE 2>&1
                                        rm -rf /etc/init.d/SMPM >> $LOG_FILE 2>&1
                                ;;
                                (SunOS)
                                        case $ARCH in

                                        (sparc)
                                                rm -rf /etc/init.d/SMPM >> $LOG_FILE 2>&1
                                                if [ -f /etc/rc2.d/S99smpm ]
                                                then
                                                        rm -rf /etc/rc2.d/S99smpm >> $LOG_FILE 2>&1
                                                fi
                                        ;;
                                        (i386)
						rm -rf /etc/init.d/SMPM >> $LOG_FILE 2>&1
						if [ -f /etc/rc2.d/S99smpm ]
						then
							rm -rf /etc/rc2.d/S99smpm >> $LOG_FILE 2>&1
						fi
                                        ;;
                                        esac
                                ;;
                                esac
                        fi
                }

#############################################################################################################################

#################################
# UNINSTALL FUNCTIONS EXECUTION #
#################################

		echo -e "======================================================================"
    echo "Uninstalling BMC SM/PM"
    echo "======================================================================"
		
		UninstallControlSA
		[ $? -ne 0 ] && echo "WARNING: Please check the log file to verify the problem $LOG_FILE"

		echo "Removing Users and Group"
		ControlsaRemovingUsers
		[ $? -ne 0 ] && echo "WARNING: Please check the log file to verify the problem $LOG_FILE"
		
		echo "Removing init entries"
		ControlsaRemovingInit	
		
		echo -e "======================================================================"
        echo "BMC SM/PM uninstall scripts finished"
        echo -e "======================================================================\n"
