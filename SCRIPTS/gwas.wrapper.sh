#!/bin/bash

### Creating display functions
### Setting colouring
NONE='\033[00m'
BOLD='\033[1m'
FLASHING='\033[5m'
UNDERLINE='\033[4m'

RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'

function echobold { #'echobold' is the function name
    echo -e "${BOLD}${1}${NONE}" # this is whatever the function needs to execute, note ${1} is the text for echo
}
function echoerrorflash { 
    echo -e "${RED}${BOLD}${FLASHING}${1}${NONE}" 
}
function echoerror { 
    echo -e "${RED}${1}${NONE}"
}
function echosucces { 
    echo -e "${YELLOW}${1}${NONE}"
}

script_copyright_message() {
	echo ""
	THISYEAR=$(date +'%Y')
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "+ The MIT License (MIT)                                                                                 +"
	echo "+ Copyright (c) 2015-${THISYEAR} Sander W. van der Laan                                                        +"
	echo "+                                                                                                       +"
	echo "+ Permission is hereby granted, free of charge, to any person obtaining a copy of this software and     +"
	echo "+ associated documentation files (the \"Software\"), to deal in the Software without restriction,         +"
	echo "+ including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, +"
	echo "+ and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, +"
	echo "+ subject to the following conditions:                                                                  +"
	echo "+                                                                                                       +"
	echo "+ The above copyright notice and this permission notice shall be included in all copies or substantial  +"
	echo "+ portions of the Software.                                                                             +"
	echo "+                                                                                                       +"
	echo "+ THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT     +"
	echo "+ NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND                +"
	echo "+ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES  +"
	echo "+ OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN   +"
	echo "+ CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                            +"
	echo "+                                                                                                       +"
	echo "+ Reference: http://opensource.org.                                                                     +"
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}

script_arguments_error() {
	echoerror "$1" # Additional message
	echoerror "- Argument #1 is path_to/ the raw, parsed and harmonized GWAS data."
	echoerror "- Argument #2 is the cohort name."
	echoerror "- Argument #3 is 'basename' of the cohort data file."
	echoerror "- Argument #4 is the variant type used in the GWAS data."
	echoerror ""
	echoerror "An example command would be: gwas.wrapper.sh [arg1] [arg2] [arg3] [arg4]"
	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
 	echo ""
	script_copyright_message
	exit 1
}

echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echobold "          GWASWRAPPER: WRAPPER FOR PARSED AND CLEANED GENOME-WIDE ASSOCIATION STUDIES"
echobold ""
echobold "* Version:      v1.0.1"
echobold ""
echobold "* Last update:  2018-03-22"
echobold "* Written by:   Sander W. van der Laan | s.w.vanderlaan@gmail.com."
echobold "* Description:  Produce concatenated parsed, and cleaned GWAS data."
echobold ""
echobold "* REQUIRED: "
echobold "  - A high-performance computer cluster with a qsub system"
echobold "  - R v3.2+, Python 2.7+, Perl."
echobold "  - Required Python 2.7+ modules: [pandas], [scipy], [numpy]."
echobold "  - Required Perl modules: [YAML], [Statistics::Distributions], [Getopt::Long]."
echobold "  - Note: it will also work on a Mac OS X system with R and Python installed."
### ADD-IN: function to check requirements...
### This might be a viable option! https://gist.github.com/JamieMason/4761049
echobold ""
echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

##########################################################################################
### SET THE SCENE FOR THE SCRIPT
##########################################################################################

### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 4 ]]; then 
	echo ""
	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echoerrorflash "               *** Oh, computer says no! Number of arguments found "$#". ***"
	echoerror "You must supply [4] arguments when running *** GWASWRAPPER -- MetaGWASToolKit ***!"
	script_arguments_error
else
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Processing arguments..."
	# Loading the configuration file (please refer to the GBASToolKit-Manual for specifications of this file). 
	source "$1" # Depends on arg1.
	
	CONFIGURATIONFILE="$1" # Depends on arg1 -- but also on where it resides!!!
	PROJECTDIR=${2} # depends on arg1
	COHORTNAME=${3} # depends on arg2
	BASEFILENAME=${4} # depends on arg3

	echo ""
	echo "All arguments are passed. These are the settings:"
	echo "Project directory.......................: "${PROJECTDIR}
	echo "Cohort name.............................: "${COHORTNAME}
	echo "Cohort's raw file name..................: "${BASEFILENAME}.txt.gz
	echo "The basename of the cohort is...........: "${BASEFILENAME}
	echo "Was quality control applied?............: "${GWASQC}
	
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Wrapping up split files and checking parsing and harmonizing..."
	echo ""
	
	echo "* Making necessary 'readme' files..."
	echo "Cohort File Parsing ParsingErrorFile" > ${PROJECTDIR}/${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.wrap.parsed.readme

	### HEADER .pdat-file
	### Marker	MarkerOriginal	CHR	BP	Strand	EffectAllele	OtherAllele	MinorAllele	MajorAllele	EAF	MAF	MAC	HWE_P	Info	Beta	BetaMinor	SE	P	N	N_cases	N_controls	Imputed
	### 1	    2               3   4   5       6               7           8           9           10  11  12  13      14      15      16          17  18  19  20      21          22

	echo ""	
	echo "* Making necessary 'summarized' files..."
	echo "Marker	MarkerOriginal	CHR	BP	Strand	EffectAllele	OtherAllele	MinorAllele	MajorAllele	EAF	MAF	MAC	HWE_P	Info	Beta	BetaMinor	SE	P	N	N_cases	N_controls	Imputed" > ${PROJECTDIR}/${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.pdat

	### Setting the patterns to look for -- never change this
	PARSEDPATTERN="All done parsing"

	echo ""
	echo "We will look for the following pattern in the ..."
	echo "...parsed log file...........: [ ${PARSEDPATTERN} ]"

	echo ""
	echo "* Check parsing of GWAS datasets."
	for ERRORFILE in ${PROJECTDIR}/gwas.parser.${BASEFILENAME}.*.log; do
		### determine basename of the ERRORFILE
		echo $ERRORFILE
		BASENAMEERRORFILE=$(basename ${ERRORFILE})
		BASEERRORFILE=$(basename ${ERRORFILE} .log)
		prefix_parsed='gwas.parser.' # removing the 'gwas.parser.'-part from the ERRORFILE
		BASEPARSEDFILE=$(echo "${BASEERRORFILE}" | sed -e "s/^$prefix_parsed//")
		echo ""
		echo "* checking split chunk: [ ${BASEPARSEDFILE} ] for pattern \"${PARSEDPATTERN}\"..."

		echo "Error file...........................:" ${BASENAMEERRORFILE}
		if [[ ! -z $(grep "${PARSEDPATTERN}" "${ERRORFILE}") ]]; then 
			PARSEDMESSAGE=$(echosucces "successfully parsed")
			PARSEDMESSAGEREADME=$(echo "success")
			echo "Parsing report.......................: ${PARSEDMESSAGE}"
			echo "${COHORTNAME} ${BASEFILENAME}.txt.gz ${PARSEDMESSAGEREADME} ${BASENAMEERRORFILE}" >> ${PROJECTDIR}/${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.wrap.parsed.readme
			echo "- concatenating data to [ ${PROJECTDIR}/${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.pdat ]..."
			cat ${PROJECTDIR}/${BASEPARSEDFILE}.pdat | tail -n +2 | awk -F '\t' '{ print $0 }' >> ${PROJECTDIR}/${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.pdat
			echo "- removing files [ ${PROJECTDIR}/${BASEPARSEDFILE}[.pdat/.errors/.log] ]..."
			rm -v ${PROJECTDIR}/${BASEPARSEDFILE}.pdat
			rm -v ${PROJECTDIR}/${prefix_parsed}${BASEPARSEDFILE}.errors
			rm -v ${PROJECTDIR}/${prefix_parsed}${BASEPARSEDFILE}.log
			rm -v ${PROJECTDIR}/${prefix_parsed}${BASEPARSEDFILE}.sh
			rm -v ${PROJECTDIR}/${BASEPARSEDFILE}
# 			rm -v ${PROJECTDIR}/*${BASEPARSEDFILE}_DEBUG_GWAS_PARSER.RData
		else
			echoerrorflash "*** Error *** The pattern \"${PARSEDPATTERN}\" was NOT found in [ ${BASENAMEERRORFILE} ]..."
			echoerror "Reported in the [ ${BASENAMEERRORFILE} ]:      "
			echoerror "####################################################################################"
			cat ${ERRORFILE}
			echoerror "####################################################################################"
			PARSEDMESSAGE=$(echosucces "parsing failure")
			PARSEDMESSAGEREADME=$(echo "failure")
			echo "Parsing report.......................: ${PARSEDMESSAGE}"
			echo "${COHORTNAME} ${BASEFILENAME}.txt.gz ${PARSEDMESSAGEREADME} ${BASENAMEERRORFILE}" >> ${PROJECTDIR}/${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.wrap.parsed.readme
		fi
	
		echo ""
	done

	echo ""
	if [[ ${GWASQC} = "YES" ]]; then
		
		echo "GWAS quality control was applied -- wrapping up these results."
		echo ""
		echo "* Making necessary 'readme' files..."
		echo "Cohort File Cleaning CleaningErrorFile" > ${PROJECTDIR}/${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.wrap.cleaned.readme
	
		### HEADER .pdat-file
		### Marker	MarkerOriginal	CHR	BP	Strand	EffectAllele	OtherAllele	MinorAllele	MajorAllele	EAF	MAF	MAC	HWE_P	Info	Beta	BetaMinor	SE	P	N	N_cases	N_controls	Imputed
		### 1	    2               3   4   5       6               7           8           9           10  11  12  13      14      15      16          17  18  19  20      21          22
	
		echo ""	
		echo "* Making necessary 'summarized' files..."
		echo "VariantID	Marker	MarkerOriginal	CHR	BP	Strand	EffectAllele	OtherAllele	MinorAllele	MajorAllele	EAF	MAF	MAC	HWE_P	Info	Beta	BetaMinor	SE	P	N	N_cases	N_controls	Imputed	Reference VT" > ${PROJECTDIR}/${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.cdat
	
		### Setting the patterns to look for -- never change this
		CLEANEDPATTERN="All done cleaning"
		
		echo ""
		echo "We will look for the following pattern in the ..."
		echo "...cleaned log file..........: [ ${CLEANEDPATTERN} ]"
		
		echo ""
		echo "* Check cleaning of parsed GWAS datasets."
		for ERRORFILE in ${PROJECTDIR}/gwas.cleaner.${BASEFILENAME}.*.log; do
			### determine basename of the ERRORFILE
			BASENAMEERRORFILE=$(basename ${ERRORFILE})
			BASEERRORFILE=$(basename ${ERRORFILE} .log)
			prefix_cleaned='gwas.cleaner.' # removing the 'gwas2ref.harmonizer.'-part from the ERRORFILE
			BASECLEANEDFILE=$(echo "${BASEERRORFILE}" | sed -e "s/^$prefix_cleaned//")
			echo ""
			echo "* checking split chunk: [ ${BASECLEANEDFILE} ] for pattern \"${CLEANEDPATTERN}\"..."
	
			echo "Error file...........................:" ${BASENAMEERRORFILE}
			if [[ ! -z $(grep "${CLEANEDPATTERN}" "${ERRORFILE}") ]]; then 
				CLEANEDMESSAGE=$(echosucces "successfully cleaned")
				CLEANEDMESSAGEREADME=$(echo "success")
				echo "Cleaning report......................: ${CLEANEDMESSAGE}"
				echo "- concatenating data to [ ${PROJECTDIR}/${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.cdat ]..."
				echo "${COHORTNAME} ${BASEFILENAME}.txt.gz ${CLEANEDMESSAGEREADME} ${BASENAMEERRORFILE}" >> ${PROJECTDIR}/${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.wrap.cleaned.readme
				cat ${PROJECTDIR}/${BASECLEANEDFILE}.cdat | tail -n +2  | awk -F '\t' '{ print $0 }' >> ${PROJECTDIR}/${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.cdat
				echo "- removing files [ ${PROJECTDIR}/${BASECLEANEDFILE}[.cdat/.errors/.log] ]..."
				rm -v ${PROJECTDIR}/${BASECLEANEDFILE}.cdat
				rm -v ${PROJECTDIR}/${prefix_cleaned}${BASECLEANEDFILE}.errors
				rm -v ${PROJECTDIR}/${prefix_cleaned}${BASECLEANEDFILE}.log
				rm -v ${PROJECTDIR}/${prefix_cleaned}${BASECLEANEDFILE}.sh
	# 			rm -v ${PROJECTDIR}/*${BASEPARSEDFILE}_DEBUG_GWAS_CLEANER.RData
			else
				echoerrorflash "*** Error *** The pattern \"${CLEANEDPATTERN}\" was NOT found in [ ${BASENAMEERRORFILE} ]..."
				echoerror "Reported in the [ ${BASENAMEERRORFILE} ]:      "
				echoerror "####################################################################################"
				cat ${ERRORFILE}
				echoerror "####################################################################################"
				CLEANEDMESSAGE=$(echosucces "cleaning failure")
				CLEANEDMESSAGEREADME=$(echo "failure")
				echo "Cleaning report......................: ${CLEANEDMESSAGE}"
				echo "${COHORTNAME} ${BASEFILENAME}.txt.gz ${CLEANEDMESSAGEREADME} ${BASENAMEERRORFILE}" >> ${PROJECTDIR}/${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.wrap.cleaned.readme
			fi
		
			echo ""
		done
		
	fi
			
	echo ""
	echo "Gzipping da [ ${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.pdat ] shizzle..."
	gzip -v ${PROJECTDIR}/${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.pdat
	cp -fv ${PROJECTDIR}/${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.pdat.gz ${PROJECTDIR}/${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.FINAL.txt.gz

	if [[ ${GWASQC} = "YES" ]]; then	
		echo ""
		echo "Gzipping da [ ${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.cdat ] shizzle..."
		gzip -v ${PROJECTDIR}/${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.cdat
		cp -fv ${PROJECTDIR}/${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.cdat.gz ${PROJECTDIR}/${COHORTNAME}.${PROJECTNAME}.${REFERENCE}.${POPULATION}.FINAL.txt.gz
	fi
	
### END of if-else statement for the number of command-line arguments passed ###
fi 

script_copyright_message