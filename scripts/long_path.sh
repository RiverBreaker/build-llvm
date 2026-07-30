#!/bin/bash
git config --system core.longpaths true
git config --global core.autocrlf false
pwsh -Command "Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled -Value 1 -Type DWord -Force" || true