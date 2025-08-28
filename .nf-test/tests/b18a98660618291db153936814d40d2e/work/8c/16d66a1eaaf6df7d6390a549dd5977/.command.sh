#!/usr/bin/env bash -C -e -u -o pipefail
gatk --java-options "-Xmx9830M -XX:-UsePerfData" \
    MarkDuplicates \
    --INPUT test.paired_end.sorted.bam \
    --OUTPUT sample1.bam \
    --METRICS_FILE sample1.bam.metrics \
    --TMP_DIR . \
    --REFERENCE_SEQUENCE genome.fasta \


# If cram files are wished as output, the run samtools for conversion
if [[ sample1.bam == *.cram ]]; then
    samtools view -Ch -T genome.fasta -o sample1.bam sample1.bam
    rm sample1.bam
    samtools index sample1.bam
fi

cat <<-END_VERSIONS > versions.yml
"PREPROCESSING:GATK4_MARKDUPLICATES":
    gatk4: $(echo $(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*$//')
    samtools: $(echo $(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*$//')
END_VERSIONS
