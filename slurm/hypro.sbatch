#!/bin/sh
#SBATCH --job-name="HyPro"
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=35G
#SBATCH --partition=aerosol
#SBATCH --time=20:00:00
#SBATCH --output=logs/%x_%A_%a_%j.out
#SBATCH --error=logs/%x_%A_%a_%j.err

PARAMETERS_FILE=${session}_SlurmJobList.txt

ENVDIR=htconda

# Activate Python environment
export PATH=$(pwd)/$ENVDIR:$(pwd)/$ENVDIR/lib:$(pwd)/$ENVDIR/share:$PATH
. $ENVDIR/bin/activate

# Get Python major & minor version number
PYTHON_VERSION=$(python -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
# Until HyPro is properly installed in the Conda environment, we need to add it to `conda.pth`
echo $(pwd)/hypro/src > $ENVDIR/lib/python${PYTHON_VERSION}/site-packages/conda.pth

# Determine grid rotation
ORIENTATION=$(awk -v ArrayTaskID=1 '$1==ArrayTaskID {print $3}' $PARAMETERS_FILE)

# Run processing
python hypro/src/hypro/workflow/main.py LAKE_Config.json --lines $SLURM_ARRAY_TASK_ID --rotation $ORIENTATION

exit