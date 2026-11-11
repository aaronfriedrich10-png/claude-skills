#!/usr/bin/env bash
# Richtet in WSL-Ubuntu die Werkzeuge für tools/check.sh der BIM Werkbank ein.
set -u
export DEBIAN_FRONTEND=noninteractive
grep PRETTY /etc/os-release
apt-get update -q >/tmp/apt.log 2>&1
apt-get install -y -q build-essential gcc-mingw-w64-x86-64-posix binutils-mingw-w64-x86-64 \
  mingw-w64-x86-64-dev python3 python3-pip python3-venv nodejs npm >>/tmp/apt.log 2>&1
echo "apt-exit=$?"
tail -2 /tmp/apt.log
pip3 install -q --break-system-packages pymupdf==1.26.6 ifcopenshell==0.9.0.post1 pytest >/tmp/pip.log 2>&1
echo "pip-exit=$?"
tail -2 /tmp/pip.log
for t in cc x86_64-w64-mingw32-gcc-posix python3 node; do command -v "$t" || echo "fehlt: $t"; done
node --version
python3 -c 'import fitz, ifcopenshell, _pytest; print("python-module ok", fitz.__doc__.split()[1], ifcopenshell.version)'
