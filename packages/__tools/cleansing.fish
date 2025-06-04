#!/usr/bin/env -S fish -NP

printf "Before cleanup:\n\n%s\n\n%s\n\n" "$(df -h)" "$(free -h)"

# Usage: cleansing.fish <mode>
#
# Since a full blown cleanup takes at least five minutes
# which is too incovenient for frequent or small jobs,
# two modes "light" and "full" are added to address this
# problem.
#
# <mode>:
#
# - light : only remove packages which have processes running
#           to freeup the precious memory
#           There're not too many of them so cleaning don't block
#           CI too long
#
# - full : purge everything not critical to run nix. It' heavy.


if test ( count $argv ) -ne 1
    echo "Expect exact 1 arugment"
    echo "Read this script code for detailed usage"
    exit ( false )
end

set -l CleansingMode "$argv[1]"

if not string match -rq '^(full|light)$' "$CleansingMode"
    echo "Mode \"$CleansingMode\" is wrong"
    echo "Expect \"light\" or \"full\""
    echo "Read this script code for detailed usage"
    exit ( false )
end

if not command -q rmz
    echo "rmz not installed"
    exit ( false )
end

set -l BloatedPackagesWithServices \
    '^dotnet.*' \
    'finalrd' \
    'irqbalance' \
    '^libmono.*' \
    'man-db' \
    'manpages' \
    '^mono.*' \
    'multipath-tools' \
    '^moby.*' \
    '^packagekit.*' \
    '^php.*' \
    'podman' \
    'sphinxsearch' \
    'snapd' \
    'ufw'

set -l BloatedPackages \
    '^.*-icon-theme' \
    'ant' \
    'apache2.*' \
    '^aspnetcore.*' \
    'azure-cli' \
    '^bcache.*' \
    'bolt' \
    'brotli' \
    'build-essential' \
    'buildah' \
    'byobu' \
    '^cpp.*' \
    '^clang.*' \
    'crun' \
    'containerd.io' \
    '^emacsen.*' \
    '^firebird.*' \
    'firefox' \
    '^fonts.*' \
    '^freetds.*' \
    'friendly-recovery' \
    '^gconf.*' \
    '^gfortran.*' \
    '^gir.*' \
    '^glib.*' \
    '^google.*' \
    '^gsettings.*' \
    '^gtk.*' \
    'htop' \
    '^hunspell.*' \
    'icu-devtools' \
    '^imagemagick.*' \
    '^java.*' \
    '^kotlin.*' \
    '^landscape.*' \
    '^libclang.*' \
    '^lld.*' \
    '^llvm.*' \
    '^mecab.*' \
    '^mercurial.*' \
    '^microsoft.*' \
    'motd-news-config' \
    '^msbuild.*' \
    '^mssql.*' \
    '^mysql.*' \
    '^nginx.*' \
    'nuget' \
    'odbcinst' \
    'packages-microsoft-prod' \
    'parallel' \
    'pastebinit' \
    'pollinate' \
    '^postgresql.*' \
    '^r-.*' \
    '^ruby.*' \
    'screen' \
    '^secureboot.*' \
    '^session-.*' \
    'shellcheck' \
    'skopeo' \
    'slirp4netns' \
    'snmp' \
    'subversion' \
    'sosreport' \
    'swig' \
    '^temurin.*' \
    'tmux' \
    'tnftp' \
    '^tex-.*' \
    'texinfo' \
    '^ttf-.*' \
    '^unixodbc.*' \
    '^update-.*' \
    'vim' \
    '^x11.*' \
    'xauth' \
    '^xorg.*' \
    '^upx.*' \
    'xfsprogs' \
    'xorriso' \
    'xtrans-dev' \
    'zerofree' \
    'zsync'

sudo apt purge --yes \
    $BloatedPackages \
    $BloatedPackagesWithServices

sudo apt autopurge --yes &

set -l BloatedPaths \
    '/usr/share/dotnet' \
    '/usr/share/swift' \
    '/usr/share/miniconda' \
    '/usr/share/gradle' \
    '/usr/share/sbt' \
    '/usr/local/' \
    '/opt' \
    '/snap' \
    '/var/snap' \
    '/var/lib/docker' \
    '/var/lib/mysql' \
    '/var/lib/gems' \
    '/etc/skel' \
    '/usr/lib/jvm' \
    '/usr/lib/google-cloud-sdk' \
    '/usr/lib/llvm-'* \
    '/usr/lib/dotnet' \
    '/usr/lib/firefox' \
    "$HOME/.rustup" \
    "$HOME/.cargo" \
    "$HOME/.dotnet"

set -g rmz_path ( command --search rmz )

for path in $BloatedPaths
    sudo "$rmz_path" -f "$path" &
end

wait

printf "After cleanup:\n\n%s\n\n%s\n\n" "$(df -h)" "$(free -h)"
