#!/bin/bash

### Creating display functions
### Setting colouring
NONE='\033[00m'
OPAQUE='\033[2m'
FLASHING='\033[5m'
BOLD='\033[1m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
STRIKETHROUGH='\033[9m'

RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'

function echobold { #'echobold' is the function name
    echo -e "${BOLD}${1}${NONE}" # this is whatever the function needs to execute, note ${1} is the text for echo
}
function echoitalic { 
    echo -e "${ITALIC}${1}${NONE}" 
}
function echonooption { 
    echo -e "${OPAQUE}${RED}${1}${NONE}"
}
function echoerrorflash { 
    echo -e "${RED}${BOLD}${FLASHING}${1}${NONE}" 
}
function echoerror { 
    echo -e "${RED}${1}${NONE}"
}
# errors no option
function echoerrornooption { 
    echo -e "${YELLOW}${1}${NONE}"
}
function echoerrorflashnooption { 
    echo -e "${YELLOW}${BOLD}${FLASHING}${1}${NONE}"
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
	echoerror "- Argument #1 is path_to/filename of the configuration file."
	echoerror "- Argument #2 is path_to/filename of the list of GWAS files with names."
	echoerror ""
	echoerror "An example command would be: gbastoolkit.sh [arg1] [arg2]"
	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
 	echo ""
	script_copyright_message
	exit 1
}

echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echobold "                          GASToolKit: A TOOLKIT FOR GENE-BASED ASSOCIATION STUDIES"
echoitalic "                    --- prepare and perform gene-based studies using VEGAS2 or MAGMA---"
echobold ""
echobold "* Version:      v1.0.0"
echobold ""
echobold "* Last update:  2018-03-21"
echobold "* Written by:   Sander W. van der Laan | s.w.vanderlaan@gmail.com."
echobold "* Description:  Prepare and perform gene-based association studies. It will do the following:"
echobold "                - Automatically parse the summary statistics of some (meta-analysis of) GWAS."
echobold "                - Perform VEGAS2 based analyses."
echobold "                - Perform MAGMA based analyses."
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
if [[ $# -lt 2 ]]; then 
	echo ""
	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echoerrorflash "               *** Oh, oh, computer says no! Number of arguments found "$#". ***"
	echoerror "You must supply [2] arguments when running *** GBASToolKit ***!"
	script_arguments_error
else
	echo "These are the "$#" arguments that passed:"
	echo "The configuration file.................: "$(basename ${1}) # argument 1
	echo "The list of GWAS files.................: "$(basename ${2}) # argument 2
	
	### SETTING DIRECTORIES (from configuration file).
	# Loading the configuration file (please refer to the GBASToolKit-Manual for specifications of this file). 
	source "$1" # Depends on arg1.
	
	CONFIGURATIONFILE="$1" # Depends on arg1 -- but also on where it resides!!!
	GWASFILES="$2" # Depends on arg2 -- all the GWAS dataset information
	
	# Where GBASToolKit resides
	GBASTOOLKIT=${GBASTOOLKITDIR} # from configuration file
	SCRIPTS=${GBASTOOLKIT}/SCRIPTS
	
	# Project information
	ORIGINALS=${DATA_UPLOAD_FREEZE} # from configuration file

	##########################################################################################
	### CREATE THE OUTPUT DIRECTORIES
	echo ""
	echo "Checking for the existence of the output directory [ ${OUTPUTDIRNAME} ]."
	if [ ! -d ${PROJECTDIR}/${OUTPUTDIRNAME} ]; then
		echo "> Output directory doesn't exist - Mr. Bourne will create it for you."
		mkdir -v ${PROJECTDIR}/${OUTPUTDIRNAME}
	else
		echo "> Output directory already exists."
	fi
	OUTPUTDIR=${OUTPUTDIRNAME}
	
	echo ""
	echo "Checking for the existence of the subproject directory [ ${OUTPUTDIR}/${SUBPROJECTDIRNAME} ]."
	if [ ! -d ${PROJECTDIR}/${OUTPUTDIR}/${SUBPROJECTDIRNAME} ]; then
		echo "> Subproject directory doesn't exist - Mr. Bourne will create it for you."
		mkdir -v ${PROJECTDIR}/${OUTPUTDIR}/${SUBPROJECTDIRNAME}
	else
		echo "> Subproject directory already exists."
	fi
	SUBPROJECTDIR=${PROJECTDIR}/${OUTPUTDIR}/${SUBPROJECTDIRNAME}
	
	echo ""
	echo "Checking for the existence of the parsed data directory [ ${OUTPUTDIR}/${SUBPROJECTDIRNAME}/PARSED ]."
	if [ ! -d ${PROJECTDIR}/${OUTPUTDIR}/${SUBPROJECTDIRNAME}/PARSED ]; then
		echo "> Parsed data directory doesn't exist - Mr. Bourne will create it for you."
		mkdir -v ${PROJECTDIR}/${OUTPUTDIR}/${SUBPROJECTDIRNAME}/PARSED
	else
		echo "> Parsed data directory already exists."
	fi
	PARSEDDIR=${PROJECTDIR}/${OUTPUTDIR}/${SUBPROJECTDIRNAME}/PARSED

	##########################################################################################
	### SETTING UP THE OUTPUT AND PARSEDDATA DIRECTORIES
	echo ""
	### Making raw data directories, unless they already exist. Depends on arg2.
	if [[ ${REFERENCE} = "1Gp1" ]]; then

	  	echo ""
	  	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	  	echo ""
	  	echo "The scene is properly set, and directories are created! 🖖"
	  	echo "GBASToolKit program............................: "${GBASTOOLKIT}
	  	echo "GBASToolKit scripts............................: "${SCRIPTS}
	  	echo "Reference and population used..................: ${REFERENCE} - ${POPULATION}"
	  	echo "Main directory.................................: "${PROJECTDIR}
	  	echo "Main analysis output directory.................: "${OUTPUTDIR}
	  	echo "Original data directory........................: "${ORIGINALS}
	  	echo "Subproject's analysis output directory.........: "${SUBPROJECTDIR}
	  	echo "Parsed data is stored in.......................: "${PARSEDDIR}
	  	echo "We are processing these cohort(s)..............:"
		while IFS='' read -r GWASCOHORT || [[ -n "$GWASCOHORT" ]]; do
			LINE=${GWASCOHORT}
			COHORT=$(echo "${LINE}" | awk '{ print $1 }')
			echo " * ${COHORT}"
		done < ${GWASFILES}
	  	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	  	echo ""
	
	elif [[ ${REFERENCE} = "HM2" || ${REFERENCE} = "GONL4" || ${REFERENCE} = "GONL5" || ${REFERENCE} = "1Gp3" || ${REFERENCE} = "1Gp3GONL5" ]]; then
		echoerrornooption "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	  	echoerrornooption ""
	  	echoerrorflashnooption "               *** Oh, computer says no! This option is not available yet. ***"
	  	echoerrornooption "Unfortunately using ${REFERENCE} as a reference is not possible yet. Currently only 1Gp1 is available."
	  	echoerrornooption "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		### The wrong arguments are passed, so we'll exit the script now!
		echo ""
		script_copyright_message
		exit 1
	
	else
	  	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	  	echoerror ""
	  	echoerrorflash "                  *** Oh, computer says no! Argument not recognised. ***"
	  	echoerror "You have the following options as reference for the quality control"
	  	echoerror "and meta-analysis:"
	  	echonooption " - [HM2]          HapMap2 (r27, b36, hg18)."
	  	echoerror " - [1Gp1]         1000G (phase 1, release 3, 20101123 version, updated on 20110521 "
	  	echoerror "                  and revised on Feb/Mar 2012, b37, hg19)."
	  	echonooption " - [1Gp3]         1000G (phase 3, release 5, 20130502 version, b37, hg19)."
	  	echonooption " - [GoNL4]        Genome of the Netherlands, version 4."
	  	echonooption " - [GONL5]        Genome of the Netherlands, version 5."
	  	echonooption " - [1Gp3GONL5]    integrated 1000G phase 3, version 5 and GoNL5."
	  	echonooption "(Opaque: not an option yet)"
	  	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		### The wrong arguments are passed, so we'll exit the script now!
		echo ""
		script_copyright_message
		exit 1
	fi

	
	echobold "#########################################################################################################"
	echobold "### REFORMAT AND PARSE ORIGINAL GWAS DATA"
	echobold "#########################################################################################################"
	echobold "#"
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Start the reformatting and parsing of each cohort and dataset. "
	echo ""
	
	while IFS='' read -r GWASCOHORT || [[ -n "$GWASCOHORT" ]]; do
			
		LINE=${GWASCOHORT}
		COHORT=$(echo "${LINE}" | awk '{ print $1 }')
		FILE=$(echo "${LINE}" | awk '{ print $2 }')
		
		BASEFILE=$(basename ${FILE} .txt.gz)
		
		if [ ! -d ${PARSEDDIR}/${COHORT} ]; then
	  		echo "Making subdirectory for ${COHORT}..."
	  		mkdir -v ${PARSEDDIR}/${COHORT}
		else
			echo "Directory for ${COHORT} already there."
		fi
		RAWDATACOHORT=${PARSEDDIR}/${COHORT}
		
		echobold "#========================================================================================================"
		echobold "#== REFORMAT AND PARSE ORIGINAL GWAS DATA"
		echobold "#========================================================================================================"
		echobold "#"
		echo ""
		echo "* Chopping up GWAS summary statistics into chunks of ${CHUNKSIZE} variants -- for parallelisation and speedgain..."
		
		### Split up the file in increments of 1000K -- note: the period at the end of '${BASEFILE}' is a separator character
		zcat ${ORIGINALS}/${FILE} | tail -n +2 | split -a 3 -l ${CHUNKSIZE} - ${RAWDATACOHORT}/${BASEFILE}.
		
		## Adding headers -- this is ABSOLUTELY required for the 'gwas.parser.R'.
		for SPLITFILE in ${RAWDATACOHORT}/${BASEFILE}.*; do
			### determine basename of the splitfile
			BASESPLITFILE=$(basename ${SPLITFILE} )
			echo ""
			echo "* Prepping split chunk: [ ${BASESPLITFILE} ]..."
			echo ""
			echo " - heading a temporary file." 
			zcat ${ORIGINALS}/${FILE} | head -1 > ${RAWDATACOHORT}/tmp_file
			echo " - adding the split data to the temporary file."
			cat ${SPLITFILE} >> ${RAWDATACOHORT}/tmp_file
			echo " - renaming the temporary file."
			mv -fv ${RAWDATACOHORT}/tmp_file ${SPLITFILE}
			
			echobold "#========================================================================================================"
			echobold "#== PARSING THE GWAS DATA"
			echobold "#========================================================================================================"
			echobold "#"
			echo ""
			echo "* Parsing data for cohort ${COHORT} [ file: ${BASESPLITFILE} ]."
			### FOR DEBUGGING LOCALLY -- Mac OS X
			### Rscript ${SCRIPTS}/gwas.parser.R -p ${PROJECTDIR} -d ${SPLITFILE} -o ${OUTPUTDIRNAME}/${SUBPROJECTDIRNAME}/PARSED/${COHORT} 
			echo "Rscript ${SCRIPTS}/gwas.parser.R -p ${PROJECTDIR} -d ${SPLITFILE} -o ${OUTPUTDIRNAME}/${SUBPROJECTDIRNAME}/PARSED/${COHORT} " > ${RAWDATACOHORT}/gwas.parser.${BASESPLITFILE}.sh
			qsub -S /bin/bash -N gwas.parser.${BASESPLITFILE} -hold_jid run_metagwastoolkit -o ${RAWDATACOHORT}/gwas.parser.${BASESPLITFILE}.log -e ${RAWDATACOHORT}/gwas.parser.${BASESPLITFILE}.errors -l h_rt=${QRUNTIMEPARSER} -l h_vmem=${QMEMPARSER} -M ${QMAIL} -m ${QMAILOPTIONS} -cwd ${RAWDATACOHORT}/gwas.parser.${BASESPLITFILE}.sh
			
			echobold "#========================================================================================================"
			echobold "#== CLEANING UP THE REFORMATTED GWAS DATA"
			echobold "#========================================================================================================"
			echobold "#"
			echo ""
			echo "* Cleaning harmonized data for [ ${BASESPLITFILE} ] file for cohort ${COHORT} with ${REFERENCE}"
			echo "  using the following pre-specified settings:"
			echo "  - MAF  = ${MAF}"
			echo "  - MAC  = ${MAC}"
			echo "  - HWE  = ${HWE}"
			echo "  - INFO = ${INFO}"
			echo "  - BETA = ${BETA}"
			echo "  - SE   = ${SE}"
			### FOR DEBUGGING LOCALLY -- Mac OS X
			### ${SCRIPTS}/gwas.cleaner.R -d ${SPLITFILE}.pdat -f ${BASESPLITFILE} -o ${RAWDATACOHORT} -e ${BETA} -s ${SE} -m ${MAF} -c ${MAC} -i ${INFO} -w ${HWE}
			echo "${SCRIPTS}/gwas.cleaner.R -d ${SPLITFILE}.pdat -f ${BASESPLITFILE} -o ${RAWDATACOHORT} -e ${BETA} -s ${SE} -m ${MAF} -c ${MAC} -i ${INFO} -w ${HWE}" >> ${RAWDATACOHORT}/gwas.cleaner.${BASESPLITFILE}.sh
# 			qsub -S /bin/bash -N gwas.cleaner.${BASEFILE} -hold_jid gwas2ref.harmonizer.${BASEFILE} -o ${RAWDATACOHORT}/gwas.cleaner.${BASESPLITFILE}.log -e ${RAWDATACOHORT}/gwas.cleaner.${BASESPLITFILE}.errors -l h_rt=${QRUNTIMECLEANER} -l h_vmem=${QMEMCLEANER} -M ${QMAIL} -m ${QMAILOPTIONS} -cwd ${RAWDATACOHORT}/gwas.cleaner.${BASESPLITFILE}.sh

		done

		echobold "#========================================================================================================"
		echobold "#== WRAPPING THE REFORMATTED GWAS DATA"
		echobold "#========================================================================================================"
		echobold "#"

		echo ""
		echo "* Wrapping up parsed and harmonized data for cohort ${COHORT}..."
		### FOR DEBUGGING LOCALLY -- Mac OS X
		### ${SCRIPTS}/gwas.wrapper.sh ${RAWDATACOHORT} ${COHORT} ${BASEFILE} ${VARIANTYPE}
		echo "${SCRIPTS}/gwas.wrapper.sh ${RAWDATACOHORT} ${COHORT} ${BASEFILE} ${VARIANTYPE}" >> ${RAWDATACOHORT}/gwas.wrapper.${BASEFILE}.sh
# 		qsub -S /bin/bash -N gwas.wrapper -hold_jid gwas.cleaner.${BASEFILE} -o ${RAWDATACOHORT}/gwas.wrapper.${BASEFILE}.log -e ${RAWDATACOHORT}/gwas.wrapper.${BASEFILE}.errors -l h_rt=${QRUNTIMEWRAPPER} -l h_vmem=${QMEMWRAPPER} -M ${QMAIL} -m ${QMAILOPTIONS} -cwd ${RAWDATACOHORT}/gwas.wrapper.${BASEFILE}.sh
		
	done < ${GWASFILES}

# 
# 	echobold "#========================================================================================================"
# 	echobold "#== GENE-BASED ANALYSIS OF META-ANALYSIS RESULTS USING VEGAS2"
# 	echobold "#========================================================================================================"
# 	echobold "#"
# 	# REQUIRED: VEGAS/VEGAS2 settings.
# 	# Note: we do `cd ${VEGASDIR}` because VEGAS is making temp-files in a special way, 
# 	#       adding a date-based number in front of the input/output files.
# 	echo "Creating VEGAS input files..." 
# 	mkdir -v ${SUBPROJECTDIR}/vegas
# 	VEGASDIR=${SUBPROJECTDIR}/vegas
# 	chmod -Rv a+rwx ${VEGASDIR}
# 	echo "...per chromosome."
# 	
# 	while IFS='' read -r GWASCOHORT || [[ -n "$GWASCOHORT" ]]; do
# 			LINE=${GWASCOHORT}
# 			COHORT=$(echo "${LINE}" | awk '{ print $1 }')
# 			echo "     * ${COHORT}"
# 		for CHR in $(seq 1 23); do
# 			if [[ $CHR -le 22 ]]; then 
# 				echo "Processing chromosome ${CHR}..."
# 				echo "zcat ${METARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.summary.txt.gz | ${SCRIPTS}/parseTable.pl --col VARIANTID,CHR,P_FIXED | awk ' \$2==${CHR} ' | awk '{ print \$1, \$3 }' | tail -n +2 > ${VEGASDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.chr${CHR}.forVEGAS.txt " > ${VEGASDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.chr${CHR}.runVEGAS.sh
# 				echo "cd ${VEGASDIR} " >> ${VEGASDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.chr${CHR}.runVEGAS.sh
# 				echo "$VEGAS2 -G -snpandp meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.chr${CHR}.forVEGAS.txt -custom ${VEGAS2POP}.chr${CHR} -glist ${VEGAS2GENELIST} -upper ${VEGAS2UPPER} -lower ${VEGAS2LOWER} -chr ${CHR} -out meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.chr${CHR}.fromVEGAS " >> ${VEGASDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.chr${CHR}.runVEGAS.sh
# 				qsub -S /bin/bash -N VEGAS2.${PROJECTNAME}.chr${CHR} -hold_jid METASUM -o ${VEGASDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.chr${CHR}.runVEGAS.log -e ${VEGASDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.chr${CHR}.runVEGAS.errors -l h_vmem=${QMEMVEGAS} -l h_rt=${QRUNTIMEVEGAS} -wd ${VEGASDIR} ${VEGASDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.chr${CHR}.runVEGAS.sh
# 		
# 			elif [[ $CHR -eq 23 ]]; then  
# 				echo "Processing chromosome X..."
# 				echo "zcat ${METARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.summary.txt.gz | ${SCRIPTS}/parseTable.pl --col VARIANTID,CHR,P_FIXED | awk ' \$2==\"X\" ' | awk '{ print \$1, \$3 }' | tail -n +2 > ${VEGASDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.chr${CHR}.forVEGAS.txt " > ${VEGASDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.chr${CHR}.runVEGAS.sh
# 				echo "cd ${VEGASDIR} " >> ${VEGASDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.chr${CHR}.runVEGAS.sh
# 				echo "$VEGAS2 -G -snpandp meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.chr${CHR}.forVEGAS.txt -custom ${VEGAS2POP}.chr${CHR} -glist ${VEGAS2GENELIST} -upper ${VEGAS2UPPER} -lower ${VEGAS2LOWER} -chr ${CHR} -out meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.chr${CHR}.fromVEGAS " >> ${VEGASDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.chr${CHR}.runVEGAS.sh
# 				qsub -S /bin/bash -N VEGAS2.${PROJECTNAME}.chr${CHR} -hold_jid METASUM -o ${VEGASDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.chr${CHR}.runVEGAS.log -e ${VEGASDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.chr${CHR}.runVEGAS.errors -l h_vmem=${QMEMVEGAS} -l h_rt=${QRUNTIMEVEGAS} -wd ${VEGASDIR} ${VEGASDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.chr${CHR}.runVEGAS.sh
# 		
# 			else
# 				echo "*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please."	
# 				exit 1
# 			fi
# 
# 		done
# 	done < ${GWASFILES}
# 
# 	echobold "#========================================================================================================"
# 	echobold "#== GENE-BASED ANALYSIS OF META-ANALYSIS RESULTS USING MAGMA"
# 	echobold "#========================================================================================================"
# 	echobold "#"
# 	### REQUIRED: MAGMA settings.
# 	### Head for MAGMA input
# 	### SNP CHR BP P NOBS 
# 	echo "Creating MAGMA input files..." 
# 	mkdir -v ${METARESULTDIR}/magma
# 	MAGMARESULTDIR=${METARESULTDIR}/magma
# 	chmod -Rv a+rwx ${MAGMARESULTDIR}
# 	echo " - whole-genome..."
#  	echo "echo \"SNP CHR BP P NOBS\" > ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.forMAGMA.txt " > ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.runMAGMA.sh
#  	echo "zcat ${METARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.summary.txt.gz | ${SCRIPTS}/parseTable.pl --col VARIANTID,CHR,POS,P_FIXED,N_EFF | tail -n +2 | awk '{ print \$1, \$2, \$3, \$4, int(\$5) }' >> ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.forMAGMA.txt " >> ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.runMAGMA.sh
# 	echo "${MAGMA} --annotate --snp-loc ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.forMAGMA.txt --gene-loc ${MAGMAGENES} --out ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.fromMAGMA.annotated " >> ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.runMAGMA.sh
# 	qsub -S /bin/bash -N MAGMA.ANALYSIS.${PROJECTNAME} -hold_jid METASUM -o ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.runMAGMA.log -e ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.runMAGMA.errors -l h_vmem=${QMEMMAGMA} -l h_rt=${QRUNTIMEMAGMA} -wd ${MAGMARESULTDIR} ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.runMAGMA.sh
# 
# 	echo "${MAGMA} --bfile ${MAGMAPOP} synonyms=${MAGMADBSNP} synonym-dup=drop-dup --pval ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.forMAGMA.txt ncol=NOBS --gene-annot ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.fromMAGMA.annotated.genes.annot --out ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.fromMAGMA.genesannotated " > ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.annotMAGMA.sh
#  	qsub -S /bin/bash -N MAGMA.ANNOTATION.${PROJECTNAME} -hold_jid MAGMA.ANALYSIS.${PROJECTNAME} -o ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.annotMAGMA.log -e ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.annotMAGMA.errors -l h_vmem=${QMEMMAGMA} -l h_rt=${QRUNTIMEMAGMA} -wd ${MAGMARESULTDIR} ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.annotMAGMA.sh
# 
#  	echo "${MAGMA} --gene-results ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.fromMAGMA.genesannotated.genes.raw --set-annot ${MAGMAGENESETS} --out ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.fromMAGMA.gsea " > ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.gseaMAGMA.sh
#  	qsub -S /bin/bash -N MAGMA.GSEA.${PROJECTNAME} -hold_jid MAGMA.ANNOTATION.${PROJECTNAME} -o ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.gseaMAGMA.log -e ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.gseaMAGMA.errors -l h_vmem=${QMEMMAGMA} -l h_rt=${QRUNTIMEMAGMA} -wd ${MAGMARESULTDIR} ${MAGMARESULTDIR}/meta.results.${PROJECTNAME}.${REFERENCE}.${POPULATION}.gseaMAGMA.sh
 
	### END of if-else statement for the number of command-line arguments passed ###
fi 

script_copyright_message