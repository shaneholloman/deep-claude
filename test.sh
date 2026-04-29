#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

bash -n bin/deep-claude
bash -n deep-claude
bash -n install.sh

default_output="$(CLAUDE_BIN=/bin/echo ./bin/deep-claude)"
flash_output="$(CLAUDE_BIN=/bin/echo ./bin/deep-claude --model flash hello)"
pro_output="$(CLAUDE_BIN=/bin/echo ./bin/deep-claude --model pro hello)"
passthrough_output="$(CLAUDE_BIN=/bin/echo ./bin/deep-claude -p "hello there" --output-format json)"
separator_output="$(CLAUDE_BIN=/bin/echo ./bin/deep-claude --model flash -- -p "hello from flash")"

[[ "$default_output" == "--model deepseek-v4-pro" ]]
[[ "$flash_output" == "--model deepseek-v4-flash hello" ]]
[[ "$pro_output" == "--model deepseek-v4-pro hello" ]]
[[ "$passthrough_output" == "--model deepseek-v4-pro -p hello there --output-format json" ]]
[[ "$separator_output" == "--model deepseek-v4-flash -p hello from flash" ]]

echo "ok"
