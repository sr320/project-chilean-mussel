#!/bin/bash
set -euo pipefail


# User-set paths
reads_dir="/mmfs1/gscratch/scrubbed/strigg/analyses/20250731_methylseq/raw-reads/"
genome_folder="/mmfs1/gscratch/scrubbed/sr320/github/project-chilean-mussel/data/Mchi"
output_dir="."
samples_file="samples.txt"

mkdir -p "$output_dir"
mkdir -p logs

# Make the sample list (overwrites each time for safety)
ls "${reads_dir}"*_R1.fastq.gz | xargs -n 1 basename | sed 's/_R1\.fastq\.gz//' | sort > "$samples_file"

# Count the number of samples for array indexing
num_samples=$(wc -l < "$samples_file")

# SLURM_ARRAY_TASK_ID safety check
if [[ -z "${SLURM_ARRAY_TASK_ID:-}" ]]; then
  echo "SLURM_ARRAY_TASK_ID is not set. Are you running as an array job?"
  exit 1
fi

if [[ "$SLURM_ARRAY_TASK_ID" -ge "$num_samples" ]]; then
  echo "SLURM_ARRAY_TASK_ID ($SLURM_ARRAY_TASK_ID) exceeds number of samples ($num_samples)."
  exit 1
fi

# Get sample for this array task
sample=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$samples_file")

r1="${reads_dir}${sample}_R1.fastq.gz"
r2="${reads_dir}${sample}_R2.fastq.gz"

if [[ ! -f "$r1" ]] || [[ ! -f "$r2" ]]; then
  echo "Missing files for $sample. Skipping."
  exit 1
fi

echo "Processing $sample"

bismark \
  -genome "$genome_folder" \
  -p 8 \
  -score_min L,0,-0.8 \
  -1 "$r1" \
  -2 "$r2" \
  -o "$output_dir" \
  --basename "$sample" \
  2> "${output_dir}/${sample}_bismark.log"
