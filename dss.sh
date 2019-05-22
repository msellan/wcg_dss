#!/usr/local/bin/bash

set -euo pipefail

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+ World Community Grid Data Processing Script
#+
#+ This script is a screen scraping utility to download data from the World
#+ Community Grid "Device Statistics History" page that's not provided in their
#+ API.  The script isolates the table of data and then uses a series of regular
#+ expressions to match the data in the table and outputs a pipe | seperated
#+ file since the data contains too many other commonly used delimiters. 
#+ 
#+ Screen scraping is a last resort method and is likely to be fragile. The 
#+ script uses a utility, 'wget' to retrieve the WCG security_check page and 
#+ associated session cookies and posts that data along with a WCG UserID
#+ and Password.  Those values are stored in seperate file and then sourced.
#+ 
#+ For robust regular expression matching, this script also uses a newer version
#+ of Bash than is installed on MacOS by default. It uses Bash v 5.0 which on 
#+ MacOS can be installed using Homebrew.
#+
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+
#+ By Mark Sellan
#+
#+ Created May 11, 2019
#+
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+
#+ License
#+
#+ Copyright (C) 2019 Mark Sellan
#+
#+  This program is free software: you can redistribute it and/or modify it 
#+  under the terms of the GNU General Public License as published by the Free
#+  Software Foundation, either version 3 of the License, or (at your option)
#+  any later version.
#+
#+  This program is distributed in the hope that it will be useful, but WITHOUT
#+  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#+  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License 
#+  for more details.
#+
#+  You should have received a copy of the GNU General Public License along 
#+  with this program.  If not, see <https://www.gnu.org/licenses/>.
#+
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
#  Change History
#
#  05-11-19 - Initial commit 
#  05-15-19 - Added authentication functionality
#  05-17-19 - Added data archiving functionality
#	     
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#---------> Define global variables <-------------------------------------------
#
#  Setting constants and "global" variables
#
#-------------------------------------------------------------------------------

source dss_env.sh

PATH="${PATH}":~/Downloads:/usr/bin:/usr/local/bin
SCRIPT=$(basename $0)
DATA_DIR=~/Downloads
OUTPUT_FILE="${DATA_DIR}/device_stats.dat"
INPUT_FILE="${DATA_DIR}/devicestats.html"
WCG_SECURITY_URL=https://www.worldcommunitygrid.org/j_security_check
DEVICE_URL=https://www.worldcommunitygrid.org/ms/device/viewStatisticsByDevice.do?installedSince=0\&lastResult=0

#----------> Login to WCG <--------------------------------------------------
#
#  Login to the WCG using wget to create a session for use in subsequent
#  requests. This information was found in the WCG forums.  Post/thread:
#  https://www.worldcommunitygrid.org/forums/wcg/ \
#          viewthread_thread,40823_offset,20#582183
#
#------------------------------------------------------------------------------- 

wcg_login () {

wget --save-cookies "${COOKIE_JAR}" \
     --keep-session-cookies \
     --post-data 'j_username='"${wcg_userid}"'&j_password='"${wcg_password}" \
     --delete-after \
     "${WCG_SECURITY_URL}"
}

#----------> Get device history page  <-----------------------------------------
#
#  Once the user is logged in, we can make another wget request to download the
#  Device History page to pull data from.
#
#-------------------------------------------------------------------------------

get_device_history () {

#wget -qO ~/Downloads/devicestats.html --load-cookies "${COOKIE_JAR}" \
wget -qO "${INPUT_FILE}" --load-cookies "${COOKIE_JAR}" \
     "${DEVICE_URL}"
}


#----------> Preprocess html <--------------------------------------------------
#
#  Use an 'ex' editor heredoc to strip out as much unneccesary html as possible 
#  to make it unlikely to get an unexpected match on a non-datapoint.
#
#------------------------------------------------------------------------------- 

preprocess_html () {

ex "${INPUT_FILE}" <<EOF
        g/Points<br>Generated/1,.-1d
        1d5
        g/height="40"/d
        g/images/d
        g/tr/d
        g/middleColumnCloser/.+1,\$d
        g/table/d
        g/form/d
        g/middleColumnCloser/d
        wq!
EOF
}

#----------> Process page data <-------------------------------------------
#
#  Read the HTML file line by line and use a series of regex matches to 
#  extract the relevant table data.
#
#------------------------------------------------------------------------------- 

process_page () {

i=0
while read -r line; do

    if [[ "${line}" =~ deviceId ]]; then
        i=1
        if [[ "${line}" =~ [0-9]{7} ]]; then
            printf "${BASH_REMATCH[0]}|" >> "${OUTPUT_FILE}"
        fi
    #future work - insert test for device name here
    
    elif [[ "${line}" =~ [0-9]{2}\/[0-9]{2}\/[0-9]{4}' '([0-9]{1,3}:)([0-9]{1,3}:)([0-9]{2}) ]] && [[ $i -eq 2 ]]; then
            printf "${BASH_REMATCH[0]}|" >> "${OUTPUT_FILE}"

    elif [[ "${line}" =~ ([0-9]{1,3}:)([0-9]{1,3}:)([0-9]{2}:)([0-9]{2}:)([0-9]{2}) ]] && [[ $i -eq 3 ]]; then
            printf "${BASH_REMATCH[0]}|" >> "${OUTPUT_FILE}"

    elif [[ "${line}" =~ [0-9]{1,3}(,[0-9]{3})* ]] && [[ $i -eq 4 ]]; then
            printf "${BASH_REMATCH[0]}|" >> "${OUTPUT_FILE}"
    
    elif [[ "${line}" =~ [0-9]{1,3}(,[0-9]{3})* ]] && [[ $i -eq 5 ]]; then
            printf "${BASH_REMATCH[0]}|" >> "${OUTPUT_FILE}"
    fi

    ((i++))
 
    if [[ $i -eq 6 ]]; then
        printf "\n" >> "${OUTPUT_FILE}"
        i=0
    fi

done < "${INPUT_FILE}"

}

#----------> Archive Results <-------------------------------------------
#
#  Archive_results function moves the datafile returned by the WCG and
#  the ouput file generated by the process_page function to date and 
#  timestamped filenames and thus clears the original names for the 
#  next run.
#
#------------------------------------------------------------------------------- 

archive_results () {

    if [[ -s "${OUTPUT_FILE}" ]]; then
	date_stamp=$(date +%Y-%m-%d.%H:%M:%S)
	mv "${OUTPUT_FILE}" "${OUTPUT_FILE}"."${date_stamp}"
	mv "${INPUT_FILE}" "${INPUT_FILE}"."${date_stamp}"
    fi
}


#Main

wcg_login
get_device_history
preprocess_html
process_page
archive_results
