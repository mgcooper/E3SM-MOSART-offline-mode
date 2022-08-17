#!/bin/sh

# set parameters
RES=MOS_USRDAT
COMPSET=RMOSGPCC
MACH=compy
COMPILER=intel
PROJECT=esmd
SRC_DIR=/qfs/people/coop558/source/unstructured/E3SM
CASE_DIR=/qfs/people/coop558/projects/e3sm/unstructured/sag/sag_basin/cases

# set case name
CASE_NAME=sag.1982.2008.run.`date "+%Y-%m-%d"`
# GIT_HASH=`git log -n 1 --format=%h`
	
# create a new case using ./create_newcase script
cd ${SRC_DIR}/cime/scripts
	./create_newcase -case ${CASE_DIR}/${CASE_NAME} \
		-res ${RES} -mach ${MACH} -compiler ${COMPILER} -compset ${COMPSET} --project ${PROJECT}	

# go into the case folder
cd ${CASE_DIR}/${CASE_NAME}

# make changes before setting up the case
# ./xmlchange ELM_USRDAT_NAME=hcru_hcru
./xmlchange LND_DOMAIN_FILE=domain_sag_test.nc
./xmlchange ATM_DOMAIN_FILE=domain_sag_test.nc
./xmlchange LND_DOMAIN_PATH=/qfs/people/coop558/data/e3sm/unstructured/sag/sag_basin
./xmlchange ATM_DOMAIN_PATH=/qfs/people/coop558/data/e3sm/unstructured/sag/sag_basin

# modify env_run.xml
./xmlchange -file env_run.xml -id DOUT_S             	-val FALSE
./xmlchange -file env_run.xml -id INFO_DBUG          	-val 2
./xmlchange -file env_run.xml -id DLND_CPLHIST_YR_START -val 1979
./xmlchange -file env_run.xml -id DLND_CPLHIST_YR_END 	-val 2008

# modify env_build.xml
./xmlchange STOP_N=10
./xmlchange STOP_OPTION=nyears
./xmlchange RUN_STARTDATE=1982-01-01
./xmlchange CLM_USRDAT_NAME=test_r05_r05
./xmlchange JOB_QUEUE=short
# ./xmlchange DEBUG=true
# ./xmlchange CALENDAR=NO_LEAP

# modify env_case.xml
# ./xmlchange NAMELIST_DEFINITION_FILE=
# ./xmlchange CASEROOT=
# ./xmlchange CASE=

# modify env_workflow.xml
# ./xmlchange -file env_run.xml -id JOB_WALLCLOCK_TIME # format is DD:HH:MM
# ./xmlchange -file env_run.xml -id JOB_QUEUE # format is DD:HH:MM

# this puts the text between << EOF and EOF into user_nl_mosart file even if it doesn't exist
cat >> user_nl_mosart << EOF
frivinp_rtm = '/qfs/people/coop558/data/e3sm/unstructured/sag/sag_basin/MOSART_sag_test.nc'
!wrmflag = .true.
!inundflag = .true.
!opt_elevprof = 1
!rtmhist_fincl2="RIVER_DISCHARGE_OVER_LAND_LIQ"
!rtmhist_nhtfrq=0,-24
!rtmhist_mfilt=1,365
EOF

# note:
# rtmhist_nhtfrq=0,-24 	# 0=monthly average, -24=daily average
# rtmhist_mfilt=12,365 	# the number of time slices in these files


# copy the user_dlnd file into the case directory
cp /qfs/people/coop558/data/e3sm/usrdat/user_dlnd.streams.txt.lnd.gpcc.mingpan .
# cp /qfs/people/coop558/data/e3sm/usrdat/user_dlnd.streams.txt.lnd.gpcc.new .

# run it
./case.setup
./case.build
./case.submit --mail-user matt.cooper@pnnl.gov --mail-type all


################## NOTES and references
# use <squeue> to see the queue

# modify env_mach_pes.xml # shouldn't need to change anything here, below was to get mosart unstructured
# ./xmlchange NTASKS=15
# ./xmlchange -file env_mach_pes.xml -id NTASKS -val 3266
# modify env_mach_specific.xml # shouldn't ever have to change anything here
# modify env_archive.xml
# modify env_batch.xml (slurm stuff)
# modify env_run.xml
#./xmlchange -file env_run.xml -id PIO_REARR_COMM_MAX_PEND_REQ_COMP2IO       -val -1
#./xmlchange -file env_run.xml -id PIO_REARR_COMM_MAX_PEND_REQ_IO2COMP       -val -1
# modify env_build.xml
# ./xmlchange CIME_OUTPUT_ROOT=/path/to/output # default = /compyfs/coop558/e3sm_scratch (DON'T change, use archive)

# for setting up custom surf data
# cat >> user_nl_elm << EOF
# fsurdat = '<path-to-new-fsurdat-file>/<new-fsurdat-file>'
# EOF
