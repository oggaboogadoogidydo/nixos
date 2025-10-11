# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the config from hardware prior
      #  <hardware-g713pi/asus/rog-strix/g713pi>
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Kernel Choice
  boot.kernelPackages = pkgs.linuxPackages_6_16;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-95192317-faaa-4d77-96ac-7246f4a939f0".device = "/dev/disk/by-uuid/95192317-faaa-4d77-96ac-7246f4a939f0";

  # Enable ACL in filesystems
  fileSystems."/".options = [ "defaults" "acl" ];

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
    extraGroups = [ "networkmanager" "wheel" "vboxusers" "dialout" "input" "fileshare"  ];
    packages = with pkgs; [];
  };

  # Allow for system auto upgrade
  system.autoUpgrade.enable = true;
  # Allow for system to self clean
  nix.gc = {
    automatic = true;
    dates = "weekly";
    persistent = true;
    };
  nix.settings.auto-optimise-store = true;

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

    # Load nvidia driver for Xorg and Wayland
    services.xserver.videoDrivers = ["nvidia"];

    hardware.graphics.enable = true;
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
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  hardware.nvidia.prime = {
    offload.enable = true;

    offload.enableOffloadCmd = true;
    
    amdgpuBusId = "PCI:9:0:0";
    nvidiaBusId = "PCI:1:0:0";
  };


  # boot.kernelParams = [ "module_blacklist=amdgpu" ];

  #specialisation = {
  #  on-the-go.configuration = {
  #    system.nixos.tags = [ "on-the-go" ];
  #    hardware.nvidia = {
  #      prime.offload.enable = lib.mkForce true;
  #      prime.offload.enableOffloadCmd = lib.mkForce true;
  #      prime.sync.enable = lib.mkForce false;
  #    };
  #  };
  #};

  # Hyprland config
  programs.hyprland = {
    enable = true;
    withUWSM = true;
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
      pkgs.xdg-desktop-portal-hyprland
    ];
  };

  # Auto start hyprland on login
  environment.loginShellInit = ''
    if [ "$(tty)" = "/dev/tty1" ]; then
      exec nvidia-offload uwsm start hyprland-uwsm.desktop
    fi
  '';
  
  # Sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;  # Listed as does not exist
    pulse.enable = true;
    jack.enable = true;
  };
  programs.bash.undistractMe.playSound = true;

  hardware.enableAllFirmware = true;
 
  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    settings = {
                 X11Forwarding = true;
                 X11UseLocalhost = false;
               };
    };
  
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
  virtualisation.virtualbox.host = {
    enable = true;
    enableKvm = true;
    addNetworkInterface = false;
    enableHardening = true;
  };
  users.extraGroups.vboxusers.members = [ "bobw" ];
    
  # Text Expander Utility : Espanso
  services.espanso.enable = true;

  # n8n
  # n8n user and group
  users.users.n8n = {
    isSystemUser = true;
    group = "n8n";
    home = "/var/lib/n8n";
    createHome = true;
    homeMode = "755";
    extraGroups = [ "fileshare" ];
  };
  users.groups.n8n = {};

  # Shared access group
  users.groups.fileshare = {};

  # Set premissions for n8n directory
  system.activationScripts.n8n-setup = ''
    mkdir -p /var/lib/n8n/{data,workflows,.n8n}
    chown -R n8n:n8n /var/lib/n8n
    chmod -R 755 /var/lib/n8n
  '';

  # Set shared file premissions 
  systemd.tmpfiles.rules = [
    # n8n service directories
    "d /var/lib/n8n 0755 n8n n8n - -"
    "d /var/lib/n8n/data 0755 n8n n8n - -"
    "d /var/lib/n8n/workflows 0755 n8n n8n - -"
    "d /var/lib/n8n/.n8n 0755 n8n n8n - -"

    # Set premissions for existing directories
    "a+ /home/bobw/Documents/Archive - - - - d:g:fileshare:rwx"
    "a+ /home/bobw/Documents/Notes - - - - d:g:fileshare:rwx"

    "a+ /home/bobw/Downloads - - - - d:f:fileshare:rwx"

  ];

  # Enable the service
  services.n8n = {
    enable = true;
    openFirewall = true;
    webhookUrl = "http://localhost:5678";
    settings = {N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true;};
  };

  # ollama
  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  environment.variables = { EDITOR = "vim"; };

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
    # mpvpaper # For wallpapers
    hyprpaper # For Static wallpapers
    xwayland
    wayland-protocols
    wayland-utils
    wl-clipboard # Clipboard
    wofi # App Launcher
    hyprlock # Lock manager
    uwsm # auto launcher via systemd
    # egl-wayland
    wl-kbptr

  # Sound
    pavucontrol # GUI Sound control
    pipewire # Sound application

  # Browsers
    firefox
    floorp

  # Office Suite
    libreoffice-qt-fresh # Office Suite
    unstable.dropbox # Dropbox Client - Unsure if works
    ((vim_configurable.override {  }).customize{
      name = "vim";
      # Install plugins for example for syntax highlighting of nix files
      vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
        start = [ vim-nix
                  vim-markdown
                  rust-vim
                  syntastic
                  YouCompleteMe
                  vim-polyglot
                  ale
                 ];
        opt = [];
      };
      vimrcConfig.customRC = ''
        set tabstop=8 softtabstop=0
        set shiftwidth=4 smarttab
      	set expandtab

      	syntax on
      '';
      }
    )
    sage
    
    
  # Utilities
    git # Git
    alacritty # Terminal
    wget # Download from internet source
    eza # Better ls
    run
    gh # Github cli
    ani-cli # Watch Anime from cli
    ytmdl # Download music with all attached metadata
    numbat # Very helpful math solver
    p7zip # Zip tool
    usbtop # Monitor for USB devices
    docker # Run docker containers
    nvidia-container-toolkit # pass docker containers the gpu
    zenith-nvidia # startup show all computer processes
    sniffnet # utility to veiw network usage
    espanso-wayland #text expander utility

  # Drivers
    unstable.spacenavd # Device Driver
    unstable.spacenav-cube-example # Cube Test
    unstable.spnavcfg # GUI Config for Space Nav
    unstable.libspnav # Device Driver

  # Languages
    python3 # Python
    rustup # Rust toolchain
    cargo-generate
    jdk11 # java ll
    jdk17 # Java 17
    gcc_multi # C compiler collection for several languages
    
  # Games
    steam # Steam
    unstable.modrinth-app # Minecraft modpack client
    bastet
    ninvaders
    dwarf-fortress-packages.dwarf-fortress-full # Dwarf fortress - terminal edition
    shadps4 # PS4 emulator

  # Apps
    unstable.ferdium # Messaging app - Out of date, Replace with my own nixpkg
    pidgin # Messaging app, everything except for instagram. Replace ferdium eventually. 
    kicad # PCB Cad design software
    unstable.ollama-cuda # Local AI
    unstable.n8n # AI automation
    blender
    unstable.freecad-wayland # CAD software
    sweethome3d.application # floor plan designer
    thonny # RP IDE
    unstable.arduino-ide # Arduino IDE
    unstable.cura-appimage # 3d Printer Slicer
    via

  # Enable ACL package for advanced file access control
    acl
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "python3.11-youtube-dl-2021.12.17"
    "electron-27.3.11"
  ];

  security.unprivilegedUsernsClone = true;

  # Define Aliases
  environment.shellAliases = {
    eza = "eza --sort=Name --group-directories-first -1 --long --smart-group --header --time=modified --time-style=full-iso --total-size --git --classify=always --dereference --color=auto --icons=auto --tree --level=2";
    rebuild = "cd /etc/nixos/ && sudo git add * && sudo nixos-rebuild switch && sudo git commit && sudo git push";
  };

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
