# Reprise après sinistre — réinstallation complète

Procédure pour reconstruire cette machine sur un nouveau disque, à partir de
`nixos-config` (git) et d'une sauvegarde borg (voir `~/bin/backup-home`).

Écrite le 2026-07-21 suite à la défaillance du NVMe système (970 EVO Plus,
`Available Spare` tombé à 49 %, deux auto-tests SMART échoués).

## Prérequis avant de commencer

Sur la clé USB externe :

- `borg-local.key` (export de la clé du dépôt local, protection contre la
  corruption — pas indispensable au démarrage à froid)
- `borgbase-home.key` (idem, pour le dépôt distant)
- `borgbase-appendonly` (**clé privée SSH**, indispensable : sans elle,
  impossible de joindre le dépôt BorgBase) — protégée par sa propre
  phrase de passe (ajoutée le 2026-07-21 : aucune clé privée locale ne
  reste sans phrase sur cette machine, y compris celles dédiées à un
  script)
- `keys.txt.age` (clé age personnelle pour sops — le fichier chiffré tel
  quel, pas une version en clair)

Chacun de ces quatre fichiers est protégé par sa propre phrase de passe
(borg, borg, SSH, scrypt), donc aucun n'a besoin d'un contenant chiffré
supplémentaire.

En tête, mémorisées, jamais écrites : les phrases de passe des deux
dépôts borg, celle de la clé SSH BorgBase, et celle de `keys.txt.age`.

Note : `nixos-config`, `bin` (qui contient `backup-home` et
`restore-home`) et `dotfiles` sont tous des dépôts **publics** sur GitHub —
les cloner ne nécessite aucune clé. La clé SSH GitHub habituelle
(`~/.ssh/id_rsa`) n'est nécessaire que pour *pousser* des changements, ce
qui n'arrive qu'après la restauration complète du home (phase 7).

`~/dotfiles` porte un fichier marqueur `.nobackup` : borg ne le sauvegarde
**jamais** (voir `~/bin/backup-home`). Seule la version git fait foi. Les
liens symboliques que `stow` y pointe (`~/.zshrc`, `~/.config/niri`, etc.)
sont, eux, dans le home et reviendront avec la restauration borg — mais ils
resteront orphelins tant que `~/dotfiles` n'est pas cloné.

## Phase 1 — Installation physique (machine hors tension)

**Ne jamais manipuler le matériel machine sous tension** — un retrait à
chaud du NVMe défaillant a déjà provoqué un redémarrage brutal le
2026-07-19.

1. Éteindre complètement la machine (pas juste suspendre).
2. Installer le nouveau disque (WD Blue SN5100 2 To) dans le slot **M2_2**
   de la MSI B550M Mortar WiFi. L'ancien disque reste en place dans M2_1
   pour la durée de la migration (filet de sécurité). M2_2 désactive les
   ports SATA 5 et 6 sur cette carte, mais **Disque2 est branché en USB**
   (pont USB-SATA externe), donc non concerné.
3. Rebrancher Disque2 en USB.
4. Redémarrer, entrer dans le BIOS, confirmer que les deux NVMe et Disque2
   sont détectés.

## Phase 2 — Démarrage sur l'installeur NixOS

1. Démarrer sur la clé USB d'installation NixOS.
2. Identifier le nouveau disque avec certitude avant toute écriture :
   ```sh
   lsblk -o NAME,SIZE,MODEL
   ```
   Repérer le disque de 2 To (WD Blue SN5100) — **ne pas supposer** que
   c'est `nvme0n1` ou `nvme1n1`, l'ordre d'énumération dépend du slot. Le
   modèle affiché doit correspondre.

## Phase 3 — Partitionnement (même schéma qu'avant)

Même schéma que l'ancien disque : EFI 512 Mio vfat, LUKS root (le reste de
l'espace — sur 2 To, plus besoin de laisser de marge comme sur l'ancien
1 To), LUKS swap 8 Gio (pas d'hibernation utilisée avec 58 Gio de RAM,
donc pas besoin de swap ≥ RAM).

```sh
DISK=/dev/nvme1n1   # à confirmer avec lsblk (phase 2) — ne pas deviner

parted --script "$DISK" \
    mklabel gpt \
    mkpart ESP fat32 1MiB 513MiB \
    set 1 esp on \
    mkpart primary 513MiB 8705MiB \
    mkpart primary 8705MiB 100%

cryptsetup luksFormat "${DISK}p2"
cryptsetup luksFormat "${DISK}p3"
cryptsetup open "${DISK}p2" swap
cryptsetup open "${DISK}p3" root

mkfs.vfat -F32 -n boot "${DISK}p1"
mkfs.ext4 -L nixos /dev/mapper/root
mkswap -L swap /dev/mapper/swap

mount /dev/mapper/root /mnt
mkdir -p /mnt/boot
mount "${DISK}p1" /mnt/boot
swapon /dev/mapper/swap
```

(`${DISK}p1/p2/p3` : convention de nommage des partitions NVMe, avec le
`p` séparateur — adapter si le disque final s'avère être `/dev/sdX`.)

## Phase 4 — Configuration et installation

L'installeur NixOS n'a ni `git` ni les flakes activés par défaut — les
deux sont nécessaires ici (`git` est un paquet système déclaré dans
`nixos-config`, donc disponible seulement *après* `nixos-install` ; les
flakes, eux, le resteront pour de bon une fois le système installé,
puisque `nixos-config` les active lui-même).

```sh
export NIX_CONFIG="experimental-features = nix-command flakes"
```

1. Cloner la configuration (dépôt public, HTTPS anonyme, aucune clé
   nécessaire) :
   ```sh
   nix-shell -p git --run \
       "git clone https://github.com/Pierre-Thibault/nixos-config.git \
       /mnt/home/pierre/nixos-config"
   ```
2. **Régénérer `hardware-configuration.nix`** — c'est l'étape la plus
   facile à oublier, et son oubli empêche le nouveau système de démarrer
   (les UUID de l'ancien disque n'existent plus) :
   ```sh
   nixos-generate-config --root /mnt --show-hardware-config \
       > /mnt/home/pierre/nixos-config/modules/hardware/hardware-configuration.nix
   ```
   Comparer rapidement le résultat avec l'ancien fichier (mêmes sections :
   `fileSystems."/"`, `boot.initrd.luks.devices`, `fileSystems."/boot"`,
   `swapDevices`) — seuls les UUID doivent changer.
3. Installer :
   ```sh
   nixos-install --root /mnt --flake /mnt/home/pierre/nixos-config#pierre-nixos
   ```
4. Définir le mot de passe root si l'installeur le demande, puis
   `reboot`, retirer la clé USB d'installation.

## Phase 5 — Premier démarrage

Tout se fait ici en ligne de commande, dans un terminal ouvert après
connexion — pas de gestionnaire de fichiers. La connexion graphique
(niri) reste nécessaire malgré tout : c'est elle (via PAM) qui démarre la
session D-Bus et déverrouille `gnome-keyring-daemon`, dont `secret-tool`
dépend à la phase 6. Un chroot `nixos-enter` depuis l'installeur, pour
éviter le redémarrage, ne le permettrait pas — aucun service ni session
D-Bus n'y tourne.

1. Ouvrir la session LUKS puis niri, se connecter en tant que `pierre`,
   ouvrir un terminal.
2. **Committer localement** le nouveau `hardware-configuration.nix` — un
   commit local ne nécessite aucune clé, seul le `push` en aura besoin
   plus tard (phase 7, une fois `~/.ssh/id_rsa` restauré) :
   ```sh
   cd ~/nixos-config
   git add modules/hardware/hardware-configuration.nix
   git commit -m "Update hardware-configuration.nix for new NVMe (SN5100)"
   ```
3. Monter Disque2 (USB) et la clé USB portant les secrets :
   ```sh
   lsblk -o NAME,SIZE,MODEL
   udisksctl mount -b /dev/sdX1
   ```
   (ajuster `sdX1` selon la sortie de `lsblk`, une fois pour chaque
   disque)
5. Cloner le dépôt `bin` (dépôt public distinct de `nixos-config`, HTTPS
   anonyme) pour obtenir `restore-home` avant que le home ne soit
   restauré :
   ```sh
   git clone https://github.com/Pierre-Thibault/bin.git ~/bin
   ```
   `~/bin` porte lui aussi un `.nobackup` depuis le 2026-07-21 (comme
   `nixos-config` et `dotfiles`) : borg ne le sauvegarde jamais, donc rien
   à la phase 7 ne viendra écraser ce clone avec une copie plus ancienne.
6. Cloner `dotfiles` (public, HTTPS anonyme aussi) — nécessaire séparément
   puisque borg ne le sauvegarde jamais (`.nobackup`) :
   ```sh
   git clone https://github.com/Pierre-Thibault/dotfiles.git ~/dotfiles
   ```

## Phase 6 — Reconstituer les secrets (manuel, avant le script)

Le script de restauration a besoin de trois choses que la restauration
borg elle-même ne peut pas fournir (elles sont *dans* le home qu'on
restaure) :

1. **Clé SSH BorgBase** — elle est protégée par sa propre phrase de passe
   (aucune clé privée locale ne doit rester sans phrase, y compris celles
   dédiées à un script) :
   ```sh
   mkdir -p ~/.ssh
   cp /chemin/vers/clé-usb/borgbase-appendonly ~/.ssh/
   chmod 600 ~/.ssh/borgbase-appendonly
   ```
2. **Trousseau GNOME** — recréer les trois entrées avec les phrases
   mémorisées (elles seront demandées de façon interactive et masquée) :
   ```sh
   secret-tool store --label='Borg local (Disque2)' \
       repo-id 1dd9e1100359cab671f26037e17ba538cdeee0b2fa47181fd4c29e51204a66ac
   secret-tool store --label='BorgBase home' repo-id borgbase-home
   secret-tool store --label='BorgBase SSH key passphrase' \
       ssh-key borgbase-appendonly
   ```
   La troisième entrée alimente `~/bin/ssh-askpass-borgbase` (déjà cloné
   avec `~/bin` à l'étape précédente), qui permet à `restore-home` et
   `backup-home` d'ouvrir la clé SSH sans invite interactive — le même
   principe que `BORG_PASSCOMMAND` pour les phrases des dépôts.
3. Vérifier que les trois fonctionnent avant de lancer le script :
   ```sh
   secret-tool lookup repo-id 1dd9e1100359cab671f26037e17ba538cdeee0b2fa47181fd4c29e51204a66ac | wc -c
   secret-tool lookup repo-id borgbase-home | wc -c
   secret-tool lookup ssh-key borgbase-appendonly | wc -c
   ```
   (juste vérifier qu'un nombre d'octets non nul sort, sans afficher la
   phrase elle-même)
4. **Clé age personnelle (sops)** — remettre en place le fichier chiffré
   par phrase de passe tel quel (pas une version en clair : c'est le
   fichier que `~/dotfiles/zsh/.zshrc` attend déjà à cet emplacement via
   `SOPS_AGE_KEY_CMD`, aucun autre changement nécessaire) :
   ```sh
   mkdir -p ~/.config/sops/age
   cp /chemin/vers/zip-monte/keys.txt.age ~/.config/sops/age/
   chmod 600 ~/.config/sops/age/keys.txt.age
   ```
   Ne débloque que la clé **personnelle** (`pierre` dans `.sops.yaml`) —
   voir phase 8 pour la clé **machine**, qui ne peut pas être restaurée de
   la même façon.

## Phase 7 — Restauration et finalisation

1. Restaurer le home :
   ```sh
   ~/bin/restore-home
   ```
   Voir l'en-tête du script pour le choix de la source (`disque2` ou
   `borgbase`) et de l'archive.
2. `~/.ssh/id_rsa` est maintenant restauré — pousser le commit laissé en
   attente depuis la phase 5 :
   ```sh
   cd ~/nixos-config
   git push
   ```
3. Rien d'autre à faire pour les dotfiles : les liens symboliques
   (`~/.zshrc`, `~/.config/niri`, etc.) étaient déjà dans l'archive borg
   et viennent d'être restaurés à la phase 7.1 ; avec `~/dotfiles` cloné
   au bon endroit (phase 5), ils se résolvent tout seuls. `stow` n'est
   utile que pour lier un *nouveau* paquet, pas pour cette restauration.

## Phase 8 — Re-clé sops pour la nouvelle identité machine

`.sops.yaml` déclare deux destinataires par secret : `pierre` (ta clé
personnelle, restaurée en phase 6) et `pierre-nixos` (dérivée
automatiquement par sops-nix de `/etc/ssh/ssh_host_ed25519_key`). Cette
clé hôte est un fichier **système** (`/etc`, pas `/home`) — jamais
couverte par `backup-home` — et une installation fraîche en génère une
toute nouvelle. Résultat : au premier démarrage, sops-nix ne peut plus
déchiffrer aucun secret pour cette machine (geoclue, proxy API, mot de
passe iCloud) tant que cette étape n'est pas faite. Pas fatal pour le
démarrage du système lui-même — seuls les services qui dépendent de ces
secrets restent en échec entre-temps.

1. Obtenir la nouvelle clé publique age dérivée de la nouvelle clé hôte :
   ```sh
   nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub
   ```
2. Dans `~/nixos-config/.sops.yaml`, remplacer la valeur de l'ancre
   `&pierre-nixos` par cette nouvelle clé.
3. Re-chiffrer tous les secrets pour le nouvel ensemble de destinataires
   (utilise ta clé **personnelle**, déjà en place depuis la phase 6, pour
   déchiffrer et réécrire) :
   ```sh
   cd ~/nixos-config
   sops updatekeys sops/*.yaml
   ```
4. Committer et pousser :
   ```sh
   git add .sops.yaml sops/
   git commit -m "Re-key sops secrets for new machine SSH host key"
   git push
   ```
5. Rejouer l'activation pour que les services concernés récupèrent leurs
   secrets :
   ```sh
   sudo nixos-rebuild switch --flake ~/nixos-config#pierre-nixos
   ```

## Phase 9 — Validation, puis nettoyage

1. Vérifier quelques fichiers représentatifs, en particulier
   `Documents/LPA/Video/LPA/Entrevue-2015-01-19/Francais/Séquence 03.mp4`
   (le fichier récupéré par ddrescue le 2026-07-19).
2. Lancer `backup-home` pour confirmer que les deux dépôts (Disque2 et
   BorgBase) acceptent encore les écritures depuis la nouvelle machine.
3. Laisser cohabiter les deux disques quelques jours.
4. Une fois confiant : éteindre, retirer l'ancien NVMe, l'effacer
   (`blkdiscard` ou effacement sécurisé Samsung Magician) et l'envoyer en
   RMA (garantie 5 ans, dossier déjà accepté par le support Samsung).
