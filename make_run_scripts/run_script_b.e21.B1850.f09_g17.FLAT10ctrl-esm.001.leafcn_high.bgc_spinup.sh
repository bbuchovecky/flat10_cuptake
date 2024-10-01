#!/bin/bash

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Define simulation details
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
export FLAT10_EXP=ctrl-esm
export FLAT10_PARAM=leafcn_high

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Define directories and user settings
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Project number to charge for the simulation
export PROJECT_NUM=P93300070

# Case name and directory for the simulation
export CESM_CASE_NAME=b.e21.B1850.f09_g17.FLAT10${FLAT10_EXP}.001.${FLAT10_PARAM}.bgc_spinup
export CESM_CASE_DIR=/glade/u/home/bbuchovecky/cesm_runs/cases

# Model code
export CESM_SRC_DIR=/glade/u/home/bbuchovecky/cesm_source/cesm_FLAT10

# Resolution and compset
# Copied (verbose) from the FLAT10ctrl-esm timing file
export CESM_CASE_RES=f09_g17
export CESM_COMPSET=1850_CAM60_CLM50%BGC-CROP-CMIP6DECK_CICE%CMIP6_POP2%ECO%ABIO-DIC_MOSART_CISM2%NOEVOLVE_WW3_BGC%BPRP

# Output storage
export ARCHIVE_DIR=/glade/derecho/scratch/bbuchovecky/archive
export RUN_DIR=/glade/derecho/scratch/bbuchovecky

# Case name and directory associated with restart files (for branching)
export REFCASE_NAME=b.e21.B1850.f09_g17.FLAT10ctrl-esm.001.leafcn_high
export RESTART_DIR=/glade/derecho/scratch/bbuchovecky/archive/b.e21.B1850.f09_g17.FLAT10ctrl-esm.001.leafcn_high/rest/0043-01-01-00000

# This run script
export FILENAME=/glade/u/home/bbuchovecky/cesm_runs/make_run_scripts/run_script_b.e21.B1850.f09_g17.FLAT10${FLAT10_EXP}.001.${FLAT10_PARAM}.bgc_spinup.sh

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Clean up workspace (only if necessary)
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Delete old case
rm -rf "${CESM_CASE_DIR}/${CESM_CASE_NAME}"

# Delete old run directory
rm -rf "${RUN_DIR}/${CESM_CASE_NAME}"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Make case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Change to directory to make case
cd "${CESM_SRC_DIR}/cime/scripts"

# Create new case
./create_newcase --case "${CESM_CASE_DIR}/${CESM_CASE_NAME}" --res ${CESM_CASE_RES} --compset ${CESM_COMPSET} --project ${PROJECT_NUM} --machine derecho

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Configure case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Change to case directory
cd "${CESM_CASE_DIR}/${CESM_CASE_NAME}"

# +++ Modify xml files related to initial conditions
# Identify simulation to branch from
./xmlchange GET_REFCASE=FALSE
./xmlchange RUN_TYPE=hybrid
./xmlchange RUN_REFCASE=${REFCASE_NAME}
./xmlchange RUN_REFDATE=0043-01-01

# +++ Modify xml files related to run time
# Run for 6 years
./xmlchange STOP_OPTION="nyears"
./xmlchange STOP_N=2
./xmlchange RESUBMIT=2  
./xmlchange JOB_WALLCLOCK_TIME=12:00:00 --subgroup case.run

# +++ Modify xml files related to spinup
./xmlchange CLM_ACCELERATED_SPINUP="on"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Set up case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
./case.setup

# # If pointing to a model build directory (mainly for saving time when running same build many times)
# # could also use ./create_clone script
# ./xmlchange BUILD_COMPLETE=TRUE
# ./xmlchange EXEROOT=$RUN_DIR/$REFCASE_NAME"/bld"

# # Turn off short term archiving
# ./xmlchange DOUT_S=FALSE

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
cd ${RUN_DIR}/${CESM_CASE_NAME}/run
cp ${RESTART_DIR}/* .

# Build the case
cd "${CESM_CASE_DIR}/${CESM_CASE_NAME}"
qcmd -A "${PROJECT_NUM}" -- ./case.build

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Submit case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
cd "${CESM_CASE_DIR}/${CESM_CASE_NAME}"
./case.submit
