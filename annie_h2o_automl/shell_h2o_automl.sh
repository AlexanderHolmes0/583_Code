#!/bin/bash
#SBATCH --job-name annie_automl_job
#SBATCH --account=bckj-delta-cpu
#SBATCH --partition=cpu
#SBATCH --mem=192g
# the node count; there might be some speed up if we could
# distribute the load to multiple nodes
#SBATCH -N 1
# number of tasks to be launched
#SBATCH -n 1
#SBATCH --cpus-per-task=128
#SBATCH --time 02:00:00
#SBATCH --error=./automl_job.err
#SBATCH --output=./automl_job.out

# load the R module
module load r

# run the R script
srun time Rscript /projects/bckj/Team5/583_Code/annie_h2o_automl/h2o_automl.R
