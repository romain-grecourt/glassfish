#!/bin/bash
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2017-2018 Oracle and/or its affiliates. All rights reserved.
#
# The contents of this file are subject to the terms of either the GNU
# General Public License Version 2 only ("GPL") or the Common Development
# and Distribution License("CDDL") (collectively, the "License").  You
# may not use this file except in compliance with the License.  You can
# obtain a copy of the License at
# https://oss.oracle.com/licenses/CDDL+GPL-1.1
# or LICENSE.txt.  See the License for the specific
# language governing permissions and limitations under the License.
#
# When distributing the software, include this License Header Notice in each
# file and include the License file at LICENSE.txt.
#
# GPL Classpath Exception:
# Oracle designates this particular file as subject to the "Classpath"
# exception as provided by Oracle in the GPL Version 2 section of the License
# file that accompanied this code.
#
# Modifications:
# If applicable, add the following below the License Header, with the fields
# enclosed by brackets [] replaced by your own identifying information:
# "Portions Copyright [year] [name of copyright owner]"
#
# Contributor(s):
# If you wish your version of this file to be governed by only the CDDL or
# only the GPL Version 2, indicate your decision by adding "[Contributor]
# elects to include this software in this distribution under the [CDDL or GPL
# Version 2] license."  If you don't indicate a single choice of license, a
# recipient has the option to distribute your version of this file under
# either the CDDL, the GPL Version 2 or to extend the choice of license to
# its licensees as provided above.  However, if you add GPL Version 2 code
# and therefore, elected the GPL Version 2 license, then the option applies
# only if the new code is made subject to such option by the copyright
# holder.
#

test_run(){
	cp -f ${APS_HOME}/devtests/security/ldap/opends/X500Signer.jar ${OPENDS_HOME}/lib

	# Configure and start OpenDS using the default ports
	${OPENDS_HOME}/setup \
    -i \
    -v \
    -n \
    -p 1389 \
    --adminConnectorPort 4444 \
    -x 1689 \
    -w dmanager \
    -b "dc=sfbay,dc=sun,dc=com" \
    -Z 1636 \
    --useJavaKeystore ${S1AS_HOME}/domains/domain1/config/keystore.jks \
    -W changeit \
    -N s1as

	${S1AS_HOME}/bin/asadmin start-database
	${S1AS_HOME}/bin/asadmin start-domain
	cd ${APS_HOME}/devtests/security

	ant ${TARGET} | tee ${TEST_RUN_LOG}

	${S1AS_HOME}/bin/asadmin stop-domain
	${S1AS_HOME}/bin/asadmin stop-database
	${OPENDS_HOME}/bin/stop-ds \
    -p 4444 \
    -D "cn=Directory Manager" \
    -w dmanager \
    -P ${OPENDS_HOME}/config/admin-truststore \
    -U ${OPENDS_HOME}/config/admin-keystore.pin

	egrep 'FAILED= *0' ${TEST_RUN_LOG}
	egrep 'DID NOT RUN= *0' ${TEST_RUN_LOG}
	cd -
}

get_test_target(){
	case $1 in
		security_all )
			TARGET=all
			export TARGET;;
	esac
}

merge_result_files(){
	cat ${APS_HOME}/test_resultsValid.xml ${APS_HOME}/security-gtest-results.xml > ${APS_HOME}/temp.xml
	mv ${APS_HOME}/temp.xml ${APS_HOME}/test_resultsValid.xml
}

run_test_id(){
  # setup opendj (fork of opends)
  wget https://github.com/OpenIdentityPlatform/OpenDJ/releases/download/4.1.10/opendj-4.1.10.zip
  unzip opendj-4.1.10.zip
  export OPENDS_HOME=${PWD}/opendj

	unzip_test_resources ${WORKSPACE}/bundles/glassfish.zip
	cd `dirname ${0}`
	test_init
	get_test_target ${1}
	test_run
	merge_result_files
	check_successful_run
  generate_junit_report ${1}
  change_junit_report_class_names
}

list_test_ids(){
	echo security_all
}

OPT=${1}
TEST_ID=${2}
source `dirname ${0}`/../../../common_test.sh

case ${OPT} in
	list_test_ids )
		list_test_ids;;
	run_test_id )
		trap "copy_test_artifacts ${TEST_ID}" EXIT
		run_test_id ${TEST_ID} ;;
esac
