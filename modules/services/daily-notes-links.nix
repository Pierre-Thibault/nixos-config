{ pkgs, ... }:

let
  notesSubpath = "Documents/Notes-Personnelles/Organisation/Journées";

  updateScript = pkgs.writeScript "update-daily-notes-links" ''
    #!${pkgs.python3}/bin/python3
    import datetime
    import os
    import sys
    from pathlib import Path

    FRENCH_WEEKDAYS = [
        "lundi",
        "mardi",
        "mercredi",
        "jeudi",
        "vendredi",
        "samedi",
        "dimanche",
    ]

    MANAGED_LINKS = ("Aujourd'hui.md", "Hier.md")


    def find_daily_note(notes_dir: Path, target_date: datetime.date) -> Path | None:
        date_prefix = target_date.isoformat()
        expected_weekday = FRENCH_WEEKDAYS[target_date.weekday()]
        preferred_name = f"{date_prefix} {expected_weekday}.md".casefold()

        candidates: list[Path] = []
        for entry in notes_dir.iterdir():
            if entry.name in MANAGED_LINKS:
                continue
            if entry.is_symlink() or not entry.is_file():
                continue
            if not (entry.name.startswith(date_prefix) and entry.name.endswith(".md")):
                continue
            # Match either "YYYY-MM-DD.md" or "YYYY-MM-DD <suffix>.md".
            rest = entry.name[len(date_prefix) :]
            if rest != ".md" and not rest.startswith(" "):
                continue
            candidates.append(entry)

        if not candidates:
            return None

        for candidate in candidates:
            if candidate.name.casefold() == preferred_name:
                return candidate

        return sorted(candidates, key=lambda p: p.name)[0]


    def sync_hardlink(notes_dir: Path, link_name: str, target: Path | None) -> None:
        link_path = notes_dir / link_name

        if target is None:
            if link_path.is_symlink() or link_path.is_file():
                link_path.unlink()
            return

        target_stat = target.lstat()
        if link_path.is_symlink():
            # Replace any legacy symlink left over from the previous version.
            link_path.unlink()
        elif link_path.exists():
            link_stat = link_path.lstat()
            if (link_stat.st_dev, link_stat.st_ino) == (
                target_stat.st_dev,
                target_stat.st_ino,
            ):
                return
            if not link_path.is_file():
                print(
                    f"Skipping {link_path}: exists and is not a regular file",
                    file=sys.stderr,
                )
                return
            link_path.unlink()

        os.link(target, link_path)


    def main() -> int:
        notes_dir = Path.home() / "${notesSubpath}"
        if not notes_dir.is_dir():
            return 0

        today = datetime.date.today()
        yesterday = today - datetime.timedelta(days=1)

        sync_hardlink(notes_dir, "Aujourd'hui.md", find_daily_note(notes_dir, today))
        sync_hardlink(notes_dir, "Hier.md", find_daily_note(notes_dir, yesterday))
        return 0


    if __name__ == "__main__":
        raise SystemExit(main())
  '';

  commonUnitConfig = {
    ConditionUser = "!gdm-greeter";
    ConditionPathIsDirectory = "%h/${notesSubpath}";
  };
in
{
  systemd.user.services.daily-notes-links = {
    description = "Update hard links for today's and yesterday's daily notes";
    wantedBy = [ "default.target" ];
    unitConfig = commonUnitConfig;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${updateScript}";
    };
  };

  systemd.user.paths.daily-notes-links = {
    description = "Watch daily notes directory to update Aujourd'hui.md and Hier.md";
    wantedBy = [ "default.target" ];
    unitConfig = commonUnitConfig;
    pathConfig = {
      PathChanged = "%h/${notesSubpath}";
    };
  };

  systemd.user.timers.daily-notes-links = {
    description = "Refresh daily notes hard links at midnight";
    wantedBy = [ "timers.target" ];
    unitConfig = commonUnitConfig;
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
