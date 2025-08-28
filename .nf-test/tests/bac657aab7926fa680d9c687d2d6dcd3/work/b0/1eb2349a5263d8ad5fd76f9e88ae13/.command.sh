#!/usr/bin/env bash -C -e -u -o pipefail
gatk --java-options "-Xmx9830M -XX:-UsePerfData" \
    MarkDuplicates \
    --INPUT test.paired_end.sorted.bam \
    --OUTPUT test_sample.bam \
    --METRICS_FILE test_sample.bam.metrics \
    --TMP_DIR . \
    --REFERENCE_SEQUENCE genome.fasta \


# If cram files are wished as output, the run samtools for conversion
if [[ test_sample.bam == *.cram ]]; then
    samtools view -Ch -T genome.fasta -o test_sample.bam test_sample.bam
    rm test_sample.bam
    samtools index test_sample.bam
fi

cat <<-END_VERSIONS > versions.yml
"PREPROCESSING:GATK4_MARKDUPLICATES":
    gatk4: $(echo $(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*$//')
    samtools: $(echo $(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*$//')
END_VERSIONS
