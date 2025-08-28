import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter

nextflow.enable.dsl=2

// comes from nf-test to store json files
params.nf_test_output  = ""

// include dependencies

include { SETUP  } from '/workspaces/nf-core-adhdpgx/
                mkdir -p test_data
                
                # Download and cache BAM files
                if [ ! -f test_data/test.paired_end.sorted.bam ]; then
                    wget -O test_data/test.paired_end.sorted.bam https:/raw.githubusercontent.com/nf-core/test-datasets/modules/data/genomics/homo_sapiens/illumina/bam/test.paired_end.sorted.bam
                fi
                if [ ! -f test_data/test.paired_end.sorted.bam.bai ]; then
                    wget -O test_data/test.paired_end.sorted.bam.bai https:/raw.githubusercontent.com/nf-core/test-datasets/modules/data/genomics/homo_sapiens/illumina/bam/test.paired_end.sorted.bam.bai
                fi
                
                # Download reference files
                if [ ! -f test_data/genome.fasta ]; then
                    wget -O test_data/genome.fasta https:/raw.githubusercontent.com/nf-core/test-datasets/modules/data/genomics/homo_sapiens/genome/genome.fasta
                fi
                if [ ! -f test_data/genome.fasta.fai ]; then
                    wget -O test_data/genome.fasta.fai https:/raw.githubusercontent.com/nf-core/test-datasets/modules/data/genomics/homo_sapiens/genome/genome.fasta.fai
                fi
                if [ ! -f test_data/genome.dict ]; then
                    wget -O test_data/genome.dict https:/raw.githubusercontent.com/nf-core/test-datasets/modules/data/genomics/homo_sapiens/genome/genome.dict
                fi
                if [ ! -f test_data/dbsnp_146.hg38.vcf.gz ]; then
                    wget -O test_data/dbsnp_146.hg38.vcf.gz https:/raw.githubusercontent.com/nf-core/test-datasets/modules/data/genomics/homo_sapiens/genome/vcf/dbsnp_146.hg38.vcf.gz
                fi
                if [ ! -f test_data/dbsnp_146.hg38.vcf.gz.tbi ]; then
                    wget -O test_data/dbsnp_146.hg38.vcf.gz.tbi https:/raw.githubusercontent.com/nf-core/test-datasets/modules/data/genomics/homo_sapiens/genome/vcf/dbsnp_146.hg38.vcf.gz.tbi
                fi
                '


// include test workflow
include { PREPROCESSING } from '/workspaces/nf-core-adhdpgx/subworkflows/local/preprocessing/tests/../main.nf'

// define custom rules for JSON that will be generated.
def jsonOutput =
    new JsonGenerator.Options()
        .addConverter(Path) { value -> value.toAbsolutePath().toString() } // Custom converter for Path. Only filename
        .build()

def jsonWorkflowOutput = new JsonGenerator.Options().excludeNulls().build()

workflow {

    // run dependencies
    
    {
        def input = []
        null
        SETUP(*input)
    }
    

    // workflow mapping
    def input = []
    
                input[0] = Channel.of(
                    [
                        [ id:'sample1_no_bqsr', single_end:false, sex:'XX' ],
                        file('test_data/test.paired_end.sorted.bam'),
                        file('test_data/test.paired_end.sorted.bam.bai')
                    ],
                    [
                        [ id:'sample2_no_bqsr', single_end:false, sex:'XY' ],
                        file('test_data/test.paired_end.sorted.bam'),
                        file('test_data/test.paired_end.sorted.bam.bai')
                    ]
                )
                input[1] = file('test_data/genome.fasta')
                input[2] = file('test_data/genome.fasta.fai')
                input[3] = false // enable_bqsr
                input[4] = file('test_data/genome.dict')
                input[5] = [
                    [ id:'dbsnp' ],
                    file('test_data/dbsnp_146.hg38.vcf.gz')
                ]
                input[6] = [
                    [ id:'dbsnp' ],
                    file('test_data/dbsnp_146.hg38.vcf.gz.tbi')
                ]
                
    //----

    //run workflow
    PREPROCESSING(*input)
    
    if (PREPROCESSING.output){

        // consumes all named output channels and stores items in a json file
        for (def name in PREPROCESSING.out.getNames()) {
            serializeChannel(name, PREPROCESSING.out.getProperty(name), jsonOutput)
        }	  
    
        // consumes all unnamed output channels and stores items in a json file
        def array = PREPROCESSING.out as Object[]
        for (def i = 0; i < array.length ; i++) {
            serializeChannel(i, array[i], jsonOutput)
        }    	

    }
}


def serializeChannel(name, channel, jsonOutput) {
    def _name = name
    def list = [ ]
    channel.subscribe(
        onNext: {
            list.add(it)
        },
        onComplete: {
              def map = new HashMap()
              map[_name] = list
              def filename = "${params.nf_test_output}/output_${_name}.json"
              new File(filename).text = jsonOutput.toJson(map)		  		
        } 
    )
}


workflow.onComplete {

    def result = [
        success: workflow.success,
        exitStatus: workflow.exitStatus,
        errorMessage: workflow.errorMessage,
        errorReport: workflow.errorReport
    ]
    new File("${params.nf_test_output}/workflow.json").text = jsonWorkflowOutput.toJson(result)
    
}
