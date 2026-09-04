# Copyright 2026 Canonical Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Install apt packages on the machines of the given Juju applications.
#
# The Terraform Juju provider only waits for machines to be allocated and
# units to be created when applying an application; it does not wait for the
# unit agents to start. `juju exec` cannot reach a unit until its agent is
# up, so each provisioner first polls `juju status` until every unit of the
# application reports a started agent, and only then installs the packages.
resource "null_resource" "packages" {
  for_each = var.packages

  triggers = {
    app      = each.key
    packages = join(" ", sort(each.value))
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      APP        = each.key
      PACKAGES   = join(" ", each.value)
      MODEL_UUID = var.model_uuid
      SETUP_CMD  = var.juju_cli_setup_command
      PASSWORD   = var.juju_cli_password
    }

    command = <<-EOT
      set -euo pipefail

      # Set up Juju CLI access to the controller. The setup command exports
      # JUJU_DATA and logs in; the password is piped to `juju login` so it
      # does not prompt. Idempotent: safe to run on every apply.
      printf '%s\n' "$PASSWORD" | eval "$SETUP_CMD"

      # Wait until every unit of the application has a started agent.
      units_started() {
        juju status -m "$MODEL_UUID" "$APP" --format=json 2>/dev/null | jq -r --arg app "$APP" \
          '(.applications[$app].units | length) > 0
           and ([.applications[$app].units[].agent-status.current] | all(. == "started"))'
      }
      attempts=0
      until [ "$(units_started)" = "true" ]; do
        attempts=$((attempts+1))
        if [ "$attempts" -gt 120 ]; then
          echo "timed out waiting for units of '$APP' to start" >&2
          exit 1
        fi
        sleep 10
      done

      # Install the packages on every unit of the application.
      for unit in $(juju status -m "$MODEL_UUID" "$APP" --format=json | jq -r --arg app "$APP" '.applications[$app].units | keys[]'); do
        juju exec -m "$MODEL_UUID" -u "$unit" -- sudo apt-get update
        juju exec -m "$MODEL_UUID" -u "$unit" -- sudo DEBIAN_FRONTEND=noninteractive apt-get install -y $PACKAGES
      done
    EOT
  }
}