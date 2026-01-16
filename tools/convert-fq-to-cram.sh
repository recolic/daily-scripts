# note: fq base could be downloaded from Internet. Most gene testing company are using GRCh38

# convert fastq to cram+crai
minimap2 -t $(nproc) -a -x sr fq-base/Homo_sapiens.GRCh38.dna.primary_assembly.fa NG1CFEHD1B_1.fq NG1CFEHD1B_2.fq  -o CE.sam

samtools view -bS CE.sam | samtools sort -o CE.sorted.bam
samtools view -C -T fq-base/Homo_sapiens.GRCh38.dna.primary_assembly.fa -o CE.cram CE.sorted.bam
samtools index CE.cram

