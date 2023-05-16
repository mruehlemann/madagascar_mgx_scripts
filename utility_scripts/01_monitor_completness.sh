source /work_beegfs/sukmb276/Metagenomes/projects/230505_Madagascar_MGX/madagascar_mgx_scripts/00_sources.txt
cd $workfolder

while read line; do read ID CSB Num MGX_ID SeqID Subject_ID Batch MGX_NEW Batch2 <<< $(echo $line);
if [ "$Batch2" == "" ]; then continue; fi
qced=$(ls ${Batch2}_results/qced_files/${MGX_NEW}_*_clean.fastq.gz | wc -l)
megahit=$(ll ${Batch2}_results/Megahit/${MGX_NEW}_final.contigs.fa | cut -f 5 -d ' ')
concoct=$(wc -l ${Batch2}_results/concoct/${MGX_NEW}/${MGX_NEW}_concoct_contigs_to_bin.tsv | cut -f 1 -d " ")
metabat=$(wc -l ${Batch2}_results/Metabat2/${MGX_NEW}/${MGX_NEW}_metabat2_contigs_to_bins.tsv | cut -f 1 -d " ")
maxbin=$(wc -l ${Batch2}_results/maxbin2/${MGX_NEW}/${MGX_NEW}_maxbin2_contigs_to_bin.tsv | cut -f 1 -d " ")
keep=$(grep $MGX_NEW batch_lists/Batch_${Batch2}_list.csv | wc -l)
echo "$MGX_NEW,$Batch2,QC:$qced,Megahit:$megahit,concoct:$concoct,metabat:$metabat,maxbin:$maxbin,keep:$keep"
done < $workfolder/sample_mgx_all.tsv | tee mntr.tsc


while read line; do read ID CSB Num MGX_ID SeqID Subject_ID Batch MGX_NEW Batch2 <<< $(echo $line);
if [ "$Batch2" == "" ]; then continue; fi
Batch="Madagascar"
qced=$(ls ${Batch2}_results/qced_files/${MGX_NEW}_*_clean.fastq.gz | wc -l)
megahit=$(ll ${Batch2}_results/Megahit/${MGX_NEW}_final.contigs.fa | cut -f 5 -d ' ')
concoct=$(wc -l ${Batch2}_results/concoct/${MGX_NEW}/${MGX_NEW}_concoct_contigs_to_bin.tsv | cut -f 1 -d " ")
metabat=$(wc -l ${Batch2}_results/Metabat2/${MGX_NEW}/${MGX_NEW}_metabat2_contigs_to_bins.tsv | cut -f 1 -d " ")
maxbin=$(wc -l ${Batch2}_results/maxbin2/${MGX_NEW}/${MGX_NEW}_maxbin2_contigs_to_bin.tsv | cut -f 1 -d " ")
keep=$(grep $MGX_NEW batch_lists/Batch_${Batch2}_list.csv | wc -l)
echo "$MGX_NEW,$Batch2,QC:$qced,Megahit:$megahit,concoct:$concoct,metabat:$metabat,maxbin:$maxbin,keep:$keep"
done < $workfolder/sample_mgx_all.tsv | tee mntr_new.csv