// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

include { GATK4_MARKDUPLICATES } from '../../../modules/nf-core/gatk4/markduplicates/main'
include { GATK4_APPLYBQSR } from '../../../modules/nf-core/gatk4/applybqsr/main'
include { GATK4_BASERECALIBRATOR } from '../../../modules/nf-core/gatk4/baserecalibrator/main'


workflow PREPROCESSING {
    take:
    ch_bam_bai      // channel: [ val(meta), bam, bai ]
    fasta           // path: fasta file  
    fasta_fai       // path: fasta.fai file
    enable_bqsr     // val: true/false
    dict            // path: dict file
    known_sites     // path: vcf file
    known_sites_tbi // path: vcf.tbi file

    main:

    ch_versions = Channel.empty()

    // Mark duplicates - these modules expect single path inputs
    GATK4_MARKDUPLICATES( ch_bam_bai, fasta, fasta_fai )
    ch_versions = ch_versions.mix(GATK4_MARKDUPLICATES.out.versions.first())
    
    md_bam_bai = GATK4_MARKDUPLICATES.out.bam.join(GATK4_MARKDUPLICATES.out.bai)

    if( enable_bqsr ) {
        // For BASERECALIBRATOR, we need to create proper channel tuples
        ch_fasta_tuple = Channel.value([ [id: 'genome'], fasta ])
        ch_fai_tuple = Channel.value([ [id: 'genome'], fasta_fai ])
        ch_dict_tuple = Channel.value([ [id: 'genome'], dict ])
        ch_known_sites_tuple = Channel.value([ [id: 'known_sites'], known_sites ])
        ch_known_sites_tbi_tuple = Channel.value([ [id: 'known_sites'], known_sites_tbi ])
        
        // Base quality score recalibration
        GATK4_BASERECALIBRATOR(
            md_bam_bai.map { meta, bam, bai -> [ meta, bam, bai, [] ] }, // add empty intervals
            ch_fasta_tuple, 
            ch_fai_tuple, 
            ch_dict_tuple, 
            ch_known_sites_tuple, 
            ch_known_sites_tbi_tuple
        )
        ch_versions = ch_versions.mix(GATK4_BASERECALIBRATOR.out.versions.first())
        
        ch_recal_input = md_bam_bai.join(GATK4_BASERECALIBRATOR.out.table)
        
        GATK4_APPLYBQSR(ch_recal_input, ch_fasta_tuple, ch_fai_tuple, ch_dict_tuple)
        ch_versions = ch_versions.mix(GATK4_APPLYBQSR.out.versions.first())
        
        ch_final_bam_bai = GATK4_APPLYBQSR.out.bam.join(GATK4_APPLYBQSR.out.bai)
    } else {
        ch_final_bam_bai = md_bam_bai
    }

    emit:
    bam_bai  = ch_final_bam_bai     // channel: [ val(meta), bam, bai ]
    versions = ch_versions          // channel: [ versions.yml ]
}
