#!/bin/bash
#SBATCH --gres=gpu:1
#SBACTH --nodelist=medg01
#SBATCH -c 4
#SBATCH --mem=100gb
#SBATCH --time=1-00:00
#SBATCH --output=/work_beegfs/sukmb276/Metagenomes/projects/230505_Madagascar_MGX/log/%A_%a.out
#SBATCH --job-name="02c_vamb"

###########################
####    SETUP     #######
###########################
echo $SLURMD_NODENAME

source /work_beegfs/sukmb276/Metagenomes/projects/230505_Madagascar_MGX/madagascar_mgx_scripts/00_sources.txt

cd $WORKFOLDER

####################################
####    GROUP SELECTION     ########
####################################

batch=${ALL_BATCHES[$SLURM_ARRAY_TASK_ID]}

batch_samples=($(grep $batch $GROUPINGFILE | cut -f $IDCOL))

###########################
####    VAMB        #######
###########################

module load miniconda3

if [ -e "$WORKFOLDER/${PROJECTID}_results/subgroups/${batch}/vamb/vamb_out/clusters_sorted.tsv" ]; then exit; fi

cd $WORKFOLDER/${PROJECTID}_results/subgroups/${batch}/vamb

### retain only name and colum
cut -f 1,2 $(ls *.depth.txt | head -n 1) > $TMPDIR/$batch.contiglengths.tsv

## retain name, depth and var for each sample
for i in $(ls *.depth.txt); do
cut -f 1,4,5 $i > $TMPDIR/${i}_cut
done

cd $TMPDIR
### use first sample as starting point
cat $(ls *.depth.txt_cut | head -n 1) > $batch.all_depths.tsv

source activate r_microbiome_env
### iteratively join sample depths
R --vanilla < """
library(tidyverse)
all_depths=lapply(list.files(pattern='.depth.txt_cut'), read.table, head=T, stringsAsFactors=F)
all_depths_joined = all_depths %>% reduce(full_join, by='contigName')
write.table(all_depths_joined, 'all_depths.tsv', sep=' ', row.names=F, quote=F)
"""

# for i in $(ls *.depth.txt_cut | tail -n+2); do
# cp $batch.all_depths.tsv tmp
# join tmp $i > $batch.all_depths.tsv
# done

### calculate total coverage
cat all_depths.tsv | awk '{if(NR==1){print "contigName totalAvgDepth"; next}{z=0; for(i=1; i<NF; ++i) z=z+$(i*2); print $1" "z}}' | join /dev/stdin all_depths.tsv | sed 's/[.]var/-var/g' > $batch.all_depths_len.tsv

### join all files
join $batch.contiglengths.tsv $batch.all_depths_len.tsv | tr ' ' '\t' > $WORKFOLDER/${PROJECTID}_results/subgroups/${batch}/vamb/$batch.all_depths_final.tsv 


source activate vamb_gpu_env

vamb --cuda -p ${SLURM_CPUS_PER_TASK} --outdir $WORKFOLDER/${PROJECTID}_results/subgroups/${batch}/vamb/vamb_out --fasta $WORKFOLDER/${PROJECTID}_results/subgroups/${batch}/vamb/${batch}.catalogue.fna.gz \
 --jgi $WORKFOLDER/${PROJECTID}_results/vsubgroups/${batch}/vamb/$batch.all_depths_final.tsv -o _megahitcontig_

sort -k 1 $WORKFOLDER/${PROJECTID}_results/subgroups/${batch}/vamb/vamb_out/clusters.tsv | awk -v batch=$batch 'BEGIN{cl=0; thisclust=""}{if($1!=thisclust){thisclust=$1; ++cl}; printf batch"_vamb_"cl"\t"$2"\n" }' >  $WORKFOLDER/${PROJECTID}_results/subgroups/${batch}/vamb/vamb_out/clusters_sorted.tsv

for mgx_new in ${batch_samples[@]}; do
grep "${mgx_new}_" $WORKFOLDER/${PROJECTID}_results/subgroups/${batch}/vamb/vamb_out/clusters_sorted.tsv > $WORKFOLDER/${PROJECTID}_results/samples/${mgx_new}/binning/${mgx_new}_vamb_contigs_to_bin.tsv
done