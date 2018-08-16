#!/bin/bash
#
#$ -S /bin/bash 																							# the type of BASH you'd like to use
#$ -N gbastoolkit 																							# the name of this script
# -hold_jid some_other_basic_bash_script 																	# the current script (basic_bash_script) will hold until some_other_basic_bash_script has finished
#$ -o /hpc/dhl_ec/svanderlaan/projects/consortia/GWAS_PotassiumSodium/POTSOD_POSTGWAS/gbastoolkit.qsub.v3.log 		# the log file of this job
#$ -e /hpc/dhl_ec/svanderlaan/projects/consortia/GWAS_PotassiumSodium/POTSOD_POSTGWAS/gbastoolkit.qsub.v3.errors 	# the error file of this job
#$ -l h_rt=00:30:00 																						# h_rt=[max time, e.g. 02:02:01] - this is the time you think the script will take
#$ -l h_vmem=4G 																							# h_vmem=[max. mem, e.g. 45G] - this is the amount of memory you think your script will use
# -l tmpspace=64G 																							# this is the amount of temporary space you think your script will use
#$ -M s.w.vanderlaan-2@umcutrecht.nl 																		# you can send yourself emails when the job is done; "-M" and "-m" go hand in hand
#$ -m beas 																									# you can choose: b=begin of job; e=end of job; a=abort of job; s=suspended job; n=no mail is send
#$ -cwd 																									# set the job start to the current directory - so all the things in this script are relative to the current directory!!!
#
# You can use the variables below (indicated by "#$") to set some things for the submission system.
# Another useful tip: you can set a job to run after another has finished. Name the job 
# with "-N SOMENAME" and hold the other job with -hold_jid SOMENAME". 
# Further instructions: https://wiki.bioinformatics.umcutrecht.nl/bin/view/HPC/HowToS#Run_a_job_after_your_other_jobs
#
# It is good practice to properly name and annotate your script for future reference for
# yourself and others. Trust me, you'll forget why and how you made this!!!

GBASTOOLKIT="/hpc/local/CentOS7/dhl_ec/software/GBASToolKit"
SCRIPTS="${GBASTOOLKIT}/SCRIPTS"
PROJECTDIR="/hpc/dhl_ec/svanderlaan/projects/consortia/GWAS_PotassiumSodium/POTSOD_POSTGWAS"
ORIGINALDATA="${PROJECTDIR}/DATA_UPLOAD_FREEZE"

echo ""
echo " PERFORM GENE-BASED ASSOCIATION STUDIES USING VEGAS2 AND MAGMA "
echo ""

# Note: in this case we filtered differently, we did it manually. In the `gbastoolkit.config`
# we indicated `GWASQC="NO"` meaning GBASToolKit will not apply GWAS QC on the datasets.
echo ""
echo "OPTIONAL: manually prepare GWAS files."

zcat ${ORIGINALDATA}/K_GWAMA_combined_01Mar2018.qced.txt.gz | awk ' $1 == "rsid" || $23 == "pass" ' | ${SCRIPTS}/parseTable.pl --col rsid,chr,pos,reference_allele,other_allele,eaf,beta,se,p.value,n_samples > ${ORIGINALDATA}/K_GWAMA_combined_01Mar2018.qced.PREPPED.txt
zcat ${ORIGINALDATA}/Na_GWAMA_combined_01Mar2018.qced.txt.gz | awk ' $1 == "rsid" || $23 == "pass" ' | ${SCRIPTS}/parseTable.pl --col rsid,chr,pos,reference_allele,other_allele,eaf,beta,se,p.value,n_samples > ${ORIGINALDATA}/Na_GWAMA_combined_01Mar2018.qced.PREPPED.txt

gzip -fv ${ORIGINALDATA}/K_GWAMA_combined_01Mar2018.qced.PREPPED.txt
gzip -fv ${ORIGINALDATA}/Na_GWAMA_combined_01Mar2018.qced.PREPPED.txt

echo ""
echo "Perform Gene-Based Association Studies (GBAS)."

${GBASTOOLKIT}/gbastoolkit.sh $(pwd)/gbastoolkit.config $(pwd)/gbastoolkit.files.list



