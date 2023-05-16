module load singularity nextflow

source /work_beegfs/sukmb276/Metagenomes/projects/230505_Madagascar_MGX/madagascar_mgx_scripts/00_sources.txt
cd $WORKFOLDER

cat batch_lists/Batch_*_list.csv | grep -v id | awk 'BEGIN{print "id,read1,read2"}{print $0}' > batch_lists/ALL_list.csv

#for batch in $(cut -f 9 $WORKFOLDER/sample_mgx_all.tsv | sort | uniq | grep -v Batch ); do
for batch in Andina5B Andina3A Andina3B REDO; do


nextflow run ikmb/TOFU-MAaPO --reads "/work_beegfs/sukmb276/Metagenomes/projects/230505_Madagascar_MGX/batch_lists/ALL_list.csv" \
--genome human \
--outdir ${PROJECTID}_results \
--min_read_length=60 \
--cleanreads \
-work-dir work_${PROJECTID} \
-with-dag flowchart.svg

rm -r work_${batch}

done

####

mkdir -p ${PROJECTID}_results/samples

for mgx_new in $(cut -d ',' -f 1 $WORKFOLDER/batch_lists/ALL_list.csv); do
echo $mgx_new
mkdir ${PROJECTID}_results/samples/$mgx_new 
mkdir ${PROJECTID}_results/samples/$mgx_new/qced_files
mv ${Batch2}_results/qced_files/${mgx_new}_*_clean.fastq.gz ${PROJECTID}_results/samples/$mgx_new/qced_files
done

cut -d ',' -f 1 $WORKFOLDER/batch_lists/ALL_list.csv | awk -v wd=$WORKFOLDER -v projectid=$PROJECTID 'BEGIN{print "id,read1,read2,read3"}{printf $1","wd"/"projectid"_results/samples/"$1"/qced_files/"$1"_R1_clean.fastq.gz,"wd"/"projectid"_results/samples/"$1"/qced_files/"$1"_R2_clean.fastq.gz,"wd"/"projectid"_results/samples/"$1"/qced_files/"$1"_single_clean.fastq.gz\n"}' > batch_lists/run_assembly.csv

nextflow run ikmb/TOFU-MAaPO -r dev --reads "$WORKFOLDER/batch_lists/run_assembly.csv" \
--no_qc \
--outdir ${PROJECTID}_redo_results \
-work-dir work_redo \
--magscot \
--publish_megahit \
--publish_rawbins \
--skip_vamb \
--skip_gtdbtk \
--skip_checkm \
-with-dag flowchart.svg

for mgx_new in $(cut -d ',' -f 1 $PROJECTID/batch_lists/run_assembly.csv); do
echo $mgx_new
mkdir ${PROJECTID}_results/samples/$mgx_new/megahit
mkdir ${PROJECTID}_results/samples/$mgx_new/binning
mkdir ${PROJECTID}_results/samples/$mgx_new/counttable
mv ${PROJECTID}_redo_results/Megahit/${mgx_new}_final.contigs.fa ${PROJECTID}_results/samples/$mgx_new/megahit
mv ${PROJECTID}_redo_results/concoct/${mgx_new}/${mgx_new}_concoct_contigs_to_bin.tsv ${PROJECTID}_results/samples/$mgx_new/binning
mv ${PROJECTID}_redo_results/Metabat2/${mgx_new}/${mgx_new}_metabat2_contigs_to_bins.tsv ${PROJECTID}_results/samples/$mgx_new/binning/${mgx_new}_metabat2_contigs_to_bin.tsv
mv ${PROJECTID}_redo_results/maxbin2/${mgx_new}/${mgx_new}_maxbin2_contigs_to_bin.tsv ${PROJECTID}_results/samples/$mgx_new/binning
cp ${PROJECTID}_redo_results/counttable/${mgx_new}/* ${PROJECTID}_results/samples/$mgx_new/counttable
mv ${PROJECTID}_results/magscot/${mgx_new}/${mgx_new}.hmm ${PROJECTID}_results/samples/$mgx_new/binning
mv ${PROJECTID}_results/magscot/${mgx_new}/${mgx_new}_fcontigsfiltered.fa ${PROJECTID}_results/samples/$mgx_new/megahit
done


nextflow run ikmb/TOFU-MAaPO --reads "$WORKFOLDER/batch_lists/run_assembly.csv" \
--no_qc \
--outdir ${PROJECTID}_results \
-work-dir work_redo \
--metaphlan \
-with-dag flowchart.svg

