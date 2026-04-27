{ config, ... }:

{
  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://192.168.1.61:6443";
    tokenFile = "/etc/k3s/token";
    extraFlags = [
      "--node-ip=${config.projet.k3s.nodeIp}"
    ];
  };

  environment.etc."k3s/token" = {
    text = "change-me-before-production";
    mode = "0600";
  };
}
