#!/bin/bash

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Define simulation details
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
export FLAT10_SIM_TYPE=ctrl-esm
export FLAT10_PARAM=leafcn_high

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Define directories and user settings
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Project number to charge for the simulation
export PROJECT_NUM=P93300070

# Case name and directory for the simulation
export CESM_CASE_NAME=i.e21.I1850.f09_g17.FLAT10${FLAT10_SIM_TYPE}.${FLAT10_PARAM}.ADspin.002
export CESM_CASE_DIR=/glade/u/home/bbuchovecky/cesm_runs/cases

# Model code
export CESM_SRC_DIR=/glade/u/home/bbuchovecky/cesm_source/cesm_FLAT10

# Resolution and compset
# Copied (verbose) from the FLAT10ctrl-esm timing file
export CESM_CASE_RES=f09_g17
export CESM_COMPSET=1850_DATM%CPLHIST_CLM50%BGC_SICE_SOCN_MOSART_CISM2%NOEVOLVE_SWAV

# Output storage
export ARCHIVE_DIR=/glade/derecho/scratch/bbuchovecky/archive
export RUN_DIR=/glade/derecho/scratch/bbuchovecky

# This run script
export FILENAME=/glade/u/home/bbuchovecky/projects/flat10_leafcn/runs/make_run_scripts/run_script_i.e21.I1850.f09_g17.FLAT10ctrl-esm.leafcn_high.ADspin.002.sh
echo "{$0}"
echo "${FILENAME}"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Clean up workspace (only if necessary)
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Delete old case
rm -rf "${CESM_CASE_DIR}/${CESM_CASE_NAME:?}"

# Delete old run directory
rm -rf "${RUN_DIR}/${CESM_CASE_NAME:?}"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Make case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Change to directory to make case
cd "${CESM_SRC_DIR}/cime/scripts" || exit

# Create new case
./create_newcase --case "${CESM_CASE_DIR}/${CESM_CASE_NAME}" --res ${CESM_CASE_RES} --compset ${CESM_COMPSET} --project ${PROJECT_NUM} --machine derecho --run-unsupported

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Configure case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Change to case directory
cd "${CESM_CASE_DIR}/${CESM_CASE_NAME}" || exit

# +++ Modify xml files related to initial conditions
# Run startup mode
./xmlchange RUN_TYPE="startup"

# +++ Modify xml files related to run time
./xmlchange STOP_OPTION="nyears"
./xmlchange STOP_N=100
./xmlchange RESUBMIT=1
./xmlchange JOB_WALLCLOCK_TIME="12:00:00" --subgroup case.run

# +++ Modify xml files related to data model components
# Set DATM forcing to be from CESM output
# Use the coupler history from Claires's COUP0000_PI_SOM run
./xmlchange DATM_MODE="CPLHIST"
./xmlchange DATM_PRESAERO="cplhist"
./xmlchange DATM_TOPO="cplhist"
./xmlchange DATM_CPLHIST_DIR="/glade/campaign/cgd/tss/czarakas/CoupledPPE/coupled_simulations/COUP0000_PI_SOM/cpl/proc"
# (Note from Marysa: this is the path to the CPL output you're going to
# use to force your offline run)

./xmlchange DATM_CPLHIST_CASE="COUP0000_PI_SOM"
# CESM casename of the run you're using to force your offline run,
# i.e. the runname that is in all the files of CPL history output

./xmlchange DATM_CPLHIST_YR_ALIGN="49"
# (Note from Marysa: this doesn't have to be "1" - basically, if you have
# CPL hist output from year 0001-0050 and you actually want the years to
# line up properly, use "1". If you want there to be some offset (or if your
# CPL hist run started, say, in year 1850 instead of 0001, you might want to
# change this)

# Loop over the first 100 years of the forcing twice (200 years total)

./xmlchange DATM_CPLHIST_YR_START="49"
# (Note from Marysa: The first year of coupler history output you want to use.
# E.g. if you were spinning up your coupled model for 20 years, you don't want
# to use those spinup years to force your offline model. Or maybe you do. But
# if you want to skip some years, this is where you tell it where to start)

./xmlchange DATM_CPLHIST_YR_END="148"
# (Note from Marysa: The last year of the coupler output you want to use.
# E.g. lets say you just want to loop years 21-24 over and over and over
# again, you'd set this to 24. It will loop from YR_START to YR_END repeatedly
# for the whole length of the run you tell it to go for, ie a 10 year run
# that you only hand 5 years of coupler output will loop over the coupler
# forcing files twice).

# Set the start date of the run
./xmlchange RUN_STARTDATE="0001-01-01"

# Turn on AD mode for accelerated spinup
./xmlchange CLM_ACCELERATED_SPINUP="on"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Set up case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
./case.setup

# +++ Turn on/off short term archiving
#./xmlchange DOUT_S=FALSE

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Modify namelists
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Copy user modified namelists from the original FLAT10ctrl-esm configuration
cp "/glade/u/home/bbuchovecky/projects/flat10_leafcn/runs/user_nml/icompset_mod/icomp_nl_cam" user_nl_cam
cp "/glade/u/home/bbuchovecky/projects/flat10_leafcn/runs/user_nml/icompset_mod/icomp_nl_cice" user_nl_cice
cp "/glade/u/home/bbuchovecky/projects/flat10_leafcn/runs/user_nml/icompset_mod/icomp_nl_clm" user_nl_clm
cp "/glade/u/home/bbuchovecky/projects/flat10_leafcn/runs/user_nml/icompset_mod/icomp_nl_cpl" user_nl_cpl

# Add new CLM parameter file and initial conditions
cat >> user_nl_clm << EOF
! ---------------------------------PARAMETER FILE----------------------------------
paramfile = "/glade/u/home/djk2120/for/abby/${FLAT10_PARAM}.nc"

! ---------------------------------INITIAL CONDITIONS------------------------------
finidat = "/glade/derecho/scratch/bbuchovecky/archive/b.e21.B1850.f09_g17.FLAT10ctrl-esm.001.leafcn_high.bgc_spinup/rest/0007-01-01-00000/b.e21.B1850.f09_g17.FLAT10ctrl-esm.001.leafcn_high.bgc_spinup.clm2.r.0007-01-01-00000.nc"

use_init_interp = .true.
! Setting use_init_interp = .true. is needed when doing a
! transient run using an initial conditions file from a non-transient run,
! or a -> non-transient run using an initial conditions file from a transient run <-,
! or when running a resolution or configuration that differs from the initial conditions.

EOF

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Build case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Copy this run script into the run directory
cp "${FILENAME}" .

# Build the case
cd "${CESM_CASE_DIR}/${CESM_CASE_NAME}" || exit
qcmd -A "${PROJECT_NUM}" -- ./case.build

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Submit case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
cd "${CESM_CASE_DIR}/${CESM_CASE_NAME}" || exit
./case.submit
