{
  description = "NixOS K3s cluster on Proxmox for the DevOps M1 project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, disko, ... }:
    let
      system = "x86_64-linux";
      mkNode = name: role: ip: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          ./modules/disko-proxmox.nix
          ./modules/common.nix
          ./modules/tailscale.nix
          ./modules/k3s-${role}.nix
          ./hosts/${name}.nix
          {
            networking.hostName = name;
            projet.k3s.nodeIp = ip;
          }
        ];
      };
    in {
      nixosConfigurations = {
        k3s-cp-1 = mkNode "k3s-cp-1" "server" "192.168.1.61";
        k3s-worker-1 = mkNode "k3s-worker-1" "agent" "192.168.1.62";
        k3s-worker-2 = mkNode "k3s-worker-2" "agent" "192.168.1.63";
      };
    };
}
