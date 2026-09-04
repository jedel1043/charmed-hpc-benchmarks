# Copyright 2026 Canonical Ltd.
# See LICENSE file for licensing details.

stack "slurm" {
  source = "${get_path_to_repo_root()}/stacks/slurm"
  path   = "slurm"

  values = {
    kiosk = {
      # Toolchain for building the ReFrame test applications on the login
      # node.
      packages = [
        "libopenmpi-dev",
        "build-essential",
        "python3-venv",
        "nvidia-cuda-toolkit-gcc",
      ]
    }

    compute_partitions = {
      "hb120rs-v3" : {
        constraints = "arch=amd64 instance-type=Standard_HB120rs_v3"
        units       = 2
        config = {
          # Start benchmark nodes in idle so jobs can be scheduled without a
          # manual `set-node-state` after deployment.
          default-node-state = "idle"
        }
      }
      "nc4as-t4-v3" : {
        constraints = "arch=amd64 instance-type=Standard_NC4as_T4_v3"
        units       = 1
        config = {
          default-node-state = "idle"
        }
        # CUDA BLAS library needed by the gpu_burn benchmark.
        packages = ["libcublas12"]
      }
    }
  }
}
