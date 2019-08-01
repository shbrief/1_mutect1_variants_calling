workflow M1_variant_calling {
    # inputs
    Array[File] tumor_bams
    Array[File] tumor_bais
    Array[File]? normal_bams
    Array[File]? normal_bais
    
    Array[Pair[File,File]] tumor_bam_pairs = zip(tumor_bams, tumor_bais)
    
    scatter (tumor_bam_pair in tumor_bam_pairs) {
        File tumor_bam = tumor_bam_pair.left
        File tumor_bai = tumor_bam_pair.right
        
        call M1_var {
            input:
                tumor_bam = tumor_bam,
                tumor_bai = tumor_bai
        }
    }
    
    output {
        Array[File] var_calls = M1_var.output_pon_vcf
        Array[File] var_calls_idx = M1_var.output_pon_vcf_index
        Array[File] var_calls_stats = M1_var.output_pon_stats_txt
    }
}

task M1_var {
	# input
	File tumor_bam
	File tumor_bai
	File dbsnp_vcf
	File dbsnp_vcf_idx
	File cosmicVCF
	File cosmicVCF_idx
	File ref_fasta
	File ref_fai
	File ref_dict

	String BAM_pre = basename(tumor_bam, ".bam")

	# runtime
	String mutect1_docker
    Int disk_size = ceil(size(tumor_bam, "GB")) + 30

	command <<<
		java -jar -Xmx4g /home/mutect-1.1.7.jar \
		--analysis_type MuTect \
		-R ${ref_fasta} \
		--dbsnp ${dbsnp_vcf} \
		--cosmic ${cosmicVCF} \
		-I:tumor ${tumor_bam} \
		-o ${BAM_pre}_mutect_stats.txt \
		-vcf ${BAM_pre}_mutect.vcf
	>>>

	runtime {
		docker: mutect1_docker   # jvivian/mutect
		memory: "32 GB"
		disks: "local-disk " + disk_size + " HDD"
	}

    output {
        File output_pon_vcf = "${BAM_pre}_pon.vcf"
        File output_pon_vcf_index = "${BAM_pre}_pon.vcf.idx"        
        File output_pon_stats_txt = "${BAM_pre}_pon_stats.txt"
    }
}