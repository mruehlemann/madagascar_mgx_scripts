#!/bin/bash
#SBATCH -c 10
#SBATCH --mem=100gb
#SBATCH --time=1-00:00
#SBATCH --output=/work_beegfs/sukmb276/Metagenomes/projects/230505_Madagascar_MGX/log/%A_%a.out
#SBATCH --job-name="02a_vamb"

###########################
####    SETUP       #######
###########################
echo $SLURMD_NODENAME

source /work_beegfs/sukmb276/Metagenomes/projects/230505_Madagascar_MGX/madagascar_mgx_scripts/00_sources.txt

cd $WORKFOLDER

####################################
####    GROUP SELECTION     ########
####################################

batch=${ALL_BATCHES[$SLURM_ARRAY_TASK_ID]}

cd ${batch}_results

batch_samples=($(grep $batch $GROUPINGFILE | cut -f $IDCOL))

####################################
####    ENVIRONMENT    ########
####################################

module load miniconda3
source activate metagenome_env
module load samtools

####################################
####    CATALOG CREATION    ########
####################################

cd $TMPDIR

if [ -e "$WORKFOLDER/${PROJECTID}_results/subgroups/${batch}/vamb/${batch}.catalogue.mmi" ]; then exit; fi

for mgx_new in ${batch_samples[@]}; do
    cat $WORKFOLDER/${PROJECTID}_results/samples/$mgx_new/megahit/${mgx_new}_fcontigsfiltered.fa > ${mgx_new}.sample.fasta
done

cat *.sample.fasta > ${batch}.catalogue.fna

rm *.sample.fasta

minimap2 -I100G -d ${batch}.catalogue.mmi ${batch}.catalogue.fna # make index

gzip ${batch}.catalogue.fna

mkdir -p $WORKFOLDER/${PROJECTID}_results/subgroups/${batch}/vamb

mv ${batch}.catalogue.fna.gz $WORKFOLDER/${PROJECTID}_results/subgroups/${batch}/vamb/
mv ${batch}.catalogue.mmi $WORKFOLDER/${PROJECTID}_results/subgroups/${batch}/vamb/
