#!/bin/bash

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Define simulation details
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
export FLAT10_SIM_TYPE=ctrl-esm
export FLAT10_PARAM=leafcn_high

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Define directories and user settings
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
export CESM_CASE_NAME=b.e21.B1850.f09_g17.FLAT10${FLAT10_SIM_TYPE-esm}.001.${FLAT10_PARAM}
export PROJECT_NUM=P93300070

# Resolution and compset copied (verbose) from the FLAT10ctrl-esm timing file
export CESM_CASE_RES=a%0.9x1.25_l%0.9x1.25_oi%gx1v7_r%r05_g%gland4_w%ww3a_m%gx1v7
export CESM_COMPSET=1850_CAM60_CLM50%BGC-CROP-CMIP6DECK_CICE%CMIP6_POP2%ECO%ABIO-DIC_MOSART_CISM2%NOEVOLVE_WW3_BGC%BPRP

export BASECASE_NAME=b.e21.B1850.f09_g17.CMIP6-esm-piControl.001

export CESM_SRC_DIR=/glade/u/home/bbuchovecky/cesm_source/cesm_FLAT10
export CESM_CASE_DIR=/glade/u/home/bbuchovecky/cesm_runs/cases
export ARCHIVE_DIR=/glade/derecho/scratch/bbuchovecky/archive
export RUN_DIR=/glade/derecho/scratch/bbuchovecky
export FILENAME=/glade/u/home/bbuchovecky/cesm_runs/make_run_scripts/run_script_b.e21.B1850.f09_g17.FLAT10${FLAT10_SIM_TYPE-esm}.001.${FLAT10_PARAM}.sh

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Clean up workspace (only if necessary)
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Delete old case
# rm -rf "${CESM_CASE_DIR}/${CESM_CASE_NAME}"

# Delete old run directory
# rm -rf "${RUN_DIR}/${CESM_CASE_NAME}"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Make case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Change to directory to make case
cd "${CESM_SRC_DIR}/cime/scripts" || return

# Create new case
./create_newcase --case "${CESM_CASE_DIR}/${CESM_CASE_NAME}" --res ${CESM_CASE_RES} --compset ${CESM_COMPSET} --project ${PROJECT_NUM} --machine derecho

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Configure case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Change to case directory
cd "${CESM_CASE_DIR}/${CESM_CASE_NAME}" || return

# Identify simulation to branch from
./xmlchange RUN_TYPE=hybrid
./xmlchange GET_REFCASE=TRUE  # this will get the initial condition/restart files for you from the RUN_REFDIR=cesm2_init (default)
./xmlchange RUN_REFCASE=${BASECASE_NAME}
./xmlchange RUN_REFDATE=0151-01-01

# +++ Modify xml files related to run time
# For running a full simulation
# ./xmlchange STOP_OPTION="nyears"
# ./xmlchange STOP_N=5
# ./xmlchange RESUBMIT=16
# ./xmlchange JOB_WALLCLOCK_TIME=12:00:00 --subgroup case.run

# For running a test simulation
./xmlchange STOP_OPTION="nmonths"
./xmlchange STOP_N=1
./xmlchange JOB_WALLCLOCK_TIME=12:00:00 --subgroup case.run

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Set up case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
./case.setup

#./xmlchange BUILD_COMPLETE=TRUE

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Add modified source files
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# cp "modified_file.F90" SourceMods/src.general_component/corresponding_mod.F90

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Modify namelists
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Copy user modified namelists from the original FLAT10ctrl-esm configuration
cp "/glade/work/lawrence/cesmflat10cases/b.e21.B1850.f09_g17.FLAT10ctrl-esm.001/user_nl_cam" user_nl_cam
cp "/glade/work/lawrence/cesmflat10cases/b.e21.B1850.f09_g17.FLAT10ctrl-esm.001/user_nl_cice" user_nl_cice
cp "/glade/work/lawrence/cesmflat10cases/b.e21.B1850.f09_g17.FLAT10ctrl-esm.001/user_nl_clm" user_nl_clm
cp "/glade/work/lawrence/cesmflat10cases/b.e21.B1850.f09_g17.FLAT10ctrl-esm.001/user_nl_cpl" user_nl_cpl

# Add new parameter file
cat >> user_nl_clm << EOF
! ---------------------------------PARAMETER FILE----------------------------------
paramfile = "/glade/u/home/djk2120/for/abby/${FLAT10_PARAM}.nc"
EOF

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Build case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Copy this run script into the run directory
cp "${FILENAME}" .

# Copy resubmit files (from the case we're branching from) into this case's run folder
# cd ${RUN_DIR}/${CESM_CASE_NAME}/run
# cp ${RESTART_DIR}/* .

# Build the case
cd "${CESM_CASE_DIR}/${CESM_CASE_NAME}" || return
qcmd -A "${PROJECT_NUM}" -- ./case.build

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Submit case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
cd "${CESM_CASE_DIR}/${CESM_CASE_NAME}" || return
./case.submit
