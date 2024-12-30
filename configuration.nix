# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the config from hardware prior
      <hardware-g713pi/asus/rog-strix/g713pi>
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-5bdceca8-e2db-4e79-9224-d7d71bba9966".device = "/dev/disk/by-uuid/5bdceca8-e2db-4e79-9224-d7d71bba9966";
  networking.hostName = "deckard"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = ""; # Colemak varrient ad somehow
    # options = "grp:alt_shift_toggle";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.bobw = {
    isNormalUser = true;
    description = "BobW";
    extraGroups = [ "networkmanager" "wheel" "vboxusers" ];
    packages = with pkgs; [];
  };


  # Power Managment
  # Asus Required
  powerManagement.powertop.enable = true;
  powerManagement.enable = true;
  programs.rog-control-center.autoStart = true;
  programs.rog-control-center.enable = true;
  services.supergfxd.enable = true;
  services = {
    asusd = {
      enable = true;
      enableUserService = true;
    };
  };
  # tlp
  services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 20;

       #Optional helps save long term battery health
       START_CHARGE_THRESH_BAT0 = 40; # 40 and bellow it starts to charge
       STOP_CHARGE_THRESH_BAT0 = 80; # 80 and above it stops charging

      };
  };


  # Enable Nvidia GPU
  
    # Enable OpenGL
    hardware.opengl = {
      enable = true;
    };

    # Load nvidia driver for Xorg and Wayland
    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia = {

      # Modesetting is required.
      modesetting.enable = true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      # Enable this if you have graphical corruption issues or application crashes after waking
      # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
      # of just the bare essentials.
      powerManagement.enable = false;

      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = false;

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of 
      # supported GPUs is at: 
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
      # Only available from driver 515.43.04+
      # Currently alpha-quality/buggy, so false is currently the recommended setting.
      open = false;

      # Enable the Nvidia settings menu,
	# accessible via `nvidia-settings`.
      nvidiaSettings = true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      package = config.boot.kernelPackages.nvidiaPackages.production;
    };
  

  # Hyprland config
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Hint Electron apps to use wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  services.dbus.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # Sound
  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;  # Listed as does not exist
    pulse.enable = true;
    jack.enable = true;
  };
  sound.mediaKeys.enable = true;
  programs.bash.undistractMe.playSound = true;

  hardware.enableAllFirmware = true;

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
    localNetworkGameTransfers.openFirewall = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # VirtualBox
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "bobw" ];

  # VMWare
  virtualisation.vmware.host.enable = true;
  

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  # Allow unstable packages
  nixpkgs.config.packageOverrides = pkgs: {
	unstable = import <unstable> {
	  config = config.nixpkgs.config;
	};
  };
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
        
  # Asus
    supergfxctl # Asus control Application
    asusctl # Asus control system

  # Hyprland
    hyprland # Hyprland window manager
    mpvpaper # For wallpapers
    hyprpaper # For Static wallpapers
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    xwayland
    wayland-protocols
    wayland-utils
    wl-clipboard # Clipboard
    wlroots
    wofi # App Launcher
    hyprlock # Lock manager

  # Sound
    pavucontrol # GUI Sound control
    pipewire # Sound application

  # Browsers
    firefox
    tor-browser

  # Office Suite
    libreoffice-qt-fresh # Office Suite
    unstable.dropbox # Dropbox Client - Unsure if works
    glow # CLI MD render
    unstable.skypeforlinux

  # Utilities
    git # Git
    kitty # Terminal
    networkmanagerapplet # GUI for configuring network manager connections
    wget # Download from internet source
    eza # Better ls
    btop # Monitor
    gh # Github cli
    ani-cli # Watch Anime from cli
    ytmdl # Download music with all attached metadata
    rink # Very helpful math solver
    nvtopPackages.nvidia # GPU Monitor
    p7zip # Zip tool
    appimage-run # Runs zen browser until packaged
    usbtop # Monitor for USB devices
    usbutils # Easy USB device plug and play
    docker # Run docker containers
    nvidia-container-toolkit # pass docker containers the gpu
    beets # Music library manager
#   kdePackages.kdeconnect-kde # KDE Connect - Does Not Work

  # Drivers
    unstable.spacenavd # Device Driver
    unstable.spacenav-cube-example # Cube Test
    unstable.spnavcfg # GUI Config for Space Nav
    unstable.libspnav # Device Driver

  # Languages
    python3
    rustc
    jdk11
    jdk17

  # Games
    steam # Steam
    modrinth-app # Minecraft modpack client
    bastet
    ninvaders
    dwarf-fortress-packages.dwarf-fortress-full # Dwarf fortress - terminal edition
    unstable.shadps4 # PS4 emulator

  # Apps
    kuro # Issue with electron version - Out of date, Replace with my own nixpkg
    ferdium # Messaging app - Out of date, Replace with my own nixpkg
    kicad # PCB Cad
    pwsafe # Password database
    logseq # Note Taking Application
    thunderbird # Mail Client
    unstable.ollama-cuda # Local AI
    blender
    unstable.freecad-wayland # CAD software
    openscad 
    sweethome3d.application # floor plan designer
    ytui-music # terminal music player
    thonny # RP IDE
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "electron-27.3.11"
    "electron-29.4.6"
    "python3.11-youtube-dl-2021.12.17"
  ];

  nixpkgs.overlays = [
    (
      final: prev: {
        logseq = prev.logseq.overrideAttrs (oldAttrs: {
          postFixup = ''
            makeWrapper ${prev.electron_27}/bin/electron $out/bin/${oldAttrs.pname} \
              --set "LOCAL_GIT_DIRECTORY" ${prev.git} \
              --add-flags $out/share/${oldAttrs.pname}/resources/app \
              --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
              --prefix LD_LIBRARY_PATH : "${prev.lib.makeLibraryPath [ prev.stdenv.cc.cc.lib ]}"
          '';
        });
      }
    )
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
