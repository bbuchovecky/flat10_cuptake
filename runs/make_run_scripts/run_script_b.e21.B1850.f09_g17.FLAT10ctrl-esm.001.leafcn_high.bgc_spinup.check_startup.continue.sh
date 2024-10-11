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
export CESM_CASE_NAME=b.e21.B1850.f09_g17.FLAT10${FLAT10_EXP}.001.${FLAT10_PARAM}.bgc_spinup.check_startup
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
export REFCASE_NAME=b.e21.B1850.f09_g17.FLAT10ctrl-esm.001.leafcn_high.bgc_spinup
export RESTART_DIR=/glade/derecho/scratch/bbuchovecky/archive/b.e21.B1850.f09_g17.FLAT10ctrl-esm.001.leafcn_high.bgc_spinup/rest/0007-01-01-00000

# This run script
export FILENAME=/glade/u/home/bbuchovecky/cesm_runs/make_run_scripts/run_script_b.e21.B1850.f09_g17.FLAT10${FLAT10_EXP}.001.${FLAT10_PARAM}.bgc_spinup.check_startup.continue.sh

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Configure case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Change to case directory
cd "${CESM_CASE_DIR}/${CESM_CASE_NAME}" || exit

# +++ Modify xml files related to initial conditions
# Run startup mode
# ./xmlchange RUN_TYPE="startup"
# ./xmlchange RUN_REFCASE="${REFCASE_NAME}"

# Identify simulation to branch from
# ./xmlchange GET_REFCASE=FALSE
# ./xmlchange RUN_TYPE=hybrid
# ./xmlchange RUN_REFCASE="${REFCASE_NAME}"
# ./xmlchange RUN_REFDATE=0043-01-01

# +++ Modify xml files related to run time
./xmlchange STOP_OPTION="nyears"
./xmlchange STOP_N=2
./xmlchange RESUBMIT=2  
./xmlchange JOB_WALLCLOCK_TIME=12:00:00 --subgroup case.run

# +++ Continue run
./xmlchange CONTINUE_RUN=TRUE

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Build case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Copy this run script into the run directory
cp "${FILENAME}" .

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Submit case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
cd "${CESM_CASE_DIR}/${CESM_CASE_NAME}" || exit
./case.submit
