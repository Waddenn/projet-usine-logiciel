# Déploiement K3s NixOS sur Proxmox

Préparation pour un cluster K3s hébergé en VM NixOS sur le nœud Proxmox `proxade`.

## Cible retenue

Le nœud `proxade` dispose de 24 vCPU, 62 GiB RAM et d'un stockage ZFS `Storage` très disponible. Pour le MVP DevOps, le dimensionnement proposé reste volontairement raisonnable:

| VM | VMID | IP | Rôle | CPU | RAM | Disque |
| --- | ---: | --- | --- | ---: | ---: | ---: |
| `k3s-cp-1` | 301 | `192.168.1.61` | control-plane | 2 | 4096 MiB | 32 GiB |
| `k3s-worker-1` | 302 | `192.168.1.62` | worker | 2 | 4096 MiB | 32 GiB |
| `k3s-worker-2` | 303 | `192.168.1.63` | worker | 2 | 4096 MiB | 32 GiB |

Réseau: `vmbr0`, passerelle `192.168.1.254`, DNS `1.1.1.1`.

## Choix technique

Le déploiement ne repose pas sur Ansible. Le flux retenu est:

1. Proxmox crée trois VM bootstrap Debian cloud-init.
2. `nixos-anywhere` remplace ces VM par NixOS à partir du `flake`.
3. Les changements suivants se font avec `nixos-rebuild switch --target-host`.

NixOS 25.11 est utilisé car c'est la version stable publiée le 30 novembre 2025; la branche 26.05 est encore en préversion au 27 avril 2026.

## Pré-requis poste local

- Accès SSH fonctionnel vers `root@proxade`.
- `nix` installé localement avec les flakes activés.
- Une clé publique SSH disponible et ajoutée dans `nixos/ssh-authorized-keys.pub`.

## Étapes

Depuis ce répertoire:

```bash
cd infrastructure/proxmox-k3s
ssh-keygen -t ed25519 -N '' -f /tmp/projet-etude-k3s-ed25519 -C 'projet-etude-k3s'
scp scripts/*.sh root@proxade:/root/
scp /tmp/projet-etude-k3s-ed25519.pub root@proxade:/root/k3s-admin.pub
ssh root@proxade 'bash /root/00-create-debian-template.sh'
ssh root@proxade 'SSH_KEY_FILE=/root/k3s-admin.pub bash /root/01-create-k3s-vms.sh'
./scripts/02-install-nixos-anywhere.sh
```

La clé privée temporaire utilisée par défaut est `/tmp/projet-etude-k3s-ed25519`. Pour une utilisation durable, remplace-la par une clé stockée proprement hors du dépôt et lance les scripts avec `IDENTITY_FILE=/chemin/vers/cle`.

Après la première installation:

```bash
./scripts/03-switch-nixos.sh
```

Avant production, remplace le token K3s `change-me-before-production` dans:

- `nixos/modules/k3s-server.nix`
- `nixos/modules/k3s-agent.nix`

## Vérifications

```bash
ssh ops@192.168.1.61 'sudo kubectl get nodes -o wide'
ssh ops@192.168.1.61 'sudo kubectl get pods -A'
```

## Suite logique du projet

Une fois K3s prêt, les composants du cahier des charges peuvent être installés par Helm:

- `ingress-nginx` ou Traefik intégré K3s pour l'exposition HTTP.
- `cert-manager` si TLS requis.
- `kube-prometheus-stack` pour Prometheus/Grafana.
- `loki` ou `elastic` pour les logs.
- `vault` pour les secrets.
- `trivy-operator` pour les scans Kubernetes.
- `minio` pour le stockage d'artefacts compatible S3.
