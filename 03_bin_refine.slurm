#!/bin/bash
#SBATCH -c 1
#SBATCH --mem=10gb
#SBATCH --time=1-00:00
#SBATCH --output=/work_beegfs/sukmb276/Metagenomes/projects/230505_Madagascar_MGX/log/%A_%a.out
#SBATCH --job-name="03_magscot"

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

if [ -e "$WORKFOLDER/${PROJECTID}_results/samples/${mgx_new}/binning/${mgx_new}.refined.contig_to_bin.out" ]; then exit; fi

module load miniconda3

cd $WORKFOLDER/${PROJECTID}_results/samples/${mgx_new}/binning

awk '{print $1"\t"$2"\tvamb"}' ${mgx_new}_vamb_contigs_to_bin.tsv > ${mgx_new}.contigs_to_bin_final.tsv
awk '{print $1"\t"$2"\tconcoct"}'  ${mgx_new}_concoct_contigs_to_bin.tsv >> ${mgx_new}.contigs_to_bin_final.tsv
awk '{print $1"\t"$2"\tmetabat2"}'  ${mgx_new}_metabat2_contigs_to_bin.tsv >> ${mgx_new}.contigs_to_bin_final.tsv
awk '{print $1"\t"$2"\tmaxbin2"}'  ${mgx_new}_maxbin2_contigs_to_bin.tsv >> ${mgx_new}.contigs_to_bin_final.tsv

source activate MAGScoT_env

Rscript $MAGSCOT_EXEC -i ${mgx_new}.contigs_to_bin_final.tsv --hmm ${mgx_new}.hmm -o ${mgx_new}

conda activate mgx_tools_env

mkdir cleanbins
for bin in $(tail -n+2 ${mgx_new}.refined.contig_to_bin.out | cut -f 1 | uniq); do
    echo $bin
    grep -w $bin ${mgx_new}.refined.contig_to_bin.out | cut -f 2 | faSomeRecords $WORKFOLDER/${PROJECTID}_results/samples/$mgx_new/megahit/${mgx_new}_fcontigsfiltered.fa /dev/stdin cleanbins/$bin.fna
done