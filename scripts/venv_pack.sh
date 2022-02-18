#!/usr/bin/env bash
set -e

ENV_NAME="psparkvenv"
PYTHON_VERSION="3.9"

# Add PDM plugin for venv
pdm plugin add pdm-venv

# Fix error "Your shell has not been properly configured to use 'conda activate'"
eval "$($CONDA_EXE shell.bash hook)"
eval "$($CONDA_EXE shell.bash activate)"

# Config conda for conflict resolution, latest conda and conda-pack are needed
conda config --set channel_priority strict
conda config --add channels conda-forge
conda install conda-pack -y

# Create venv from requirements.txt and pack it
pdm venv create --name ${ENV_NAME} --with conda ${PYTHON_VERSION}
eval $(pdm venv activate ${ENV_NAME})
pdm export -f requirements --without-hashes --prod -o requirements.txt

pip install --upgrade-strategy only-if-needed -r requirements.txt # to not mess with conda
VENV_PATH=$(pdm venv activate ${ENV_NAME} | cut -d ' ' -f3)
rm -f ${ENV_NAME}.tar.gz && conda pack -p $VENV_PATH -o ${ENV_NAME}.tar.gz
