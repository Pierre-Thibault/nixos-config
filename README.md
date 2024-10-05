# My NixOS configuration

I'm sharing my NixOS configuration. I did a nice separation in a few files. I might help others to do the same and serve as an example.

## Installation

1. Clone the git repository.
1. Change the host name in `flake.nix`
1. Edit `userdata.nix` and change the values for what is appropriate for your system.
1. Run `nix flake update` to update `flake.lock`.
1. CD into the repository directory.
1. Run `nixos-rebuild switch --flake .` to build and switch to generation defined by these files.

## Notes

### Gnome Extensions

I was unable to list all the Gnome Extensions I wanted for conflicting reasons. These extensions are installed manually on my system:

- Emoji Copy
- Tiling Shell

### `bin` directory

This directory contains some nice utility scripts I used. I added them here to easily share them.

#### `clipsnipper`

A simple script to grab something on the screen and convert it to text. Very useful when the text is inside an image or in a video. The result is sent to the clipboard.

I created a Gnome shortcut (Gnome Settings > Keyboard > Keyboard shortcuts ) with the command:

    gnome-terminal --geometry=0x0 -- ./nixos-config/bin/clipsnipper

I use gnome-terminal because I needed a window to be able to access the clipboard on Wayland.

### `services`

My services are not working perfectly well. It is better than nothing but it would be nice to address.

#### `set-dark-theme` and `set-light-theme`

These are two scripts I used with the Night Theme Switcher Gnome extension as commands to set my colors properly.

## Roadmap

- Soon, integrating Home Manager.
- Make a video to explain how I manage the system theme (light and dark) with Gnome.

## Contributing

Comments are welcome.

## License

[MIT](https://choosealicense.com/licenses/mit/)
