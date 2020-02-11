Based on https://github.com/freeseek/imputec4

## Prepare docker image

docker run -v "/${PWD}":/home/C4 --rm -ti --security-opt seccomp=unconfined ubuntu:latest
apt-get update
apt-get -y install curl
apt-get install wget gzip samtools bcftools plink1.9 openjdk-11-jre-headless

docker ps
docker commit

## Use new image

docker run -v "/${PWD}":/home/C4 --rm -ti --security-opt seccomp=unconfined imputec4
cd /home/C4/
mkdir -p res
wget -P res/ https://faculty.washington.edu/browning/beagle/beagle.25Nov19.28d.jar
wget -P res/ https://personal.broadinstitute.org/giulio/panels/MHC_haplotypes_CEU_HapMap3_ref_panel.GRCh3{7,8}.vcf.gz

### Run imputation with Beagle

vcf="tmp-data/1000G-MHC.vcf.gz"
bcftools index $vcf
out="res/impute-C4"
build=37
declare -A reg=( ["37"]="6:24894177-33890574" ["38"]="chr6:24893949-33922797" )

bcftools view --no-version "$vcf" -r ${reg[$build]} | \
  java -Xmx8g -jar res/beagle.25Nov19.28d.jar gt=/dev/stdin \
  ref=res/MHC_haplotypes_CEU_HapMap3_ref_panel.GRCh$build.vcf.gz out="$out" \
  map=<(bcftools query -f "%CHROM\t%POS\n" res/MHC_haplotypes_CEU_HapMap3_ref_panel.GRCh$build.vcf.gz | \
  awk '{print $1"\t.\t"$2/1e7"\t"$2}')
  
### Extract imputed C4 alleles into a table

declare -A reg=( ["37"]="6:31948000-31948000" ["38"]="chr6:31980223-31980223" )

bcftools index -ft "$out.vcf.gz" && \
bcftools query -f "[%SAMPLE\t%ALT\t%GT\n]" "$out.vcf.gz" -r ${reg[$build]} | tr -d '[<>]' | \
  awk -F"\t" -v OFS="\t" '{split($2,a,","); a["0"]="NA"; split($3,b,"|"); \
  print $1,a[b[1]],a[b[2]]}' > "$out.tsv"
