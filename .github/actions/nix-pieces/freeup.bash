#!/usr/bin/env bash

printf "Before:\n%s" "$(df -h)"

rm -rf "$HOME/.cargo" &
rm -rf "$HOME/.composer" &
rm -rf "$HOME/.dotnet" &
rm -rf "$HOME/.nvm" &
rm -rf "$HOME/.rustup" &

for d in /opt/* /var/lib/*
do
    # On some hosted runner layouts this backs the runner's Node runtime;
    # deleting it breaks every JavaScript action after this step.
    case "$d" in
        /opt/runner-cache) continue ;;
    esac
    sudo rm -rf "$d" &
done

sudo apt autopurge --yes --autoremove manpages man-db

sudo apt autopurge --yes --autoremove \
    7z\* \
    aardvark-\* \
    adoptium\* \
    adwaita\* \
    ant\* \
    apache2\* \
    apparmor\* \
    apport\* \
    aria2\* \
    auto\* \
    bcache\* \
    bind9\* \
    binutils\* \
    bison\* \
    bolt\* \
    bpf\* \
    brotli\* \
    buildah\* \
    byobu\* \
    catatonit\* \
    clang\* \
    cifs\* \
    command-not\* \
    conmon\* \
    container\* \
    cpp\* \
    crun\* \
    debugedit\* \
    dictionaries\* \
    docker\* \
    emacs\* \
    fakeroot\* \
    finalrd\* \
    firebird\* \
    firefox\* \
    flex\* \
    fontconfig\* \
    fonts\* \
    freetds\* \
    friendly\* \
    ftp\* \
    g++\* \
    gcc \
    gcc-12 \
    gcc-13 \
    gcc-14 \
    gfortran\* \
    gir\* \
    golang\* \
    google\* \
    gtk\* \
    hicolor\* \
    humanity\* \
    hunspell\* \
    ibverbs\* \
    ieee\* \
    imagemagick\* \
    inetutils\* \
    info\* \
    java\* \
    kpartx\* \
    kubectl\* \
    landscape\* \
    linux-azure\* \
    linux-cloud-tools\* \
    linux-headers\* \
    linux-libc-dev\* \
    linux-tools\* \
    lld\* \
    llvm\* \
    lto\* \
    lxd\* \
    mecab\* \
    mercurial\* \
    mesa\* \
    microsoft\* \
    mlock\* \
    modemmanager\* \
    multipath\* \
    mysql\* \
    netavark\* \
    nginx\* \
    overlayroot\* \
    p11\* \
    p7zip\* \
    packagekit\* \
    packages-microsoft\* \
    parallel\* \
    parted\* \
    passt\* \
    patchelf\* \
    php\* \
    pkg-config\* \
    pkgconf\* \
    podman\* \
    pollinate\* \
    postgresql\* \
    powermgmt\* \
    powershell\* \
    psmisc\* \
    rake\* \
    ri\* \
    rpm\* \
    rsync\* \
    ruby\* \
    session-manager-plugin\* \
    sg3\* \
    sgml\* \
    shellcheck\* \
    shtool\* \
    skopeo\* \
    slirp4netns\* \
    snap\* \
    snmp\* \
    sosreport\* \
    sound-theme-freedesktop\* \
    sphinxsearch\* \
    sshpass\* \
    swig\* \
    sysstat\* \
    tcl\* \
    tcpdump\* \
    temurin\* \
    tex\* \
    texinfo\* \
    tk\* \
    tnftp\* \
    ubuntu-mono\* \
    vim\* \
    walinuxagent\* \
    x11\* \
    xauth\* \
    xdg\* \
    xserver\* \
    xul\* \
    xvfb\* \
    zerofree\* \
    zsync\*

for d in /usr/local/*
do
    sudo rm -rf "$d" &
done

sudo rm -rf /usr/share/dotnet &
sudo rm -rf /usr/share/miniconda &
sudo rm -rf /usr/share/swift &
sudo rm -rf /usr/share/az_* &
sudo rm -rf /usr/share/gradle &
sudo rm -rf /usr/share/kotlin* &

wait
