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

batch_samples=($(grep $batch $GROUPINGFILE | cut -f 8))

###########################
####    VAMB        #######
###########################

module load miniconda3
source activate vamb_gpu_env

cd $WORKFOLDER/${PROJECTID}_results/vamb/${batch}

cut -f 1,2 $(ls *.depth.txt | head -n 1) > $batch.contiglengths.tsv
for i in $(ls *.depth.txt); do
cut -f 1,4,5 $i > $TMPDIR/${i}_cut
done

cd $TMPDIR
cat $(ls *.depth.txt_cut | head -n 1) > $batch.all_depths.tsv
for i in $(ls *.depth.txt_cut | tail -n+2); do
cp $batch.all_depths.tsv tmp
join tmp $i > $batch.all_depths.tsv
done

cat $batch.all_depths.tsv | awk '{if(NR==1){print "contigName totalAvgDepth"; next}{z=0; for(i=1; i<NF; ++i) z=z+$(i*2); print $1" "z}}' | join /dev/stdin $batch.all_depths.tsv > $batch.all_depths_len.tsv
join $batch.contiglengths.tsv $batch.all_depths_len.tsv > $WORKFOLDER/${PROJECTID}_results/vamb/${batch}/$batch.all_depths_final.tsv | tr ' ' '\t'

vamb --cuda -p ${SLURM_CPUS_PER_TASK} --outdir $WORKFOLDER/${PROJECTID}_results/vamb/${batch}/vamb_out --fasta $WORKFOLDER/${PROJECTID}_results/vamb/${batch}/${batch}.catalogue.fna.gz \
 --jgi $WORKFOLDER/${PROJECTID}_results/vamb/${batch}/$batch.all_depths_final.tsv -o _megahitcontig_
