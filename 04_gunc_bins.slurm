#!/bin/bash
#SBATCH -c 8
#SBATCH --mem=80gb
#SBATCH --time=1-00:00
#SBATCH --output=/work_beegfs/sukmb276/Metagenomes/projects/230505_Madagascar_MGX/log/%A_%a.out
#SBATCH --job-name="04_gunc"

###########################
####    SETUP     #######
###########################
echo $SLURMD_NODENAME

source /work_beegfs/sukmb276/Metagenomes/projects/230505_Madagascar_MGX/madagascar_mgx_scripts/00_sources.txt

cd $WORKFOLDER

####################################
####    GROUP SELECTION     ########
####################################

mgx_new=${ALL_SAMPLES[$SLURM_ARRAY_TASK_ID]}

###########################
####    REFINE        #######
###########################

if [ -e "$WORKFOLDER/${PROJECTID}_results/samples/${mgx_new}/binning/${mgx_new}.gunc.out" ]; then exit; fi

module load miniconda3

cd $WORKFOLDER/${PROJECTID}_results/samples/${mgx_new}/binning

conda activate mgx_tools_env
mkdir prodigal
parallel -j $SLURM_CPUS_PER_TASK prodigal -a prodigal/{}.faa -d prodigal/{}.ffn -i cleanbins/{}.fna -o prodigal/{}.out ::: $(ls cleanbins/ | sed 's/[.]fna//')

gunc run -d $WORKFOLDER/${PROJECTID}_results/samples/${mgx_new}/binning/prodigal -g -e .faa -o $TMPDIR -t $SLURM_CPUS_PER_TASK --db /work_beegfs/ikmb_repository/databases/GUNC/gunc_db_progenomes2.1.dmnd

mv $TMPDIR/GUNC.progenomes_2.1.maxCSS_level.tsv $WORKFOLDER/${PROJECTID}_results/samples/${mgx_new}/binning/${mgx_new}.gunc.out