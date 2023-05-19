module load singularity nextflow

source /work_beegfs/sukmb276/Metagenomes/projects/230505_Madagascar_MGX/madagascar_mgx_scripts/00_sources.txt
cd $WORKFOLDER

cat batch_lists/Batch_*_list.csv | grep -v id | awk 'BEGIN{print "id,read1,read2"}{print $0}' > batch_lists/ALL_list.csv

#for batch in $(cut -f 9 $WORKFOLDER/sample_mgx_all.tsv | sort | uniq | grep -v Batch ); do
for batch in Andina5B Andina3A Andina3B REDO; do


nextflow run ikmb/TOFU-MAaPO --reads "/work_beegfs/sukmb276/Metagenomes/projects/230505_Madagascar_MGX/batch_lists/Batch_${batch}_list.csv" \
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

for i in $(grep keep:1 mntr.tsc | grep -v ":," | cut -d ',' -f 1-2); do
echo $i
read MGX_NEW Batch2 <<< $(echo $i | tr ',' ' ')
mkdir ${PROJECTID}_results/samples/$MGX_NEW 
mkdir ${PROJECTID}_results/samples/$MGX_NEW/qced_files
mkdir ${PROJECTID}_results/samples/$MGX_NEW/megahit
mkdir ${PROJECTID}_results/samples/$MGX_NEW/binning
mkdir ${PROJECTID}_results/samples/$MGX_NEW/counttable
mv ${Batch2}_results/qced_files/${MGX_NEW}_*_clean.fastq.gz ${PROJECTID}_results/samples/$MGX_NEW/qced_files
mv ${Batch2}_results/Megahit/${MGX_NEW}_final.contigs.fa ${PROJECTID}_results/samples/$MGX_NEW/megahit
mv ${Batch2}_results/concoct/${MGX_NEW}/${MGX_NEW}_concoct_contigs_to_bin.tsv ${PROJECTID}_results/samples/$MGX_NEW/binning
mv ${Batch2}_results/Metabat2/${MGX_NEW}/${MGX_NEW}_metabat2_contigs_to_bins.tsv ${PROJECTID}_results/samples/$MGX_NEW/binning/${MGX_NEW}_metabat2_contigs_to_bin.tsv
mv ${Batch2}_results/maxbin2/${MGX_NEW}/${MGX_NEW}_maxbin2_contigs_to_bin.tsv ${PROJECTID}_results/samples/$MGX_NEW/binning
cp ${Batch2}_results/counttable/${MGX_NEW}/* ${PROJECTID}_results/samples/$MGX_NEW/counttable

done



for MGX_NEW in $(grep keep:1 mntr.tsc | grep -v "QC:3," | grep ":," | cut -d ',' -f 1-2); do
echo $MGX_NEW
mkdir $WORKFOLDER/${PROJECTID}_results/samples/$MGX_NEW 
mkdir $WORKFOLDER/${PROJECTID}_results/samples/$MGX_NEW/qced_files
mv ${MGX_NEW}_*_clean.fastq.gz $WORKFOLDER/${PROJECTID}_results/samples/$MGX_NEW/qced_files
done


for MGX_NEW in $(ls *R1_clean.fastq.gz | cut -d "_" -f 1); do
echo $MGX_NEW
mkdir ${PROJECTID}_results/samples/$MGX_NEW 
mkdir ${PROJECTID}_results/samples/$MGX_NEW/qced_files
mv ${MGX_NEW}_*_clean.fastq.gz $WORKFOLDER/${PROJECTID}_results/samples/$MGX_NEW/qced_files
done

####

grep keep:1 mntr.tsc | grep ":," | cut -d ',' -f 1 | awk -v wd=$PWD 'BEGIN{print "id,read1,read2,read3"}{printf $1","wd"/Madagascar_results/samples/"$1"/qced_files/"$1"_R1_clean.fastq.gz,"wd"/Madagascar_results/samples/"$1"/qced_files/"$1"_R2_clean.fastq.gz,"wd"/Madagascar_results/samples/"$1"/qced_files/"$1"_single_clean.fastq.gz\n"}' > batch_lists/run_assembly.csv

nextflow run ikmb/TOFU-MAaPO -r dev --reads "/work_beegfs/sukmb276/Metagenomes/projects/230505_Madagascar_MGX/batch_lists/run_assembly.csv" \
--no_qc \
--outdir Madagascar_redo_results \
-work-dir work_redo \
--magscot \
--publish_megahit \
--publish_rawbins \
--skip_vamb \
--skip_gtdbtk \
--skip_checkm \
-with-dag flowchart.svg

for MGX_NEW in $(cut -d ',' -f 1 batch_lists/run_assembly.csv); do 
echo $MGX_NEW
mkdir Madagascar_results/samples/$MGX_NEW/megahit
mkdir Madagascar_results/samples/$MGX_NEW/binning
mkdir Madagascar_results/samples/$MGX_NEW/counttable
mv Madagascar_redo_results/Megahit/${MGX_NEW}_final.contigs.fa Madagascar_results/samples/$MGX_NEW/megahit
mv Madagascar_redo_results/concoct/${MGX_NEW}/${MGX_NEW}_concoct_contigs_to_bin.tsv Madagascar_results/samples/$MGX_NEW/binning
mv Madagascar_redo_results/Metabat2/${MGX_NEW}/${MGX_NEW}_metabat2_contigs_to_bins.tsv Madagascar_results/samples/$MGX_NEW/binning/${MGX_NEW}_metabat2_contigs_to_bin.tsv
mv Madagascar_redo_results/maxbin2/${MGX_NEW}/${MGX_NEW}_maxbin2_contigs_to_bin.tsv Madagascar_results/samples/$MGX_NEW/binning
cp Madagascar_redo_results/counttable/${MGX_NEW}/* Madagascar_results/samples/$MGX_NEW/counttable
mv ${Batch2}_results/magscot/${MGX_NEW}/${MGX_NEW}.hmm Madagascar_results/samples/$MGX_NEW/binning
mv ${Batch2}_results/magscot/${MGX_NEW}/${MGX_NEW}_fcontigsfiltered.fa Madagascar_results/samples/$MGX_NEW/megahit
done

nextflow run ikmb/TOFU-MAaPO --reads "/work_beegfs/sukmb276/Metagenomes/projects/230505_Madagascar_MGX/batch_lists/run_assembly.csv" \
--no_qc \
--outdir Madagascar_results \
-work-dir work_redo \
--metaphlan \
-with-dag flowchart.svg