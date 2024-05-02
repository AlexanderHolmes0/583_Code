#!/bin/bash
#SBATCH --job-name alex_automl_job
#SBATCH --account=bckj-delta-cpu
#SBATCH --partition=cpu
#SBATCH --mem=192g
#SBATCH --nodes=1
#SBATCH --cpus-per-task=128
#SBATCH --time 02:00:00
#SBATCH --error=./automl_job.err
#SBATCH --output=./automl_job.out

# load the R module
module load r

# run the R script
time Rscript h2o_preproc.R
