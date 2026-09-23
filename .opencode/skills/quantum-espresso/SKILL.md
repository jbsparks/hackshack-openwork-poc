---
name: quantum-espresso
description: "Helps users pull the Quantum ESPRESSO container, configure GPU offload, and launch QE calculations via Slurm and singularity/apptainer with optimal GPU settings"
---

# Quantum ESPRESSO Container Skill

You are a Quantum ESPRESSO container expert. When activated, you help users:

1. Pull the QE container from NVIDIA NGC
2. Configure GPU offload for their hardware
3. Launch calculations via Slurm + Singularity/Apptainer

## Step 1: Pull the Container

Ask the user which version they need, then provide the pull command:

**Latest (v7.3.1):**
```bash
singularity pull docker://nvcr.io/hpc/quantum_espresso:v7.3.1
```

**Available tags:** v7.3.1, v7.1, v7.0, v6.8, v6.7, v6.6a1

**For Apptainer (newer name for Singularity):**
```bash
apptainer pull docker://nvcr.io/hpc/quantum_espresso:v7.3.1
```

## Step 2: Verify GPU Support

Check that the system has:
- NVIDIA GPU (Pascal sm60, Volta sm70, Ampere sm80, or Hopper sm90)
- CUDA driver >= 550 (or r535 >= 54.03, or r470 >= 57.02)
- Singularity >= 3.1 or Apptainer

```bash
nvidia-smi
singularity --version
```

## Step 3: Prepare Input Files

Provide the QE input file (pw.x format):

```bash
mkdir -p qe-work && cd qe-work
# Place your input file (e.g., scf.in) and pseudopotentials here
```

## Step 4: Download Helper Script (Optional)

```bash
wget https://gitlab.com/NVHPC/ngc-examples/-/raw/master/qe/single-node/run_qe.sh
chmod +x run_qe.sh
```

## Step 5: Run with Singularity/Apptainer

**Single-node with GPU:**
```bash
singularity run --nv \
  -B ${PWD}:/host_pwd \
  --pwd /host_pwd \
  nvcr.io/hpc/quantum_espresso:v7.3.1 \
  pw.x -input scf.in
```

**With helper script:**
```bash
singularity run --nv \
  -B ${PWD}:/host_pwd \
  --pwd /host_pwd \
  nvcr.io/hpc/quantum_espresso:v7.3.1 \
  ./run_qe.sh
```

**Environment variable for GPU count:**
```bash
export QE_GPU_COUNT=1  # Set number of GPUs to use
```

## Step 6: Slurm Batch Script (Multi-node)

Create `qe.slurm`:

```bash
#!/bin/bash
#SBATCH --job-name=qe-gpu
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=4
#SBATCH --gres=gpu:4
#SBATCH --time=01:00:00
#SBATCH --partition=gpu
#SBATCH --account=<your-project>

module load singularity/4.1.0-mpi-gpu

export OMP_NUM_THREADS=1
export OMP_PLACES=threads
export OMP_PROC_BIND=spread

srun --mpi=pmix \
  singularity run --nv \
  -B ${PWD}:/host_pwd \
  --pwd /host_pwd \
  nvcr.io/hpc/quantum_espresso:v7.3.1 \
  pw.x -input scf.in
```

**Submit:**
```bash
sbatch --account=<your-project> qe.slurm
```

## GPU Optimization Tips

| Setting | Recommendation |
|---------|----------------|
| MPI ranks per node | 1 per GPU |
| OMP_NUM_THREADS | 1 (avoid oversubscribing GPUs) |
| GPU binding | `--gpu-bind=none` for multi-GPU |
| PMIx | Use `--mpi=pmix` for Slurm |

## Common Issues

| Issue | Fix |
|-------|-----|
| LD_LIBRARY_PATH error (Singularity < 3.5) | `unset LD_LIBRARY_PATH` before running |
| Docker < 1.40 | Use `--runtime nvidia` instead of `--gpus all` |
| GPU not visible | Ensure `--nv` flag is present |
| MPI timeout | Add `MPICH_OFI_STARTUP_CONNECT=1` |

## References

- [NVIDIA NGC QE Container](https://catalog.ngc.nvidia.com/orgs/hpc/-/containers/quantum_espresso)
- [NERSC QE Documentation](https://docs.nersc.gov/applications/quantum-espresso/)
- [Pawsey Singularity Guide](https://pawsey.atlassian.net/wiki/spaces/US/pages/51925894/Singularity)
- [QE Manual](https://www.quantum-espresso.org/resources/users-manual)
