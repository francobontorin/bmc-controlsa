#!/bin/ksh
################################################################################
#
# Documentation
# =============
# This is the install scripts for the BMC SM/PM Installation
# =============
#  Ver 1.0.0 - Created by Franco R Bontorin Silva
################################################################################

###################
# VARIABLE DECLARATION   #
###################

OS_TYPE=$(uname -s)
RESPONSE_FILE=/appvol/depot/superstacks_smpm_unix-5.1.0.101/SMPM.resp
LOG_FILE=/appvol/depot/superstacks_smpm_unix-5.1.0.101/superstacks_smpm-unix-5.1.0.101-$(date "+%Y-%m-%d").log
. $RESPONSE_FILE

###############################################################################################################################
# GLOBAL POST FUNCTIONS - Here are located the global functions that could be used by all platforms                            #
###############################################################################################################################

               function ControlsaInstalledDetails {

                        if [ -f /opt/$CTRLSA_USER/bmc/idm/ServicesManager/script/sm-details.sh ]
                        then
                                su - $CTRLSA_USER -c "/opt/$CTRLSA_USER/bmc/idm/ServicesManager/script/sm-details.sh" 2> /dev/null
                        fi

                }

  	function ControlsaStartAgent {

			if [ -f /opt/$CTRLSA_USER/bmc/idm/ServicesManager/script/start-sm.sh ]
			then
				su - $CTRLSA_USER -c "/opt/$CTRLSA_USER/bmc/idm/ServicesManager/script/sminit.sh" >> $LOG_FILE 2>&1
				su - $CTRLSA_USER -c "/opt/$CTRLSA_USER/bmc/idm/ServicesManager/script/start-sm.sh" >> $LOG_FILE 2>&1
			fi

                }
	
###############################################################################################################################
# INDIVIDUAL POST FUNCTIONS - Here are located only the functions that have particular configuration according each Platform   #
###############################################################################################################################

	
case $OS_TYPE in


 ###########
 #   AIX   #
 ###########


	(AIX)


        ##################
        #   CONTROL-SA   #
        ##################

		
			function ControlsaPost {
				
				# Chaging SMPARM.PRM file
				cat /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.PRM | sed "s/#PM_NAME#/AIX42/g" \
				| sed "s/FOREVERY PM_NAME_SKEL AIX42/FOREVERY PM_NAME_SKEL #PM_NAME#/" \
				| sed "s,%CTSROOT%,/opt/$CTRLSA_USER/bmc/idm/ServicesManager,g" > /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.BKP
				mv /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.BKP /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.PRM

                                # Changing MSCSPARM.PRM
                                cat /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.PRM | sed "s/ADMIN_FILE_REQ N/ADMIN_FILE_REQ Y/" \
                                | sed "s/AIX_DEF_USER_NAME default/AIX_DEF_USER_NAME $CTRLSA_USER/" \
				| sed "s/SUPPORT_LONG_GNAME N/SUPPORT_LONG_GNAME Y/" | sed "s/SUPPORT_LONG_UNAME N/SUPPORT_LONG_UNAME Y/" \
				| sed "/$(uname -n) SUPPORT_LONG_UNAME Y/{p;s/.*/$(uname -n) LOCK_TOKEN/;}" \
				> /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.BKP
                                mv /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.BKP /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.PRM
				
                                # Changing SMINIT.XML
                                [ ! -d /opt/$CTRLSA_USER/bmc/idm/ServicesManager/install ] && mkdir /opt/$CTRLSA_USER/bmc/idm/ServicesManager/install
                                cat /opt/$CTRLSA_USER/bmc/idm/ServicesManager/templates/SMINIT.XML | sed "s/#host-id#/$(uname -n)/" | \
                                sed "s/#port#/<CTRLSA_PORT>/" | sed "s/#encr#/Y/" > /opt/$CTRLSA_USER/bmc/idm/ServicesManager/install/SMINIT.XML

				# Creating PMPARM.PRM file
				
				[ ! -f /opt/$CTRLSA_USER/bmc/idm/ServicesManager/PM/AIX42/conf/PMPARM.PRM ]
				echo "* Do not change this file !!!" > /opt/$CTRLSA_USER/bmc/idm/ServicesManager/PM/AIX42/conf/PMPARM.PRM

                                # Switching the encryption to blowfish
                                chsec -f /etc/security/login.cfg -s usw -a "pwd_algorithm=sblowfish"
                                perl -e 's,DEFAULT_CRYPT des,DEFAULT_CRYPT 2a,' -p -i /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.PRM

			}
		

			function ControlsaInit {
				
				if [ -f /opt/$CTRLSA_USER/bmc/idm/ServicesManager/script/start-sm.sh  ]
				then
					cp /etc/inittab /etc/inittab_SMPM
					echo "smpm:2:once:su - $CTRLSA_USER -c \"/opt/$CTRLSA_USER/bmc/idm/ServicesManager/script/start-sm.sh\" \
					> /dev/console 2>&1" >> /etc/inittab
				fi
			} 


                        function ControlsaMOSFET {

                                # Fixing permissions to be MOSFET compliant
                                # Fixes sent by John Southall
                                [ -f /opt/$CTRLSA_USER/.com.zerog.registry.xml ] && chmod 644 /opt/$CTRLSA_USER/.com.zerog.registry.xml

                                [ -f /opt/$CTRLSA_USER/.cshrc?* ] && chmod 644 /opt/$CTRLSA_USER/.cshrc?*

                                [ -f /opt/$CTRLSA_USER/AIX42#$(uname -n)#OFLI_SEMAPHORE ] && rm -f /opt/$CTRLSA_USER/AIX42#$(uname -n)#OFLI_SEMAPHORE

                                chmod g-w /opt/$CTRLSA_USER/bmc
                                chmod g-w /opt/$CTRLSA_USER/bmc/idm
                                chmod g-w /opt/$CTRLSA_USER/bmc/idm/ServicesManager
                                chmod g-w /opt/$CTRLSA_USER/bmc/idm/ServicesManager/bin

                                chown $CTRLSA_USER:$CTRLSA_USER /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.PRM
                                chown $CTRLSA_USER:$CTRLSA_USER /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.PRM
                                cd /opt/$CTRLSA_USER/bmc/idm/ServicesManager/bin
                                chown root ctsadm ctssoffi p_ctscd p_ctscs apiver
                                chmod 4750 ctsadm ctssoffi p_ctscd p_ctscs apiver

                       }

	;;	

	
 ############
 #   SLES   #
 ############


	(Linux)

        if [ -f /etc/SuSE-release ]
        then

	
	##################
        #   CONTROL-SA   #
        ##################

                        function ControlsaPost {

                                # Chaging SMPARM.PRM file
                                cat /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.PRM | sed "s/#PM_NAME#/Linux/g" \
                                | sed "s/FOREVERY PM_NAME_SKEL Linux/FOREVERY PM_NAME_SKEL #PM_NAME#/" \
                                | sed "s,%CTSROOT%,/opt/$CTRLSA_USER/bmc/idm/ServicesManager,g" > /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.BKP
                                mv /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.BKP /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.PRM

				# Changing MSCSPARM.PRM
				cat /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.PRM | sed "s/ADMIN_FILE_REQ N/ADMIN_FILE_REQ Y/" \
                                | sed "s/SUPPORT_LONG_GNAME N/SUPPORT_LONG_GNAME Y/" | sed "s/SUPPORT_LONG_UNAME N/SUPPORT_LONG_UNAME Y/" \
                                | sed "/$(uname -n) SUPPORT_LONG_UNAME Y/{p;s/.*/$(uname -n) LOCK_TOKEN/;}" \
				> /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.BKP
				mv /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.BKP /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.PRM

                                # Changing SMINIT.XML
                                [ ! -d /opt/$CTRLSA_USER/bmc/idm/ServicesManager/install ] && mkdir /opt/$CTRLSA_USER/bmc/idm/ServicesManager/install
                                cat /opt/$CTRLSA_USER/bmc/idm/ServicesManager/templates/SMINIT.XML | sed "s/#host-id#/$(uname -n)/" | \
                                sed "s/#port#/<CTRLSA_PORT>/" | sed "s/#encr#/Y/" > /opt/$CTRLSA_USER/bmc/idm/ServicesManager/install/SMINIT.XML

                                # Creating PMPARM.PRM file

                                [ ! -f /opt/$CTRLSA_USER/bmc/idm/ServicesManager/PM/Linux/conf/PMPARM.PRM ] > /dev/null
                                echo "* Do not change this file !!!" > /opt/$CTRLSA_USER/bmc/idm/ServicesManager/PM/Linux/conf/PMPARM.PRM

	                        # Switching the encryption to blowfish
        	                perl -e 's,CRYPT_FILES=sha256,CRYPT_FILES=blowfish,' -p -i /etc/default/passwd
               		        perl -e 's,DEFAULT_CRYPT des,DEFAULT_CRYPT 2a,' -p -i /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.PRM
				
                        }


	                function ControlsaInit {

       				[ -f /etc/init.d/SMPM ] && rm -rf /etc/init.d/SMPM >> $LOG_FILE 2>&1

                        	cp $BIN_PATH/$OS_TYPE/auto_response/responseBMCsmpmInitLinux.rsp.org /etc/init.d/SMPM >> $LOG_FILE 2>&1
				perl -e 's,<CTRLSA_USER>,$CTRLSA_USER,' -p -i /etc/init.d/SMPM
				chkconfig -add SMPM >> $LOG_FILE 2>&1
                        	chkconfig SMPM on >> $LOG_FILE 2>&1
               		}


	                function ControlsaMOSFET {

       	                 	# Fixing permissions to be MOSFET compliant
                        	chown $CTRLSA_USER:$CTRLSA_USER /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.PRM
                        	chown $CTRLSA_USER:$CTRLSA_USER /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.PRM
                        	cd /opt/$CTRLSA_USER/bmc/idm/ServicesManager/bin
                        	chown root ctsadm ctssoffi p_ctscd p_ctscs apiver
                        	chmod 4750 ctsadm ctssoffi p_ctscd p_ctscs apiver

                        	[ -f /opt/$CTRLSA_USER/.com.zerog.registry.xml ] >> $LOG_FILE 2>&1
                        	chmod 644 /opt/$CTRLSA_USER/.com.zerog.registry.xml >> $LOG_FILE 2>&1

                        	[ -f /opt/$CTRLSA_USER/.cshrc?* ] >> $LOG_FILE 2>&1
                        	chmod 644 /opt/$CTRLSA_USER/.cshrc?* >> $LOG_FILE 2>&1
                        	[ -f /opt/$CTRLSA_USER/Linux#$(uname -n)#OFLI_SEMAPHORE ] && rm -f /opt/$CTRLSA_USER/Linux#$(uname -n)#OFLI_SEMAPHORE

                        	chmod g-w /opt/$CTRLSA_USER/bmc
                        	chmod g-w /opt/$CTRLSA_USER/bmc/idm
                        	chmod g-w /opt/$CTRLSA_USER/bmc/idm/ServicesManager
                        	chmod g-w /opt/$CTRLSA_USER/bmc/idm/ServicesManager/bin
                	}


 ############
 #   RHEL #
 ############

        elif [ -f /etc/redhat-release ]
        then

                ##################
                #   CONTROL-SA   #
                ##################

                function ControlsaPost {

                        # Chaging SMPARM.PRM file
                        cat /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.PRM | sed "s/#PM_NAME#/Linux/g" \
                        | sed "s/FOREVERY PM_NAME_SKEL Linux/FOREVERY PM_NAME_SKEL #PM_NAME#/" \
                        | sed "s,%CTSROOT%,/opt/$CTRLSA_USER/bmc/idm/ServicesManager,g" > /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.BKP
                        mv /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.BKP /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.PRM

                        # Changing MSCSPARM.PRM
                        cat /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.PRM | sed "s/ADMIN_FILE_REQ N/ADMIN_FILE_REQ Y/" \
                        | sed "s/SUPPORT_LONG_GNAME N/SUPPORT_LONG_GNAME Y/" | sed "s/SUPPORT_LONG_UNAME N/SUPPORT_LONG_UNAME Y/" \
                        | sed "/$(uname -n) SUPPORT_LONG_UNAME Y/{p;s/.*/$(uname -n) LOCK_TOKEN/;}" \
                        > /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.BKP
                        mv /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.BKP /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.PRM

                        # Creating PMPARM.PRM file
                        [ ! -f /opt/$CTRLSA_USER/bmc/idm/ServicesManager/PM/Linux/conf/PMPARM.PRM ]
                        echo "* Do not change this file !!!" > /opt/$CTRLSA_USER/bmc/idm/ServicesManager/PM/Linux/conf/PMPARM.PRM
                }

                function ControlsaInit {

                        [ -f /etc/init.d/SMPM ] && rm -rf /etc/init.d/SMPM >> $LOG_FILE 2>&1

                        cp $BIN_PATH/$OS_TYPE/auto_response/responseBMCsmpmInitLinux.rsp /etc/init.d/SMPM >> $LOG_FILE 2>&1
                        chkconfig --add SMPM >> $LOG_FILE 2>&1
                        chkconfig SMPM on >> $LOG_FILE 2>&1
                }

                function ControlsaMOSFET {

                        # Fixing permissions to be MOSFET compliant
                        chown $CTRLSA_USER:$CTRLSA_USER /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.PRM
                        chown $CTRLSA_USER:$CTRLSA_USER /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.PRM
                        cd /opt/$CTRLSA_USER/bmc/idm/ServicesManager/bin
                        chown root ctsadm ctssoffi p_ctscd p_ctscs apiver
                        chmod 4750 ctsadm ctssoffi p_ctscd p_ctscs apiver

                        [ -f /opt/$CTRLSA_USER/.com.zerog.registry.xml ] >> $LOG_FILE 2>&1
                        chmod 644 /opt/$CTRLSA_USER/.com.zerog.registry.xml >> $LOG_FILE 2>&1

                        [ -f /opt/$CTRLSA_USER/.cshrc?* ] >> $LOG_FILE 2>&1
                        chmod 644 /opt/$CTRLSA_USER/.cshrc?* >> $LOG_FILE 2>&1
                        [ -f /opt/$CTRLSA_USER/Linux#$(uname -n)#OFLI_SEMAPHORE ] && rm -f /opt/$CTRLSA_USER/Linux#$(uname -n)#OFLI_SEMAPHORE

                        chmod g-w /opt/$CTRLSA_USER/bmc
                        chmod g-w /opt/$CTRLSA_USER/bmc/idm
                        chmod g-w /opt/$CTRLSA_USER/bmc/idm/ServicesManager
                        chmod g-w /opt/$CTRLSA_USER/bmc/idm/ServicesManager/bin
                }
	fi

	;;


 #############
 #   SUNOS   #
 #############

	
	(SunOS)


        ##################
        #   CONTROL-SA   #
        ##################


                        function ControlsaPost {

                                # Chaging SMPARM.PRM file
                                cat /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.PRM | sed "s/#PM_NAME#/Solaris26/g" \
                                | sed "s/FOREVERY PM_NAME_SKEL Solaris26/FOREVERY PM_NAME_SKEL #PM_NAME#/" \
                                | sed "s,%CTSROOT%,/opt/$CTRLSA_USER/bmc/idm/ServicesManager,g" > /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.BKP
                                mv /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.BKP /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.PRM

                                # Changing MSCSPARM.PRM
                                cat /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.PRM | sed "s/ADMIN_FILE_REQ N/ADMIN_FILE_REQ Y/" \
                                | sed "s/SUPPORT_LONG_GNAME N/SUPPORT_LONG_GNAME Y/" | sed "s/SUPPORT_LONG_UNAME N/SUPPORT_LONG_UNAME Y/" \
                            	| sed "s/LOCK_TOKEN \*LK\*/LOCK_TOKEN /g" > /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.BKP
                                mv /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.BKP /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.PRM

                                # Changing SMINIT.XML
                                [ ! -d /opt/$CTRLSA_USER/bmc/idm/ServicesManager/install ] && mkdir /opt/$CTRLSA_USER/bmc/idm/ServicesManager/install
                                cat /opt/$CTRLSA_USER/bmc/idm/ServicesManager/templates/SMINIT.XML | sed "s/#host-id#/$(uname -n)/" | \
                                sed "s/#port#/<CTRLSA_PORT>/" | sed "s/#encr#/Y/" > /opt/$CTRLSA_USER/bmc/idm/ServicesManager/install/SMINIT.XML

                                # Creating PMPARM.PRM file

                                [ ! -f /opt/$CTRLSA_USER/bmc/idm/ServicesManager/PM/Solaris26/conf/PMPARM.PRM ]
                                echo "* Do not change this file !!!" > /opt/$CTRLSA_USER/bmc/idm/ServicesManager/PM/Solaris26/conf/PMPARM.PRM

                                # Switching the encryption to blowfish
                                perl -e 's,CRYPT_DEFAULT=5,CRYPT_DEFAULT=2a,' -p -i /etc/security/policy.conf
                                perl -e 's,DEFAULT_CRYPT des,DEFAULT_CRYPT 2a,' -p -i /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.PRM

                        }

                        function ControlsaMOSFET {

                                # Fixing permissions to be MOSFET compliant
                                # Fixes sent by John Southall
                                [ -f /opt/$CTRLSA_USER/.com.zerog.registry.xml ] && chmod 644 /opt/$CTRLSA_USER/.com.zerog.registry.xml

                                [ -f /opt/$CTRLSA_USER/.cshrc?* ] && chmod 644 /opt/$CTRLSA_USER/.cshrc?*

                                [ -f /opt/$CTRLSA_USER/Solaris#$(uname -n)#OFLI_SEMAPHORE ] && rm -f /opt/$CTRLSA_USER/Solaris#$(uname -n)#OFLI_SEMAPHORE

                                chmod g-w /opt/$CTRLSA_USER/bmc
                                chmod g-w /opt/$CTRLSA_USER/bmc/idm
                                chmod g-w /opt/$CTRLSA_USER/bmc/idm/ServicesManager
                                chmod g-w /opt/$CTRLSA_USER/bmc/idm/ServicesManager/bin

                                chown $CTRLSA_USER:$CTRLSA_USER /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/SMPARM.PRM
                                chown $CTRLSA_USER:$CTRLSA_USER /opt/$CTRLSA_USER/bmc/idm/ServicesManager/conf/MSCSPARM.PRM
                                cd /opt/$CTRLSA_USER/bmc/idm/ServicesManager/bin
                                chown root ctsadm ctssoffi p_ctscd p_ctscs apiver
                                chmod 4750 ctsadm ctssoffi p_ctscd p_ctscs apiver

                        }

                        function ControlsaInit {

				if [ -f /etc/init.d/SMPM ]
				then
					[ ! -L /etc/rc2.d/S99smpm ] && ln -sf /etc/init.d/SMPM /etc/rc2.d/S99smpm >> $LOG_FILE 2>&1
					[ ! -L /etc/rc3.d/S99smpm ] && ln -sf /etc/init.d/SMPM /etc/rc3.d/S99smpm >> $LOG_FILE 2>&1
					[ ! -L /etc/rc2.d/K99smpm ] && ln -sf /etc/init.d/SMPM /etc/rc2.d/K99smpm >> $LOG_FILE 2>&1
					[ ! -L /etc/rc3.d/K99smpm ] && ln -sf /etc/init.d/SMPM /etc/rc3.d/K99smpm >> $LOG_FILE 2>&1
					
				else
					case $ARCH in
					(sparc)
						cp $BIN_PATH/$OS_TYPE/auto_response/responseBMCsmpmInitSOL.rsp /etc/init.d/SMPM >> $LOG_FILE
					;;
					
					(i386)
						cp $BIN_PATH/$OS_TYPE/auto_response/responseBMCsmpmInitSOLx86.rsp /etc/init.d/SMPM >> $LOG_FILE
					;;
					esac
					[ ! -L /etc/rc2.d/S99smpm ] && ln -sf /etc/init.d/SMPM /etc/rc2.d/S99smpm >> $LOG_FILE 2>&1
					[ ! -L /etc/rc3.d/S99smpm ] && ln -sf /etc/init.d/SMPM /etc/rc3.d/S99smpm >> $LOG_FILE 2>&1
					[ ! -L /etc/rc2.d/K99smpm ] && ln -sf /etc/init.d/SMPM /etc/rc2.d/K99smpm >> $LOG_FILE 2>&1
					[ ! -L /etc/rc3.d/K99smpm ] && ln -sf /etc/init.d/SMPM /etc/rc3.d/K99smpm >> $LOG_FILE 2>&1
				fi
                        }
	;;
esac


#############################################################################################################################

############################
# POST INSTALL FUNCTIONS EXECUTION #
############################


		## POST SCRIPTS ##
		
			[ $INSTALL_STATUS -ne 0 ] && echo "ERROR: A failure has been found in the BMC Patrol Previous Scripts." && exit 1
			
			echo "======================================================================"
			echo "Initializing BMC SM/PM Post Scripts"
			echo "======================================================================\n"
			
			echo "Configuring Control-SA Log Rotate, Encryption Key and Flags"
			ControlsaPost
			[ $? -ne 0 ] && echo "WARNING: Please check the log file to verify the problem $LOG_FILE"

			ControlsaInit
			[ $? -ne 0 ] && echo "WARNING: Please check the log file to verify the problem $LOG_FILE"
			
			ControlsaStartAgent
			[ $? -ne 0 ] && echo "WARNING: Please check the log file to verify the problem $LOG_FILE"
			
			ControlsaMOSFET
			[ $? -ne 0 ] && echo "WARNING: Please check the log file to verify the problem $LOG_FILE"

			ControlsaInstalledDetails
			
			echo "======================================================================"
			echo "BMC SM/PM Post Scripts finished with success"
			echo "======================================================================\n"
			
			
