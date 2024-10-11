#!/bin/bash

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Define simulation details
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
export FLAT10_EXP=ctrl-esm
export FLAT10_PARAM=leafcn_high

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Define directories and user settings
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
export CESM_CASE_NAME=b.e21.B1850.f09_g17.FLAT10${FLAT10_EXP}.001.${FLAT10_PARAM}
export PROJECT_NUM=P93300070

# Resolution and compset copied (verbose) from the FLAT10ctrl-esm timing file
export CESM_CASE_RES=f09_g17
export CESM_COMPSET=1850_CAM60_CLM50%BGC-CROP-CMIP6DECK_CICE%CMIP6_POP2%ECO%ABIO-DIC_MOSART_CISM2%NOEVOLVE_WW3_BGC%BPRP

export BASECASE_NAME=b.e21.B1850.f09_g17.CMIP6-esm-piControl.001

export CESM_SRC_DIR=/glade/u/home/bbuchovecky/cesm_source/cesm_FLAT10
export CESM_CASE_DIR=/glade/u/home/bbuchovecky/cesm_runs/cases
export ARCHIVE_DIR=/glade/derecho/scratch/bbuchovecky/archive
export RUN_DIR=/glade/derecho/scratch/bbuchovecky
# export FILENAME=/glade/u/home/bbuchovecky/cesm_runs/make_run_scripts/run_script_b.e21.B1850.f09_g17.FLAT10${FLAT10_EXP}.001.${FLAT10_PARAM}.continue.sh
export FILENAME="${PWD}/${0}"
echo "${FILENAME}"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Configure case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Change to case directory
cd ${CESM_CASE_DIR}/${CESM_CASE_NAME}

# Adjust simulation length
./xmlchange STOP_OPTION="nyears"
./xmlchange STOP_N=3
./xmlchange RESUBMIT=7  # changed from 16 to 7 after stopping at 0027-12 -> run until 0051-12
./xmlchange JOB_WALLCLOCK_TIME=12:00:00 --subgroup case.run

# Continue run
./xmlchange CONTINUE_RUN=TRUE

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Build case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Copy this run script into the run directory
cp "${FILENAME}" .

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Submit case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
cd ${CESM_CASE_DIR}/${CESM_CASE_NAME}
./case.submit
