{
  stdenv,
  buildFHSEnv,
  requireFile,
  lib,
  zlib,
  gdbm,
  libxslt,
  libxml2,
  libuuid,
  readline,
  readline70,
  xz,
  cups,
  libaio,
  vulkan-loader,
  alsa-lib,
  libpulseaudio,
  libxcrypt-legacy,
  libGL,
  numactl,
  xorg,
  kmod,
  python3,
  autoPatchelfHook,
  makeWrapper,
  symlinkJoin,
  enableInstaller ? false,
  bzip2,
  sqlite,
  enableMacOSGuests ? false,
  fetchFromGitHub,
  unzip,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "vmware-workstation";
  version = "17.6.4";
  build = "24832109";

  src = requireFile {
    name = "VMware-Workstation-Full-${finalAttrs.version}-${finalAttrs.build}.x86_64.bundle";
    url = "https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true";
    hash = "sha256-ZPv7rqzEiGVGgRQ2Kiu6rekRDMnoe8O9k4OWun8Zqb0=";
  };

  vmware-unpack-env = buildFHSEnv {
    pname = "vmware-unpack-env";
    inherit (finalAttrs) version;
    targetPkgs = pkgs: [ zlib ];
  };

  unpackPhase = ''
    ${finalAttrs.vmware-unpack-env}/bin/vmware-unpack-env -c "sh ${finalAttrs.src} --extract unpacked"
  '';

  macOSUnlockerSrc = fetchFromGitHub {
    owner = "paolo-projects";
    repo = "unlocker";
    tag = "3.0.5";
    hash = "sha256-JSEW1gqQuLGRkathlwZU/TnG6dL/xWKW4//SfE+kO0A=";
  };

  postPatch = lib.optionalString enableMacOSGuests ''
    cp -R "${finalAttrs.macOSUnlockerSrc}" unlocker/

    substituteInPlace unlocker/unlocker.py --replace \
      "/usr/lib/vmware/bin/" "$out/lib/vmware/bin"

    substituteInPlace unlocker/unlocker.py --replace \
      "/usr/lib/vmware/lib/libvmwarebase.so/libvmwarebase.so" "$out/lib/vmware/lib/libvmwarebase.so/libvmwarebase.so"
  '';

  readline70_compat63 = symlinkJoin {
    name = "readline70_compat63";
    paths = [ readline70 ];
    postBuild = ''
      ln -s $out/lib/libreadline.so $out/lib/libreadline.so.6
    '';
  };

  nativeBuildInputs = [
    python3
    finalAttrs.vmware-unpack-env
    autoPatchelfHook
    makeWrapper
  ]
  ++ lib.optionals enableInstaller [
    bzip2
    sqlite
    finalAttrs.readline70_compat63
  ]
  ++ lib.optionals enableMacOSGuests [ unzip ];

  buildInputs = [
    libxslt
    libxml2
    libuuid
    gdbm
    readline
    xz
    cups
    libaio
    vulkan-loader
    alsa-lib
    libpulseaudio
    libxcrypt-legacy
    libGL
    numactl
    xorg.libX11
    xorg.libXau
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXdmcp
    xorg.libXext
    xorg.libXfixes
    xorg.libXft
    xorg.libXinerama
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXScrnSaver
    xorg.libXtst
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p \
      $out/bin \
      $out/etc/vmware \
      $out/etc/init.d \
      $out/lib/vmware \
      $out/share/doc

    #### Replicate vmware-installer's order but VMX first because of appLoader
    ${lib.optionalString enableInstaller ''
      ## VMware installer
      echo "Installing VMware Installer"
      unpacked="unpacked/vmware-installer"
      vmware_installer_version=$(cat "unpacked/vmware-installer/manifest.xml" | grep -oPm1 "(?<=<version>)[^<]+")
      dest="$out/lib/vmware-installer/$vmware_installer_version"

      mkdir -p $dest
      cp -r $unpacked/vmis* $dest/
      cp -r $unpacked/sopython $dest/
      cp -r $unpacked/python $dest/
      cp -r $unpacked/cdsHelper $dest/
      cp -r $unpacked/vmware* $dest/
      cp -r $unpacked/bin $dest/
      cp -r $unpacked/lib $dest/

      chmod +x $dest/vmis-launcher $dest/sopython/* $dest/python/init.sh $dest/vmware-*
      ln -s $dest/vmware-installer $out/bin/vmware-installer

      mkdir -p $out/etc/vmware-installer
      cp ${./vmware-installer-bootstrap} $out/etc/vmware-installer/bootstrap
      sed -i -e "s,@@INSTALLERDIR@@,$dest," $out/etc/vmware-installer/bootstrap
      sed -i -e "s,@@IVERSION@@,$vmware_installer_version," $out/etc/vmware-installer/bootstrap
      sed -i -e "s,@@BUILD@@,${finalAttrs.build}," $out/etc/vmware-installer/bootstrap

      # create database of vmware guest tools (avoids vmware fetching them later)
      mkdir -p $out/etc/vmware-installer/components
      database_filename=$out/etc/vmware-installer/database
      touch $database_filename
      sqlite3 "$database_filename" "CREATE TABLE settings(key VARCHAR PRIMARY KEY, value VARCHAR NOT NULL, component_name VARCHAR NOT NULL);"
      sqlite3 "$database_filename" "INSERT INTO settings(key,value,component_name) VALUES('db.schemaVersion','2','vmware-installer');"
      sqlite3 "$database_filename" "CREATE TABLE components(id INTEGER PRIMARY KEY, name VARCHAR NOT NULL, version VARCHAR NOT NULL, buildNumber INTEGER NOT NULL, component_core_id INTEGER NOT NULL, longName VARCHAR NOT NULL, description VARCHAR, type INTEGER NOT NULL);"
      for folder in unpacked/**/.installer ; do
        component="$(basename $(dirname $folder))"
        component_version=$(cat unpacked/$component/manifest.xml | grep -oPm1 "(?<=<version>)[^<]+")
        component_core_id=$([ "$component" == "vmware-installer" ] && echo "-1" || echo "1")
        type=$([ "$component" == "vmware-workstation" ] && echo "0" || echo "1")
        sqlite3 "$database_filename" "INSERT INTO components(name,version,buildNumber,component_core_id,longName,description,type) VALUES('$component','$component_version',${finalAttrs.build},$component_core_id,'$component','$component',$type);"
        mkdir -p $out/etc/vmware-installer/components/$component
        cp -r $folder/* $out/etc/vmware-installer/components/$component
      done
    ''}

    ## VMware Bootstrap
    echo "Installing VMware Bootstrap"
    cp ${./vmware-bootstrap} $out/etc/vmware/bootstrap
    sed -i -e "s,@@PREFIXDIR@@,$out," $out/etc/vmware/bootstrap

    ## VMware Config
    echo "Installing VMware Config"
    cp ${./vmware-config} $out/etc/vmware/config
    sed -i -e "s,@@VERSION@@,${finalAttrs.version}," $out/etc/vmware/config
    sed -i -e "s,@@BUILD@@,${finalAttrs.build}," $out/etc/vmware/config
    sed -i -e "s,@@PREFIXDIR@@,$out," $out/etc/vmware/config

    ## VMware VMX
    echo "Installing VMware VMX"
    unpacked="unpacked/vmware-vmx"
    cp -r $unpacked/bin/* $out/bin/
    cp -r $unpacked/etc/modprobe.d $out/etc/
    cp -r $unpacked/etc/init.d/* $out/etc/init.d/
    cp -r $unpacked/roms $out/lib/vmware/
    cp -r $unpacked/sbin/* $out/bin/

    cp -r $unpacked/lib/libconf $out/lib/vmware/
    rm $out/lib/vmware/libconf/etc/fonts/fonts.conf

    cp -r $unpacked/lib/bin $out/lib/vmware/
    cp -r $unpacked/lib/lib $out/lib/vmware/
    cp -r $unpacked/lib/scripts $out/lib/vmware/
    cp -r $unpacked/lib/icu $out/lib/vmware/
    cp -r $unpacked/lib/share $out/lib/vmware/
    cp -r $unpacked/lib/modules $out/lib/vmware/
    cp -r $unpacked/lib/include $out/lib/vmware/

    cp -r $unpacked/extra/checkvm $out/bin/
    cp -r $unpacked/extra/modules.xml $out/lib/vmware/modules/

    ln -s $out/lib/vmware/bin/appLoader $out/lib/vmware/bin/vmware-vmblock-fuse
    ln -s $out/lib/vmware/icu $out/etc/vmware/icu

    # Replace vmware-modconfig with simple error dialog
    cp ${./vmware-modconfig} $out/bin/vmware-modconfig
    sed -i -e "s,ETCDIR=/etc/vmware,ETCDIR=$out/etc/vmware," $out/bin/vmware-modconfig

    # Patch dynamic libs in
    for binary in "mksSandbox" "mksSandbox-debug" "mksSandbox-stats" "vmware-vmx" "vmware-vmx-debug" "vmware-vmx-stats"
    do
      patchelf \
        --add-needed ${libaio}/lib/libaio.so.1 \
        --add-needed ${vulkan-loader}/lib/libvulkan.so.1 \
        --add-needed ${alsa-lib}/lib/libasound.so \
        --add-needed ${libpulseaudio}/lib/libpulse.so.0 \
        --add-needed ${libGL}/lib/libEGL.so.1 \
        --add-needed ${numactl}/lib/libnuma.so.1 \
        --add-needed ${xorg.libX11}/lib/libX11.so.6 \
        --add-needed ${xorg.libXi}/lib/libXi.so.6 \
        --add-needed ${libGL}/lib/libGL.so.1 \
        $out/lib/vmware/bin/$binary
    done

    ## VMware USB Arbitrator
    echo "Installing VMware USB Arbitrator"
    unpacked="unpacked/vmware-usbarbitrator"
    cp -r $unpacked/etc/init.d/* $out/etc/init.d/
    cp -r $unpacked/bin/* $out/bin/
    ln -s $out/lib/vmware/bin/appLoader $out/lib/vmware/bin/vmware-usbarbitrator

    ## VMware Player Setup
    echo "Installing VMware Player Setup"
    unpacked="unpacked/vmware-player-setup"
    mkdir -p $out/lib/vmware/setup
    cp $unpacked/vmware-config $out/lib/vmware/setup/

    ## VMware Network Editor
    echo "Installing VMware Network Editor"
    unpacked="unpacked/vmware-network-editor"
    cp -r $unpacked/lib $out/lib/vmware/

    ## VMware Player Application
    echo "Installing VMware Player Application"
    unpacked="unpacked/vmware-player-app"
    cp -r $unpacked/lib/* $out/lib/vmware/
    cp -r $unpacked/share/* $out/share/
    cp -r $unpacked/bin/* $out/bin/
    cp -r $unpacked/doc/* $out/share/doc/ # Licences

    for target in "vmplayer" "vmware-enter-serial" "vmware-setup-helper" "licenseTool" "vmware-mount" "vmware-fuseUI" "vmware-app-control" "vmware-zenity"
    do
      ln -s $out/lib/vmware/bin/appLoader $out/lib/vmware/bin/$target
    done

    ln -s $out/lib/vmware/bin/vmware-mount $out/bin/vmware-mount
    ln -s $out/lib/vmware/bin/vmware-fuseUI $out/bin/vmware-fuseUI
    ln -s $out/lib/vmware/bin/vmrest $out/bin/vmrest

    # Patch vmplayer
    sed -i -e "s,ETCDIR=/etc/vmware,ETCDIR=$out/etc/vmware," $out/bin/vmplayer
    sed -i -e "s,/sbin/modprobe,${kmod}/bin/modprobe," $out/bin/vmplayer
    sed -i -e "s,@@BINARY@@,$out/bin/vmplayer," $out/share/applications/vmware-player.desktop

    ## VMware OVF Tool component
    echo "Installing VMware OVF Tool for Linux"
    unpacked="unpacked/vmware-ovftool"
    mkdir -p $out/lib/vmware-ovftool/

    cp -r $unpacked/* $out/lib/vmware-ovftool/
    chmod 755 $out/lib/vmware-ovftool/ovftool*
    makeWrapper "$out/lib/vmware-ovftool/ovftool.bin" "$out/bin/ovftool"

    ## VMware Network Editor User Interface
    echo "Installing VMware Network Editor User Interface"
    unpacked="unpacked/vmware-network-editor-ui"
    cp -r $unpacked/share/* $out/share/

    ln -s $out/lib/vmware/bin/appLoader $out/lib/vmware/bin/vmware-netcfg
    ln -s $out/lib/vmware/bin/vmware-netcfg $out/bin/vmware-netcfg

    # Patch network editor ui

    sed -i -e "s,@@BINARY@@,$out/bin/vmware-netcfg," $out/share/applications/vmware-netcfg.desktop

    ## VMware VIX Core Library
    echo "Installing VMware VIX Core Library"
    unpacked="unpacked/vmware-vix-core"
    mkdir -p $out/lib/vmware-vix
    cp -r $unpacked/lib/* $out/lib/vmware-vix/
    cp -r $unpacked/bin/* $out/bin/
    cp $unpacked/*.txt $out/lib/vmware-vix/

    mkdir -p $out/share/doc/vmware-vix/
    cp -r $unpacked/doc/* $out/share/doc/vmware-vix/

    mkdir -p $out/include/
    cp -r $unpacked/include/* $out/include/

    ## VMware VIX Workstation-17.0.0 Library
    echo "Installing VMware VIX Workstation-17.0.0 Library"
    unpacked="unpacked/vmware-vix-lib-Workstation1700"
    cp -r $unpacked/lib/* $out/lib/vmware-vix/

    ## VMware VProbes component for Linux
    echo "Installing VMware VProbes component for Linux"
    unpacked="unpacked/vmware-vprobe"
    cp -r $unpacked/bin/* $out/bin/
    cp -r $unpacked/lib/* $out/lib/vmware/

    ## VMware Workstation
    echo "Installing VMware Workstation"
    unpacked="unpacked/vmware-workstation"
    cp -r $unpacked/bin/* $out/bin/
    cp -r $unpacked/lib/* $out/lib/vmware/
    cp -r $unpacked/share/* $out/share/
    cp -r $unpacked/man $out/share/
    cp -r $unpacked/doc $out/share/

    ln -s $out/lib/vmware/bin/appLoader $out/lib/vmware/bin/vmware
    ln -s $out/lib/vmware/bin/appLoader $out/lib/vmware/bin/vmware-tray
    ln -s $out/lib/vmware/bin/appLoader $out/lib/vmware/bin/vmware-vprobe

    # Patch vmware
    sed -i -e "s,ETCDIR=/etc/vmware,ETCDIR=$out/etc/vmware,g" $out/bin/vmware
    sed -i -e "s,/sbin/modprobe,${kmod}/bin/modprobe,g" $out/bin/vmware
    sed -i -e "s,@@BINARY@@,$out/bin/vmware," $out/share/applications/vmware-workstation.desktop

    chmod +x $out/bin/* $out/lib/vmware/bin/* $out/lib/vmware/setup/*

    # Hardcoded pkexec hack
    for lib in "lib/vmware/lib/libvmware-mount.so/libvmware-mount.so" "lib/vmware/lib/libvmwareui.so/libvmwareui.so" "lib/vmware/lib/libvmware-fuseUI.so/libvmware-fuseUI.so"
    do
      sed -i -e "s,/usr/local/sbin,/run/vmware/bin," "$out/$lib"
    done

    ${lib.optionalString enableMacOSGuests ''
      echo "Running VMWare Unlocker to enable macOS Guests"
      python3 unlocker/unlocker.py
    ''}

    # SUID hack
    wrapProgram $out/lib/vmware/bin/vmware-vmx
    rm $out/lib/vmware/bin/vmware-vmx
    ln -s /run/wrappers/bin/vmware-vmx $out/lib/vmware/bin/vmware-vmx

    # Remove shipped X11 libraries
    for lib in $out/lib/vmware/lib/* $out/lib/vmware-ovftool/lib*.so*; do
      lib_name="$(basename "$lib")"
      if [[ "$lib_name" == libX* || "$lib_name" == libxcb* ]]; then
        rm -rf "$lib"
      fi
    done

    runHook postInstall
  '';

  meta = {
    description = "Industry standard desktop hypervisor for x86-64 architecture";
    homepage = "https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "vmware";
    maintainers = with lib.maintainers; [
      cawilliamson
      deinferno
      vifino
    ];
  };
})
