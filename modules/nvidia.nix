{ config, lib, pkgs, ... }:
let 
  cuda = pkgs.cudaPackages_13;
  cudaLibs = with cuda; [
    cudatoolkit
    cudnn
    libcusparse_lt
    # nccl          
  ];
in
{

  config = {

    nixpkgs.config.nvidia.acceptLicense = true;
    nixpkgs.config.cudaSupport = true;
    environment.systemPackages = with pkgs; [
      linuxPackages.nvidia_x11
      nvtopPackages.full
      glibc.bin
    ] ++ cudaLibs;

    # Load nvidia driver for Xorg and Wayland
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware = {
      graphics = {
        enable = true;
      };

      nvidia = {
        # Modesetting is required.
        modesetting.enable = true;
        # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
        # Enable this if you have graphical corruption issues or application crashes after waking
        # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
        # of just the bare essentials.
        powerManagement.enable = true;
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
        nvidiaPersistenced = true;
        # Enable the Nvidia settings menu,
        # accessible via `nvidia-settings`.
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable; # Use 'stable' for modern GPUs.
      };
    };

    environment.variables = {
      CUDA_PATH = "${cuda.cudatoolkit}";
    };

    programs.nix-ld.enable = true; 
    # HACK: torch.compile / triton hardcodes the path '/sbin/ldconfig' to discover
    # CUDA libraries at runtime (see triton/backends/nvidia/driver.py). On NixOS,
    # /sbin/ldconfig either doesn't exist or points to the real glibc ldconfig which
    # tries to read a cache file from the read-only Nix store
    # (/nix/store/.../etc/ld.so.cache), causing it to exit with status 1.
    #
    # The fix: make /sbin/ldconfig a wrapper script that intercepts the specific
    # `ldconfig -p` call triton makes (used to find libcuda.so.1) and returns the
    # correct path manually. All other ldconfig calls are forwarded to the real binary.
    #
    # libcuda.so.1 lives at /run/opengl-driver/lib/ on NixOS — this is the NVIDIA
    # userspace driver library injected by the system at runtime.
    # this is some C stuff that allows Triton to work. Triton searches in /sbin/ldconfig for C libraries. This creates these in there. "This enables nix-ld which sets up a proper FHS-like environment including /sbin/ldconfig automatically, making torch.compile, triton, and any other tool that hardcodes FHS paths work without any per-project workarounds."
    system.activationScripts.ldconfig-compat.text = 
      let
        fakeLocalConfig = pkgs.writeShellScript "ldconfig-wrapper" ''
          if [ "$1" = "-p" ]; then
            echo "libcuda.so.1 (libc6,x86-64) => /run/opengl-driver/lib/libcuda.so.1"
            echo "libcuda.so (libc6,x86-64) => /run/opengl-driver/lib/libcuda.so.1"
          else
            exec ${pkgs.glibc.bin}/bin/ldconfig "$@"
          fi
        '';
      in ''
        mkdir -p /sbin
        ln -sf ${fakeLocalConfig} /sbin/ldconfig
      '';

  };
}
