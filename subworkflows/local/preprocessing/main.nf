include { GATK4_MARKDUPLICATES } from '../../../modules/nf-core/gatk4/markduplicates/main'
include { GATK4_APPLYBQSR } from '../../../modules/nf-core/gatk4/applybqsr/main'
include { GATK4_BASERECALIBRATOR } from '../../../modules/nf-core/gatk4/baserecalibrator/main'
include { SAMTOOLS_INDEX as INDEX_BAM } from '../../../modules/nf-core/samtools/index/main'
include { SAMTOOLS_INDEX as INDEX_BAM2 } from '../../../modules/nf-core/samtools/index/main'



workflow PREPROCESSING {
    take:
    ch_bam          // channel: [ val(meta), bam ]
    ch_fasta           // value channel: [val(meta), fasta ]  
    ch_fai       // value channel [ val(meta), fasta.fai ]
    enable_bqsr     // val: true/false
    ch_dict            // value channel: [val(meta), dict ]
    ch_known_sites     // value channel: [val(meta), known_sites ]
    ch_known_sites_tbi // value channel: [val(meta), knwon_sites.tbi ]


    main:
    ch_versions = channel.empty()

    // Mark duplicates - takes [meta, bam], outputs [meta, bam] and [meta, bai]
    
    GATK4_MARKDUPLICATES( ch_bam, ch_fasta.map{it -> it[1]}, ch_fai.map{it -> it[1]} )

    ch_bam.view { meta, bam -> println "before: ${meta.id} -> ${bam}" }

    // Join the new BAM and BAI from MarkDuplicates
    md_bam = GATK4_MARKDUPLICATES.out.bam

    INDEX_BAM( md_bam )
    md_bam_bai = md_bam.join(INDEX_BAM.out.bai)

    if( enable_bqsr ) {

        // Base quality score recalibration
        GATK4_BASERECALIBRATOR(
            md_bam_bai.map { meta, bam, bai -> tuple( meta, bam, bai, [] )}, // add empty intervals
            ch_fasta, 
            ch_fai, 
            ch_dict, 
            ch_known_sites, 
            ch_known_sites_tbi
        )
        ch_versions = ch_versions.mix(GATK4_BASERECALIBRATOR.out.versions.first())
        
        // Join BAM/BAI with recalibration table
        ch_recal_input = md_bam_bai.join(GATK4_BASERECALIBRATOR.out.table)
        ch_recal_input_intervals = ch_recal_input.map { meta, bam, bai, table -> tuple( meta, bam, bai, table, [] ) }
        
        GATK4_APPLYBQSR(
            ch_recal_input_intervals,
            ch_fasta.map{it -> it[1]},
            ch_fai.map{it -> it[1]},
            ch_dict.map{it -> it[1]}
        )
        ch_versions = ch_versions.mix(GATK4_APPLYBQSR.out.versions.first())

        INDEX_BAM2( GATK4_APPLYBQSR.out.bam )
        
        ch_final_bam_bai = GATK4_APPLYBQSR.out.bam.join(INDEX_BAM2.out.bai)
    } else {
        ch_final_bam_bai = md_bam_bai
    }

    emit:
    bam  = ch_final_bam_bai                   // channel: [ val(meta), bam, bai ]
    metrics  = GATK4_MARKDUPLICATES.out.metrics   // channel: [ val(meta), metrics ]
    versions = ch_versions                         // channel: [ versions.yml ]
}
