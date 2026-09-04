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

variable "packages" {
  description = "Map of Juju application names to the apt packages to install on each of their machines."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "juju_cli_setup_command" {
  description = "Command that sets up Juju CLI access to the controller (exports JUJU_DATA and logs in)."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "juju_cli_password" {
  description = "Controller admin password, piped to `juju login` so it does not prompt."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "model_uuid" {
  description = "UUID of the Juju model the applications run in."
  type        = string
  nullable    = false
}