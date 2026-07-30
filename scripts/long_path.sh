#!/bin/bash
git config --system core.longpaths true
git config --global core.autocrlf false
pwsh -Command "Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled -Value 1 -Type DWord -Force" || {
    echo "::warning::无法启用长路径支持，不影响编译"
}