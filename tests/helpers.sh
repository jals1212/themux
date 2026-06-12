#!/usr/bin/env bash

# Returns the value of given tmux option.
# First argument is the option name, e.g. @themux_theme.
#
# Usage: `get_option @themux_theme`
# Would return: `catppuccin_mocha`
#
# The option is given as a format string.
get_option() {
  local option
  option=$1

  tmux display-message -p "#{${option}}"
}

# Prints the given tmux option to stdout.
# First argument is the option name, e.g. @themux_theme.
#
# Usage: `print_option @themux_theme`
# Would print: `@themux_theme mocha`
#
# The option is given as a format string.
print_option() {
  local option
  option=$1

  printf "\n%s " "${option}"
  get_option "$option"
}
