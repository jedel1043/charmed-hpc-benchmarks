# Copyright 2026 Canonical Ltd.
# See LICENSE file for licensing details.

# Project the extended settings onto the types the remote module expects:
# `packages` is handled by this unit, not the module.
locals {
  compute_partitions = {
    for name, partition in var.compute_partitions : name => {
      constraints = partition.constraints
      units       = partition.units
    }
  }
  kiosk = {
    app_name = var.kiosk.app_name
    units    = var.kiosk.units
  }

  # Packages to install per application, keyed by application name. Only
  # applications that actually have packages are included.
  packages = {
    for app, pkgs in merge(
      { for name, partition in var.compute_partitions : name => partition.packages },
      { var.kiosk.app_name : var.kiosk.packages },
    ) : app => pkgs if length(pkgs) > 0
  }
}

module "slurm" {
  source = "git::https://github.com/canonical/charmed-hpc-terraform//modules/slurm?ref=e585d13f4a82289f6bfcd20c39f178bc5db6b30c"

  model_uuid       = var.model_uuid
  database_backend = var.database_backend

  # Optional settings for the controller node.
  controller = var.controller

  # Optional settings for the database node.
  database = {
    app_name = "slurmdbd"
  }

  # Optional settings for the REST API node.
  rest_api = {
    app_name = "slurmrestd"
  }

  # Optional settings for the kiosk node.
  kiosk = local.kiosk

  # Compute partitions to be deployed.
  compute_partitions = local.compute_partitions
}

# Since the filesystem client is a subordinate charm, it uses
# the `juju-info` endpoint to integrate with other charms.
resource "juju_integration" "kiosk-to-filesystem-client" {
  model_uuid = var.model_uuid

  application {
    name     = module.slurm.kiosk.app_name
    endpoint = "juju-info"
  }

  application {
    name     = var.filesystem_client.app_name
    endpoint = "juju-info"
  }
}

resource "juju_integration" "compute-to-filesystem-client" {
  for_each   = module.slurm.compute_partitions
  model_uuid = var.model_uuid

  application {
    name     = each.key
    endpoint = "juju-info"
  }

  application {
    name     = var.filesystem_client.app_name
    endpoint = "juju-info"
  }
}
