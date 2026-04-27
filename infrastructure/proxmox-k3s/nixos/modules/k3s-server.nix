{ config, ... }:

{
  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = "/etc/k3s/token";
    extraFlags = [
      "--node-ip=${config.projet.k3s.nodeIp}"
      "--advertise-address=${config.projet.k3s.nodeIp}"
      "--write-kubeconfig-mode=0644"
      "--disable=servicelb"
    ];
  };

  environment.etc."k3s/token" = {
    text = "change-me-before-production";
    mode = "0600";
  };
}
