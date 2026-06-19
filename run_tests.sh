#!/usr/bin/env bash

set -Eeuo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

"${script_dir}"/tests/harness.sh --test "${script_dir}"/tests/default_options.sh --expected "${script_dir}"/tests/default_options_expected.txt "$@"
"${script_dir}"/tests/harness.sh --test "${script_dir}"/tests/window_status_styling.sh --expected "${script_dir}"/tests/window_status_styling_expected.txt "$@"
"${script_dir}"/tests/harness.sh --test "${script_dir}"/tests/naked_style.sh --expected "${script_dir}"/tests/naked_style_expected.txt "$@"
"${script_dir}"/tests/harness.sh --test "${script_dir}"/tests/windows_line.sh --expected "${script_dir}"/tests/windows_line_expected.txt "$@"
"${script_dir}"/tests/harness.sh --test "${script_dir}"/tests/unstyled.sh --expected "${script_dir}"/tests/unstyled_expected.txt "$@"
"${script_dir}"/tests/harness.sh --test "${script_dir}"/tests/all_cascade.sh --expected "${script_dir}"/tests/all_cascade_expected.txt "$@"

"${script_dir}"/tests/harness.sh --test "${script_dir}"/tests/application_module.sh --expected "${script_dir}"/tests/application_module_expected.txt "$@"
"${script_dir}"/tests/harness.sh --test "${script_dir}"/tests/battery_module.sh --expected "${script_dir}"/tests/battery_module_expected.txt "$@"
"${script_dir}"/tests/harness.sh --test "${script_dir}"/tests/cpu_module.sh --expected "${script_dir}"/tests/cpu_module_expected.txt "$@"
"${script_dir}"/tests/harness.sh --test "${script_dir}"/tests/load_module.sh --expected "${script_dir}"/tests/load_module_expected.txt "$@"
"${script_dir}"/tests/harness.sh --test "${script_dir}"/tests/pane_styling.sh --expected "${script_dir}"/tests/pane_styling_expected.txt "$@"
"${script_dir}"/tests/harness.sh --test "${script_dir}"/tests/panes_variant.sh --expected "${script_dir}"/tests/panes_variant_expected.txt "$@"
"${script_dir}"/tests/harness.sh --test "${script_dir}"/tests/ram_module.sh --expected "${script_dir}"/tests/ram_module_expected.txt "$@"
"${script_dir}"/tests/harness.sh --test "${script_dir}"/tests/module_highlight.sh --expected "${script_dir}"/tests/module_highlight_expected.txt "$@"
