// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

include { SAMTOOLS_SORT      } from '../../../modules/nf-core/samtools/sort/main'
include { SAMTOOLS_INDEX     } from '../../../modules/nf-core/samtools/index/main'
include { BWA_MEM           } from '../../../modules/nf-core/bwa/mem/main'

workflow ALIGNMENT {

    take:
    ch_reads
    ch_fasta
    ch_index

    main:

    ch_versions = channel.empty()


    BWA_MEM ( ch_reads, ch_index, ch_fasta, false )
    ch_bam      = BWA_MEM.out.bam         // channel: [ val(meta), [ bam ] ]
    SAMTOOLS_SORT( ch_bam, ch_fasta, "bai" )
    ch_bam_bai = SAMTOOLS_SORT.out.bam.join(SAMTOOLS_SORT.out.bai)  // channel: [ val(meta), [ bam ] ]

    emit:
    bam_bai      = ch_bam_bai                    // channel: [ val(meta), [ bam, bai ] ]
    versions = ch_versions                     // channel: [ versions.yml ]
}
