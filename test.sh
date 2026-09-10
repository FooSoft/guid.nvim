#!/bin/sh
set -eu

cd -- "$(dirname -- "$0")"
exec nvim -n --headless -u NONE -i NONE -c "lua dofile('tests/guid_spec.lua')"
