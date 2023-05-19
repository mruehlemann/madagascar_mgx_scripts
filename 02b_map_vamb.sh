#!/bin/bash
#SBATCH -c 10
#SBATCH --mem=100gb
#SBATCH --time=1-00:00
#SBATCH --output=/work_beegfs/sukmb276/Metagenomes/projects/230505_Madagascar_MGX/log/%A_%a.out
#SBATCH --job-name="02b_vamb"

###########################
####    SETUP     #######
###########################
echo $SLURMD_NODENAME

source /work_beegfs/sukmb276/Metagenomes/projects/230505_Madagascar_MGX/madagascar_mgx_scripts/00_sources.txt

cd $WORKFOLDER

####################################
####    ENVIRONMENT       ########
####################################

module load miniconda3
source activate metagenome_env
module load samtools

####################################
####    CATALOG MAPPING    ########
####################################

cd $TMPDIR

mgx_new=${ALL_SAMPLES[$SLURM_ARRAY_TASK_ID]}
batch=$(grep $mgx_new $GROUPINGFILE | cut -f $BATCHCOL)

if [ -e "$WORKFOLDER/${PROJECTID}_results/subgroups/${batch}/vamb/${mgx_new}_${batch}.depth.txt" ]; then exit; fi

echo $batch $mgx_new
minimap2 -t ${SLURM_CPUS_PER_TASK} -N 50 -ax sr $WORKFOLDER/${PROJECTID}_results/subgroups/${batch}/vamb/${batch}.catalogue.mmi \
    $WORKFOLDER/${PROJECTID}_results/samples/${mgx_new}/qced_files/${mgx_new}_R1_clean.fastq.gz \
    $WORKFOLDER/${PROJECTID}_results/samples/${mgx_new}/qced_files/${mgx_new}_R2_clean.fastq.gz > ${mgx_new}.minimap.sam
samtools view -F 3584 -b --threads ${SLURM_CPUS_PER_TASK} ${mgx_new}.minimap.sam | samtools sort > ${mgx_new}.minimap.bam

jgi_summarize_bam_contig_depths --outputDepth $WORKFOLDER/${PROJECTID}_results/subgroups/${batch}/vamb/${mgx_new}_${batch}.depth.txt ${mgx_new}.minimap.bam


