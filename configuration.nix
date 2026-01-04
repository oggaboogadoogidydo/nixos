{ config, pkgs, lib, ... }:

{
  # ==========================================================================
  # Import external configurations
  # ==========================================================================
  imports = [ 
    ./hardware-configuration.nix 
  ];

  # ==========================================================================
  # Boot Configuration
  # ==========================================================================
  boot = {
    kernelPackages = pkgs.linuxPackages_6_18;
    kernelParams = [ 
      "page_alloc.shuffle=1"  # Security: Randomizes page allocator for ASLR
      "usbcore.autosuspend=-1" # Theoretically fix usb devices turning off when connected during boot. 
    ];
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };
    initrd.luks.devices."luks-95192317-faaa-4d77-96ac-7246f4a939f0".device = "/dev/disk/by-uuid/95192317-faaa-4d77-96ac-7246f4a939f0";
  };

  # ==========================================================================
  # Memory Management & Performance
  # ==========================================================================
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # ==========================================================================
  # Systemd Configuration
  # ==========================================================================
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "10s";
  };

  # ==========================================================================
  # Networking Configuration
  # ==========================================================================
  networking = {
    hostName = "deckard";
    networkmanager.enable = true;
    firewall = {
      enable = true;
    };
  };

  # ==========================================================================
  # Localization & Internationalization
  # ==========================================================================
  time.timeZone = "America/Chicago";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
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
  };

  # ==========================================================================
  # X11 Configuration (Required for some applications)
  # ==========================================================================
  services.xserver = {
    enable = true;  # Required for VirtualBox and some other applications
    videoDrivers = ["nvidia"];  # Required for NVIDIA GPU
    xkb = {
      layout = "us";
      variant = "";
    };
    displayManager.lightdm.enable = false;
  };

  # ==========================================================================
  # System Configuration
  # ==========================================================================
  system = {
    stateVersion = "24.05";
    autoUpgrade = {
      enable = true;
    };
  };

  # ==========================================================================
  # Nix Package Manager Configuration
  # ==========================================================================
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      persistent = true;
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
  };
  
  nixpkgs.config.allowUnfree = true;

  # ==========================================================================
  # User Configuration
  # ==========================================================================
  users.users.bobw = {
    isNormalUser = true;
    description = "BobW";
    extraGroups = [ "networkmanager" "wheel" "vboxusers" "dialout" "input" "fileshare" ];
  };

  users.groups = { 
    fileshare = {};
    n8n = {};
  };

  users.users.n8n = {
    isSystemUser = true;
    group = "fileshare";
    extraGroups = [ "n8n" "fileshare" ];
  };
  # ==========================================================================
  # Filesystem Configuration
  # ==========================================================================
  fileSystems."/".options = [ 
    "defaults" 
    # "acl"
    "noatime"
  ];

  # ==========================================================================
  # Security Configuration
  # ==========================================================================
  security = {
    rtkit.enable = true;
    unprivilegedUsernsClone = true;
  };

  # ==========================================================================
  # Power Management
  # ==========================================================================
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };
  
  # ==========================================================================
  # Hardware Services
  # ==========================================================================
  
    # ASUS ROG control services
  services.asusd = {
      enable = true;
      enableUserService = true;
    };
  services.supergfxd.enable = true;

    # Advanced power management
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
        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };

    # SSH server
  services.openssh = {
      enable = true;
      startWhenNeeded = true;
      settings = {
        X11Forwarding = true;
        X11UseLocalhost = false;
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Bluetooth
  services.blueman.enable = true;
  
  # AI Local
  services.ollama = { 
      enable = true;
      acceleration = "cuda";
    };

    # D-Bus message bus
  services.dbus.implementation = "dbus";

  # Espanso
  services.espanso = {
      package = pkgs.espanso-wayland;
      enable = true;
  };

  # ==========================================================================
  # Hardware Configuration
  # ==========================================================================
  hardware = {
    graphics.enable = true;
    enableAllFirmware = true;
    
    # NVIDIA GPU configuration
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        amdgpuBusId = "PCI:9:0:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
    
    # Bluetooth
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    
  };

  # ==========================================================================
  # Virtualization - FIXED VirtualBox Configuration
  # ==========================================================================
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;  # Enable extension pack for USB 2.0/3.0 support
    # KVM support - when using KVM, must use standard NAT networking
    enableKvm = true;
    # CRITICAL FIX: Disable additional network interfaces when using KVM
    # With KVM, VirtualBox only supports standard NAT networking
    addNetworkInterface = false;
  };

  # ==========================================================================
  # Program Configuration (user-facing programs, not services)
  # ==========================================================================
  programs = {
    # Steam gaming platform
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = false;
      localNetworkGameTransfers.openFirewall = true;
    };

    # ASUS ROG Control Center
    rog-control-center = {
      enable = true;
      autoStart = true;
    };
    
    # Hyprland Wayland compositor
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Bash configuration
    bash = {
      enableLsColors = true;  # Enable colors for ls
      undistractMe.enable = true;
      undistractMe.timeout = 60;
      undistractMe.playSound = true;
    };

    # Yazi Terminal File Manager
    yazi = {
      enable = true;
      settings = {
        yazi = {
          ratio = [
            1
            4
            3
          ];
          sort_by = "natural";
          sort_sensitive = true;
          sort_reverse = false;
          sort_dir_first = true;
          linemode = "size";
          show_hidden = true;
          show_symlink = true;

        preview = {
          wrap = "yes";
          image_filter = "lanczos3";
          image_quality = 90;
          tab_size = 1;
          max_width = 600;
          max_height = 900;
          cache_dir = "";
          ueberzug_scale = 1;
          ueberzug_offset = [
            0
            0
            0
            0
          ];
        };

        tasks = {
          micro_workers = 5;
          macro_workers = 10;
          bizarre_retry = 5;
        };
      };
      theme = {};
      keymap = {};
      };
    };
  };

  # ==========================================================================
  # XDG Desktop Portal
  # ==========================================================================
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [ 
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };

  # ==========================================================================
  # Audio Configuration
  # ==========================================================================
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
  };

  # ==========================================================================
  # Environment & Shell Configuration
  # ==========================================================================
  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";  # Hint Electron apps to use Wayland
      EDITOR = "vim";
      # NVIDIA variables for better compatibility
      __GL_GSYNC_ALLOWED = "1";
      __GL_VRR_ALLOWED = "1";
      # Hint SDL2 to use Wayland
      SDL_VIDEODRIVER = "wayland";
      # Firefox Wayland
      MOZ_ENABLE_WAYLAND = "1";
    };
    
    shellAliases = {
      eza = "eza --sort=Name --group-directories-first -1 --long --smart-group --header --time=modified --time-style=full-iso --total-size --git --classify=always --dereference --color=auto --icons=auto --tree --level=2";
      rebuild = "cd /etc/nixos/ && sudo git add * && sudo nixos-rebuild switch && sudo git commit && sudo git push";
      startWM = "nvidia-offload uwsm start hyprland.desktop";
    };

    # ==========================================================================
    # System Packages
    # ==========================================================================
    systemPackages = with pkgs; let
      unstable = import <unstable> { config.allowUnfree = true; };
    in [
      # === System Utilities ===
        asusctl 
        supergfxctl
        pipewire 
        easyeffects
        acl
        git 
        wget 
        eza 
        gh
        p7zip 
        usbtop
        docker 
        nvidia-container-toolkit
        zenith-nvidia
        brightnessctl
        clock-rs
        kdotool
        kdePackages.wayland-protocols

      # === Development Environments ===
        python3 
        rustup 
        cargo-generate 
        gcc_multi
        jdk11 
        jdk17
      
      # === Custom Vim Configuration ===
      (vim-full.customize {
        name = "vim";
        vimrcConfig = {
          customRC = ''
            set tabstop=8 softtabstop=0
            set shiftwidth=4 smarttab
            set expandtab
            set number
            set cursorline
            set cursorcolumn
            set scrolloff=10
            set incsearch
            set smartcase
            set wildmenu
            
            syntax on
            
            let g:auto_save = 1
            let g:auto_save_no_updatetime = 1
            let g:auto_save_in_insert_mode = 1
            
            set statusline= 
            set statusline+=\ %F\ %M\ %Y\ %R
            set statusline+=%=
            set statusline+=\ ascii:\ %b\ hex:\ 0x%B\ row:\ %l\ col:\ %c\ percent:\ %p%%
            set laststatus=2
              '';
            packages.myplugins = with vimPlugins; {
              start = [ 
              vim-nix vim-markdown rust-vim syntastic 
              YouCompleteMe vim-polyglot ale vim-auto-save 
            ];
          };
        };
      })

      # === Wayland & Graphics ===
        xwayland 
        wayland-protocols 
        wayland-utils
        wl-clipboard
        unstable.anyrun 
        uwsm

      # === Applications ===
        firefox 
        floorp-bin
        libreoffice-qt-fresh 
        alacritty
        ani-cli 
        ytmdl 
        numbat
      
      # === Games ===
        unstable.prismlauncher
        bastet 
        ninvaders
        dwarf-fortress-packages.dwarf-fortress-full
        shadps4

      # === Productivity & Creative ===
        unstable.ferdium
        kicad
        unstable.ollama-cuda 
#        unstable.n8n
        blender 
        freecad
        sweethome3d.application
        thonny 
        unstable.arduino-ide
        unstable.cura-appimage
        meerk40t 

      # === Hardware Drivers ===
        unstable.spacenavd 
        unstable.spacenav-cube-example
        unstable.spnavcfg 
        unstable.libspnav
        libimobiledevice
    ];
  };

  nixpkgs.overlays = [
    (final: prev: {
      # Your package overrides go here
      freecad = prev.freecad.overrideAttrs (oldAttrs: {
        # The wrapProgram command is provided by makeWrapper
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ final.makeWrapper ];
        # Create a wrapper script that sets the environment variable before launching FreeCAD
        postInstall = (oldAttrs.postInstall or "") + ''
          wrapProgram "$out/bin/FreeCAD" --set QT_QPA_PLATFORM xcb
        '';
      });
    })
  ];

  # ==========================================================================
  # Insecure Package Exceptions
  # ==========================================================================
  nixpkgs.config.permittedInsecurePackages = [
    "python3.11-youtube-dl-2021.12.17"
    "electron-27.3.11"
  ];
}
