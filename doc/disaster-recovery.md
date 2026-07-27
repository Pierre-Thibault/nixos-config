# Reprise après sinistre — réinstallation complète

Procédure pour récupérer les données de cette machine en formatant le
disque : réinstallation complète à partir de `nixos-config` (git) et
d'une sauvegarde borg (voir `~/bin/backup-home`).

## Prérequis avant de commencer

Sur la clé USB externe :

- `borg-local.key` (export de la clé du dépôt local, protection contre la
  corruption — pas indispensable au démarrage à froid)
- `borgbase-home.key` (idem, pour le dépôt distant)
- `borgbase-appendonly` (**clé privée SSH**, indispensable : sans elle,
  impossible de joindre le dépôt BorgBase) — protégée par sa propre
  phrase de passe (aucune clé privée locale ne reste sans phrase sur
  cette machine, y compris celles dédiées à un script)
- `keys.txt.age` (clé age personnelle pour sops — le fichier chiffré tel
  quel, pas une version en clair)
- `github-pat.txt` (jeton d'accès personnel GitHub, voir plus bas)

Chacun des quatre premiers fichiers est protégé par sa propre phrase de
passe (borg, borg, SSH, scrypt), donc aucun n'a besoin d'un contenant
chiffré supplémentaire. Le jeton GitHub, lui, n'a pas de protection
propre — décision délibérée : un jeton *fine-grained*, lecture seule,
restreint aux trois dépôts publics ci-dessous n'a rien à protéger que la
sécurité physique de la clé USB ne couvre déjà (portée = source de la
protection, pas chiffrement).

En tête, mémorisées, jamais écrites : les phrases de passe des deux
dépôts borg, celle de la clé SSH BorgBase, et celle de `keys.txt.age`.

Note : `nixos-config`, `bin` (qui contient `backup-home` et
`restore-home`) et `dotfiles` sont tous des dépôts **publics** sur GitHub
— mais être public ne suffit pas : **le clone HTTPS anonyme ne
fonctionne pas** depuis l'installeur live (GitHub exige une
authentification même pour un dépôt public). Ne pas compter dessus ni le
tenter en premier — utiliser directement l'une des deux sources
ci-dessous.

**Deux sources indépendantes pour chacun des trois**, aucune n'étant un
point de défaillance obligatoire à elle seule :

1. **Disque2**, sous `GitMirrors/<dépôt>.git` — des miroirs *bare* tenus
   à jour par `backup-home` à chaque exécution (variable d'environnement
   `GIT_MIRROR_DIR`), entièrement indépendants de GitHub : aucun réseau
   requis, et ça continue de fonctionner même en cas de blocage ou de
   bannissement du compte GitHub.
2. **Jeton d'accès personnel GitHub** (`github-pat.txt` sur la clé USB,
   voir ci-dessus) — permanent, portée minimale (lecture seule,
   fine-grained, restreint à ces trois dépôts), pré-généré à l'avance
   plutôt que créé sur le moment : immédiatement disponible sans
   dépendre d'un autre appareil, et reste valide quel que soit le délai
   avant la prochaine reprise (imprévisible par nature). Usage :
   ```sh
   git clone "https://$(cat /chemin/vers/clé-usb/github-pat.txt)@github.com/Pierre-Thibault/nixos-config.git" ...
   ```
   (remplacer l'URL pour `bin` et `dotfiles`).

Le miroir Disque2 est le premier recours (aucune dépendance à GitHub) ;
le jeton USB, le second (dépend de GitHub mais pas de Disque2). La clé
SSH GitHub habituelle (`~/.ssh/id_rsa`) reste nécessaire séparément pour
*pousser* des changements, ce qui n'arrive qu'après la restauration
complète du home (phase 6) — ni l'une ni l'autre de ces deux sources ne
remplace cette étape, elles ne servent qu'aux clones des phases 3-4.

Les liens symboliques que `stow` pointe vers `~/dotfiles` (`~/.zshrc`,
`~/.config/niri`, etc.) sont, eux, dans le home et reviendront avec la
restauration borg — mais ils resteront orphelins tant que `~/dotfiles`
n'est pas cloné.

## Phase 1 — Démarrage sur l'installeur NixOS

**Clavier : choisir directement le canadien CSA pour la session live**
(au démarrage, ou dans les réglages une fois le bureau live affiché).
L'installeur démarre sur une session GNOME graphique — tout le reste de
cette phase (comme les phases 2-3) se fait dans un terminal ouvert à
l'intérieur de cette session, pas dans une console texte brute du noyau.
CSA s'y applique donc normalement, comme sur n'importe quel bureau
graphique ; aucun contournement clavier n'est nécessaire ici. La
disposition graphique (`xkb-layout=ca` / `xkb-variant=multix`, le vrai
CSA) reste déclarée dans `configuration.nix` et s'applique normalement
dès la première connexion niri, une fois le système installé.

1. Démarrer sur la clé USB d'installation NixOS.
2. Identifier le disque cible avec certitude avant toute écriture :
   ```sh
   lsblk -o NAME,SIZE,MODEL
   ```
   **Ne pas supposer** le nom du périphérique (`nvme0n1`, `nvme1n1`,
   `sda`...) — vérifier la taille et le modèle affichés contre ce qui
   est attendu.

## Phase 2 — Partitionnement

**Utiliser l'assistant de partitionnement de l'installeur graphique**
(« effacer le disque entier », chiffrement activé) — plus simple et plus
fiable que des commandes `parted`/`cryptsetup` manuelles. Revalider le
disque identifié en phase 1 (taille, modèle) dans l'assistant avant de
confirmer quoi que ce soit — il écrit sur le disque entier sans
confirmation supplémentaire au-delà de ce premier choix.

Résultat typique : EFI vfat, LUKS racine (le plus gros, ext4, tout
l'espace restant après swap), LUKS swap (dimensionné pour l'hibernation
si celle-ci est activée par défaut — sans conséquence si l'hibernation
n'est de toute façon pas utilisée au quotidien). L'ordre des partitions
produit par l'assistant peut placer la racine avant le swap, sans
importance.

**Vérifier que tout est monté sous `/mnt`** avant de passer à la phase 3,
qui suppose que c'est déjà fait (pas garanti que l'assistant s'en charge
automatiquement selon la version) :
```sh
findmnt /mnt
lsblk -o NAME,FSTYPE,MOUNTPOINT
```
Si `/mnt` (racine) et `/mnt/boot` (EFI) n'apparaissent pas montés,
monter manuellement — adapter les noms à ceux que l'assistant a créés :
```sh
mount /dev/mapper/<nom-racine> /mnt
mkdir -p /mnt/boot
mount /dev/<partition-EFI> /mnt/boot
```

**Piège central, indépendant de la méthode de partitionnement** :
`nixos-generate-config` (phase 3) ne détecte **pas automatiquement** les
partitions LUKS qui ne servent qu'au swap pour
`boot.initrd.luks.devices` — seules celles associées à un système de
fichiers monté (racine, `/boot`) sont repérées. Le fichier généré
référence `swapDevices` avec un chemin `/dev/mapper/luks-<uuid>` que
rien ne déclare déverrouiller, sans avertissement ni erreur à la
génération — seulement un swap silencieusement inactif et, au démarrage
suivant, un timeout systemd (« Dependency failed for Swaps ») noyé dans
le bruit habituel du journal de démarrage. Voir la correction requise à
la phase 3, étape 2.

## Phase 3 — Configuration et installation

L'installeur NixOS n'a ni `git` ni les flakes activés par défaut — les
deux sont nécessaires ici (`git` est un paquet système déclaré dans
`nixos-config`, donc disponible seulement *après* `nixos-install` ; les
flakes, eux, le resteront pour de bon une fois le système installé,
puisque `nixos-config` les active lui-même).

```sh
export NIX_CONFIG="experimental-features = nix-command flakes"
nix-shell -p git
```
Reste dans ce shell pour le reste de la phase 3 — `git` y est disponible
en plus de tout ce que l'installeur fournit déjà (`nixos-generate-config`,
`nixos-install`), inutile d'en sortir ni de le relancer à chaque commande.

1. Cloner la configuration. **Le clone HTTPS anonyme ne fonctionne pas**
   (voir « Prérequis ») — utiliser directement l'une des deux sources
   suivantes :
   - **Depuis Disque2**, si branché et monté (aucun réseau requis — voir
     « Prérequis », `GIT_MIRROR_DIR` : `backup-home` tient à jour un
     miroir bare de chaque dépôt là, indépendant de GitHub) :
   ```sh
   git clone /run/media/pierre/Disque2/GitMirrors/nixos-config.git \
       /mnt/home/pierre/nixos-config
   ```
   - **Sinon, avec le jeton** : brancher la clé USB des secrets (voir
     « Prérequis » — distincte de Disque2), puis :
   ```sh
   git clone "https://$(cat /chemin/vers/clé-usb/github-pat.txt)@github.com/Pierre-Thibault/nixos-config.git" \
       /mnt/home/pierre/nixos-config
   ```
2. **Régénérer `hardware-configuration.nix`** — c'est l'étape la plus
   facile à oublier, et son oubli empêche le nouveau système de démarrer
   (les UUID de l'ancien disque n'existent plus) :
   ```sh
   nixos-generate-config --root /mnt --show-hardware-config \
       > /mnt/home/pierre/nixos-config/modules/hardware/hardware-configuration.nix
   ```
   Comparer avec l'ancien fichier — pas juste en diagonale (voir
   phase 2) : compter le nombre d'entrées `boot.initrd.luks.devices`. Si
   le disque a une partition LUKS dédiée au swap (le cas normalement),
   il doit y en avoir **deux** — une pour la racine, une pour le swap.
   Le fichier généré n'en contient typiquement qu'**une seule**
   (racine) : `nixos-generate-config` ne détecte pas les LUKS de swap.
   Ajouter la seconde à la main, sur le même modèle que celle de la
   racine, avec l'UUID de la partition swap (visible via
   `lsblk -o NAME,FSTYPE,UUID` — chercher la partition `crypto_LUKS`
   dont le nom mappé correspond à celui déjà utilisé par `swapDevices`
   juste en dessous) :
   ```nix
   boot.initrd.luks.devices."luks-<uuid-swap>".device = "/dev/disk/by-uuid/<uuid-swap>";
   ```
   Sans cette entrée, aucune erreur ni avertissement au démarrage suivant
   — juste un swap silencieusement inactif (`swapon --show` vide) et un
   timeout systemd noyé dans le bruit du journal (« Dependency failed for
   Swaps »).

   **Autre piège à surveiller à la même comparaison** :
   `nixos-generate-config` scrute les montages *actifs* au moment où il
   tourne, pas seulement le matériel physique. Un test lancé directement
   sur une machine déjà installée (donc hors du contexte réel d'une
   reprise, sans `--root /mnt`) peut faire apparaître des entrées
   `fileSystems` bogues pour des montages FUSE (rclone, sshfs, etc.) —
   des montages gérés dynamiquement par des services utilisateur, jamais
   censés être déclarés en dur. Sur l'installeur live avec `--root /mnt`,
   aucun tel montage ne devrait être actif, mais par prudence : vérifier
   qu'aucune entrée `fileSystems` inattendue, en plus de `/` et `/boot`,
   ne s'est glissée dans le fichier généré avant de le garder.
3. **Désactiver temporairement sops et le proxy caddy** avant
   d'installer. `nixos-install` exécute les mêmes scripts d'activation
   qu'un `nixos-rebuild switch` — avec la config telle que committée
   (secrets actifs par défaut), il se heurterait probablement au même
   piège qu'en phase 7 : `.sops.yaml` ne connaît pas encore l'identité de
   cette nouvelle machine, donc tout déchiffrement échoue et fait échouer
   l'activation dans son ensemble (non vérifié directement — inféré du
   même mécanisme observé en phase 7). Éditer
   `/mnt/home/pierre/nixos-config/config/userdata.nix` :
   ```nix
   enableSops = false;
   enableCaddyProxy = false;
   ```
   Ne pas committer ce changement — il reste local pour l'instant, les
   deux commutateurs sont remis à `true` et committés en phase 7.
4. Installer :
   ```sh
   nixos-install --root /mnt --flake /mnt/home/pierre/nixos-config#pierre-nixos
   ```
5. Définir le mot de passe root si l'installeur le demande, puis
   `reboot`, retirer la clé USB d'installation.

## Phase 4 — Premier démarrage

Tout se fait ici en ligne de commande, dans un terminal — pas de
gestionnaire de fichiers. La connexion graphique (niri) est nécessaire :
c'est elle (via PAM) qui démarre la session D-Bus et déverrouille
`gnome-keyring-daemon`, dont `secret-tool` dépend à la phase 5.

**Ne pas basculer vers une console texte** (`Ctrl+Alt+F<n>`) sur cette
machine : la bascule de VT peut provoquer une instabilité sérieuse
(jusqu'à un blocage complet nécessitant un redémarrage matériel),
probablement liée à la présence d'un second GPU (calcul CUDA uniquement,
sans écran branché) qui perturbe le transfert de contrôle DRM/KMS entre
`niri` et la console. Cause non résolue avec certitude — ne pas retenter
sans raison.

**À la place : rester dans niri, mais neutraliser temporairement les
services qui peuvent interférer avec l'écriture en masse de la
restauration (phase 6).** Le suspect le plus probable pour ce genre
d'interférence est l'indexeur de fichiers (`localsearch`,
ex-`tracker-miner-fs`), qui scrute activement les fichiers modifiés. Ces
services s'activent à la demande via D-Bus plutôt que de tourner en
permanence — un simple `stop` ne les empêche pas d'être relancés en
cours de route, il faut les **masquer** :
```sh
systemctl --user mask --now \
    localsearch-3.service localsearch-control-3.service \
    localsearch-writeback-3.service gvfs-metadata.service
```
Diagnostic non confirmé avec certitude — si des symptômes d'interférence
apparaissent malgré ce masquage, ajouter d'autres services suspects à la
liste (candidats : `evolution-*.service`, `gvfs-daemon.service` et les
moniteurs de volumes `gvfs-*-volume-monitor.service`) et mettre à jour
cette étape en conséquence.

1. Ouvrir la session LUKS puis niri, se connecter en tant que `pierre`,
   ouvrir un terminal. Exécuter la commande `systemctl --user mask`
   ci-dessus avant de continuer.
2. **Committer localement** le nouveau `hardware-configuration.nix` — un
   commit local ne nécessite aucune clé, seul le `push` en aura besoin
   plus tard (phase 6, une fois `~/.ssh/id_rsa` restauré) :
   ```sh
   cd ~/nixos-config
   git add modules/hardware/hardware-configuration.nix
   git commit -m "Update hardware-configuration.nix for new disk"
   ```
3. Monter Disque2 (USB) et la clé USB portant les secrets :
   ```sh
   lsblk -o NAME,SIZE,MODEL
   udisksctl mount -b /dev/sdX1
   ```
   (ajuster `sdX1` selon la sortie de `lsblk`, une fois pour chaque
   disque)
4. Cloner le dépôt `bin` (dépôt public distinct de `nixos-config`) pour
   obtenir `restore-home` avant que le home ne soit restauré — depuis
   Disque2 ou avec le jeton, comme en phase 3 (le clone anonyme ne
   fonctionne pas) :
   ```sh
   git clone /run/media/pierre/Disque2/GitMirrors/bin.git ~/bin
   # ou, avec le jeton (voir « Prérequis ») :
   git clone "https://$(cat /chemin/vers/clé-usb/github-pat.txt)@github.com/Pierre-Thibault/bin.git" ~/bin
   ```
   `backup-home` sauvegarde l'arborescence entière de `~/bin` (seul
   `.git/` est exclu). La phase 6 peut donc écraser ce clone frais sans
   souci : pour les fichiers suivis par git, le contenu de borg est
   identique à celui du clone (aucune perte) ; pour d'éventuels fichiers
   gitignorés, c'est borg qui devient la seule source, donc bienvenue.
5. Cloner `dotfiles` — mêmes sources :
   ```sh
   git clone /run/media/pierre/Disque2/GitMirrors/dotfiles.git ~/dotfiles
   # ou, avec le jeton (voir « Prérequis ») :
   git clone "https://$(cat /chemin/vers/clé-usb/github-pat.txt)@github.com/Pierre-Thibault/dotfiles.git" ~/dotfiles
   ```
6. **Initialiser les sous-modules** — `oh-my-zsh` (`oh-my-zsh/.oh-my-zsh`)
   et `zsh-vi-mode` (`oh-my-zsh-custom/.oh-my-zsh-custom/plugins/zsh-vi-mode`,
   pointé par `ZSH_CUSTOM`) sont de vrais sous-modules git, jamais peuplés
   par un simple `git clone` ; sans cette étape, zsh échoue au démarrage
   (`source: aucun fichier ou dossier de ce nom: .../oh-my-zsh.sh`, ou
   `plugin 'zsh-vi-mode' not found`). Tout futur plugin oh-my-zsh
   personnalisé ajouté sous `ZSH_CUSTOM` (et non plus directement sous
   `~/.oh-my-zsh/custom`, qui est à l'intérieur du sous-module oh-my-zsh
   et donc invisible à git comme à borg) sera couvert par la même
   commande, sans mise à jour de cette procédure. L'URL de `oh-my-zsh`
   est déclarée en SSH (`git@github.com:...`), donc inutilisable avant la
   phase 6 (clé `~/.ssh/id_rsa` pas encore restaurée) — on force un
   remplacement HTTPS à la volée pour tout initialiser dès maintenant,
   sans clé :
   ```sh
   cd ~/dotfiles
   git -c url."https://github.com/".insteadOf="git@github.com:" \
       submodule update --init --recursive
   ```
   (`.gitmodules` peut déclarer d'autres sous-modules orphelins sans
   contenu réel dans l'arbre git actuel — vérifier via
   `git submodule status`, sans conséquence.)

## Phase 5 — Reconstituer les secrets (manuel, avant le script)

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
   cp /chemin/vers/clé-usb/keys.txt.age ~/.config/sops/age/
   chmod 600 ~/.config/sops/age/keys.txt.age
   ```
   Ne débloque que la clé **personnelle** (`pierre` dans `.sops.yaml`) —
   voir phase 7 pour la clé **machine**, qui ne peut pas être restaurée de
   la même façon.

## Phase 6 — Restauration et finalisation

1. Lancer la restauration, dans le même terminal niri qu'à la phase 4
   (services d'indexation déjà masqués) :
   ```sh
   ~/bin/restore-home
   ```
   Voir l'en-tête du script pour le choix de la source (`disque2` ou
   `borgbase`) et de l'archive.
2. **Réactiver les services masqués en phase 4** une fois la restauration
   terminée :
   ```sh
   systemctl --user unmask --now \
       localsearch-3.service localsearch-control-3.service \
       localsearch-writeback-3.service gvfs-metadata.service
   ```
3. `~/.ssh/id_rsa` est maintenant restauré — pousser le commit laissé en
   attente depuis la phase 4. **D'abord corriger `origin`** : `nixos-config`
   a été cloné en phase 3 depuis Disque2 ou avec le jeton (voir
   « Prérequis »), jamais depuis GitHub directement — `origin` pointe
   donc soit vers un chemin local sur Disque2, soit vers une URL HTTPS
   avec le jeton intégré (lecture seule, un `push` échouerait). Dans les
   deux cas, `git push` échoue ou pousse au mauvais endroit tant que
   `origin` n'a pas été remis sur l'URL SSH habituelle :
   ```sh
   cd ~/nixos-config
   git remote set-url origin git@github.com:Pierre-Thibault/nixos-config.git
   git push
   ```
4. Presque rien d'autre à faire pour les dotfiles : les liens
   symboliques (`~/.zshrc`, `~/.config/niri`, etc.) étaient déjà dans
   l'archive borg et viennent d'être restaurés à l'étape 6.1 ; avec
   `~/dotfiles` cloné au bon endroit (phase 4), ils se résolvent tout
   seuls. `stow` n'est utile que pour lier un *nouveau* paquet, pas pour
   cette restauration. **Exception** : les liens de thème clair/foncé
   (`bat/config`, `helix/config.toml`, `wezterm/wezterm.lua`, etc.) sont
   volontairement gitignorés (préférence locale, pas versionnée) donc
   jamais dans l'archive borg non plus — les régénérer avec
   `set-dark-theme` ou `set-light-theme` selon la préférence du moment.
5. **Corriger aussi `origin` pour `bin` et `dotfiles`**, pour la même
   raison — ils ont été clonés en phase 4 de la même façon que
   `nixos-config` en phase 3, jamais depuis GitHub directement. Rien à
   pousser tout de suite dans ces deux dépôts, mais un futur `git push`
   (un usage normal, pas cette procédure) échouerait sinon :
   ```sh
   git -C ~/bin remote set-url origin git@github.com:Pierre-Thibault/bin.git
   git -C ~/dotfiles remote set-url origin git@github.com:Pierre-Thibault/dotfiles.git
   ```

## Phase 7 — Re-clé sops pour la nouvelle identité machine

`.sops.yaml` déclare deux destinataires par secret : `pierre` (ta clé
personnelle, restaurée en phase 5) et `pierre-nixos` (l'identité de la
machine). Cette identité machine est une clé age **auto-générée par
sops-nix** (`sops.age.keyFile = "/var/lib/sops-nix/key.txt"`,
`sops.age.generateKey = true`, voir `modules/sops/sops-proxy.nix`) —
indépendante de sshd, qui est intentionnellement désactivé sur ce poste
(`userdata.sshEnable = false`, donc `/etc/ssh/ssh_host_ed25519_key`
n'existe jamais ; une approche via `age.sshKeyPaths` ne pourrait pas
fonctionner ici).

`/var/lib/sops-nix/key.txt` est un fichier d'**état local** (`/var`, pas
`/home`) : jamais sauvegardé par borg, jamais versionné, unique à chaque
installation. **Cette phase se reproduira donc à l'identique à chaque
future reprise après sinistre** — ce n'est pas un correctif ponctuel.

**Piège central** : dès qu'un module déclare un `sops.secrets.*` ou
`sops.templates.*`, sops-nix tente de le déchiffrer à l'activation —
indépendamment de savoir si le service qui le consomme est activé ou
non. Tant que `.sops.yaml` ne connaît pas la nouvelle clé machine, cette
tentative échoue et **fait échouer `nixos-rebuild switch` dans son
ensemble** (« Activation script snippet 'setupSecrets' failed »), pas
seulement le service concerné. `userdata.enableSops` neutralise
justement tous les points qui déclarent des secrets d'un coup (gate
chaque `sops.secrets`/`sops.templates` de `sops-icloud.nix`,
`sops-geoclue.nix`, `sops-proxy.nix`, ainsi que la référence à
`config.sops.templates."geoclue.conf".path` dans `configuration.nix` —
sans toucher à `defaultSopsFile`/`age.keyFile`/`age.generateKey`, qui
doivent justement s'exécuter à ce bootstrap) — déjà à `false`, avec
`enableCaddyProxy`, depuis la phase 3.

1. Vérifier l'évaluation avant de toucher au système (rapide, sans
   `sudo`, détecte les erreurs de syntaxe/référence avant qu'elles ne
   coûtent un cycle de `nixos-rebuild`) :
   ```sh
   cd ~/nixos-config
   nix eval .#nixosConfigurations.pierre-nixos.config.system.build.toplevel.drvPath
   ```
2. `switch` — confirme/complète la génération de
   `/var/lib/sops-nix/key.txt` (probablement déjà fait par
   `nixos-install` en phase 3, cette étape est sans danger dans les deux
   cas — `age.generateKey` ne régénère rien si le fichier existe déjà) :
   ```sh
   sudo nixos-rebuild switch --flake ~/nixos-config#pierre-nixos
   ```
3. Obtenir la nouvelle clé publique :
   ```sh
   sudo age-keygen -y /var/lib/sops-nix/key.txt
   ```
4. Dans `~/nixos-config/.sops.yaml`, remplacer la valeur de l'ancre
   `&pierre-nixos` par cette nouvelle clé.
5. Re-chiffrer tous les secrets pour le nouvel ensemble de destinataires.
   **À exécuter dans ton propre terminal, jamais via un agent** : `age`
   a besoin d'un vrai terminal pour demander ta phrase de passe
   personnelle (`SOPS_AGE_KEY_CMD` invoque `age -d` sur `keys.txt.age`,
   qui échoue silencieusement sans TTY réel) :
   ```sh
   cd ~/nixos-config
   sops updatekeys -y sops/api-proxy.yaml sops/secrets.yaml sops/grip.yaml sops/ovh.yaml
   ```
6. **Remettre `userdata.enableSops = true;` et
   `userdata.enableCaddyProxy = true;`**, revérifier l'évaluation
   (étape 1).
7. Rebuild final — déchiffrement réussi cette fois pour les trois
   (proxy, iCloud, geoclue) :
   ```sh
   sudo nixos-rebuild switch --flake ~/nixos-config#pierre-nixos
   ```
8. Committer et pousser `.sops.yaml` + `sops/*.yaml` re-chiffrés, et
   `config/userdata.nix` avec les deux commutateurs remis à `true` (ils
   ne doivent jamais rester à `false` dans un commit — seul le bootstrap
   des étapes 1 à 6 les utilise, strictement en local et temporaire).

## Phase 8 — Validation, puis nettoyage

1. Vérifier quelques fichiers représentatifs dans différents dossiers
   (Documents, projets, etc.) pour confirmer que la restauration s'est
   bien déroulée.
2. **Nettoyer les dossiers XDG créés par GNOME en anglais.** À la toute
   première connexion niri (phase 4, avant la restauration borg), GNOME
   crée automatiquement `~/Desktop`, `~/Downloads`, `~/Music`,
   `~/Pictures`, `~/Public`, `~/Templates`, `~/Videos` — en anglais,
   indépendamment de la locale `fr_CA.UTF-8` déclarée. La restauration
   borg (phase 6) ramène ensuite les vrais dossiers en français
   (`~/Bureau`, `~/Téléchargements`, `~/Musique`, `~/Images`, etc., avec
   leur contenu) **à côté** de ces dossiers anglais, sans les toucher :
   aucune perte de données, juste des dossiers vides en trop. Les
   supprimer (`rmdir` échoue proprement s'ils ne sont pas vides — donc
   sans risque si l'un d'eux contenait malgré tout quelque chose) :
   ```sh
   rmdir ~/Desktop ~/Downloads ~/Music ~/Pictures ~/Public ~/Templates ~/Videos 2>/dev/null
   ```
   (`~/Documents` s'écrit identiquement dans les deux langues, rien à
   faire pour lui.) Piste structurelle pour éviter le problème à la
   source une fois pour toutes : déclarer `xdg.userDirs` dans
   `nixos-config` avec les noms français explicites, plutôt que de
   dépendre du comportement par défaut de GNOME au premier lancement.
3. **Vérifier le montage iCloud** (`~/icloud`, service utilisateur
   `rclone-icloud`) :
   ```sh
   systemctl --user status rclone-icloud
   ```
   Le jeton de confiance Apple (`type = iclouddrive` dans
   `~/.config/rclone/rclone.conf`) expire après une période d'inactivité
   — une restauration implique presque toujours une coupure assez longue
   pour ça, indépendamment de la cause de la reprise elle-même. Symptôme
   possible : le service redémarre en boucle, `journalctl --user -u
   rclone-icloud` montre `trust token expired, please reauth`. Correctif
   — **interactif, à faire dans ton propre terminal, jamais via un
   agent** (mot de passe Apple + code 2FA) :
   ```sh
   systemctl --user stop rclone-icloud
   rclone config reconnect icloud:
   systemctl --user start rclone-icloud
   ```
4. **Rouvrir manuellement la base KeePassXC.** KeePassXC répartit son
   état sur deux fichiers — les vrais réglages dans
   `~/.config/keepassxc/keepassxc.ini` (thème, intégration navigateur,
   clés KeeShare — correctement restaurés par borg) et l'état de session
   (dernière base ouverte, fichiers récents, disposition des fenêtres)
   dans `~/.cache/keepassxc/keepassxc.ini` — exclu de la sauvegarde
   comme tout `~/.cache`. Un choix de conception discutable de KeePassXC
   (XDG_CACHE_HOME est censé ne contenir que du régénérable, pas un état
   comme « dernière base ouverte ») plutôt qu'une lacune de
   `backup-home` — pas de correctif prévu ici. Aucune perte réelle : la
   base elle-même (`~/Documents/.../*.kdbx`) est un fichier ordinaire,
   sauvegardée normalement. Juste la rouvrir une fois à la main après la
   restauration.
5. Lancer `backup-home` pour confirmer que les deux dépôts (Disque2 et
   BorgBase) acceptent encore les écritures depuis la machine reconstruite.
