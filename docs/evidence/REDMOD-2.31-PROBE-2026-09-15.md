# REDmod 2.31 Direct Probe Evidence — 2026-09-15

This note records only facts directly observed on the supported local Cyberpunk 2077 installation. It does not infer runtime behavior that was not exercised.

## Observed install

- Game root: `C:\Games\Steam\steamapps\common\Cyberpunk 2077`
- REDmod executable: `tools\redmod\bin\redMod.exe`
- File version: `2.3.1.0`
- Product version: `2.31`
- File description: `REDmod`
- Company: `CD PROJEKT S.A.`
- The REDmod toolset includes `metadata.json`, `scc.exe`, engine script sources under `tools\redmod\scripts`, and tweak sources under `tools\redmod\tweaks`.

## Observed CLI contract

Running `redMod.exe --help` outside the game root produced a root warning because REDmod defaulted to `C:\`, but still printed its module list and global parameter contract.

Observed modules:

- `resource-export`
- `resource-import`
- `animation-import`
- `util-hash`
- `deploy` — described by REDmod as: "Deploys mods to the game by compiling them together."
- `help`

Observed global parameter:

- `-root` — specifies the game directory; REDmod reports that most modules require it.

Therefore, repository tooling must invoke REDmod with an explicit game root rather than relying on the process working directory or REDmod's default-root heuristic.

## Observed current `mods` directory

At probe time, `Cyberpunk 2077\mods` contained only:

- `.stub`

No deployed Biology package was present yet. This means the probe proves the supported installation's REDmod tooling and current clean package directory state, but does **not** yet prove Biology recognition, deployment success, enable/disable persistence, relaunch persistence, or cross-mod overlap precedence.

## What this closes / does not close

This evidence resolves the previous uncertainty about:

- the installed REDmod executable location;
- the installed REDmod version corresponding to Cyberpunk 2077 2.31;
- the presence of the REDmod `deploy` module;
- the need to pass an explicit `-root` path in deterministic tooling;
- the starting state of the game's `mods` directory.

Still requiring an attended or safe direct-game probe:

- PKG-01 recognition/deploy acceptance for `mods/Biology`;
- PKG-03 enable/disable and relaunch persistence;
- PKG-05 overlap/load-order behavior using harmless reversible fixtures;
- any claim that a built Biology package actually loads in gameplay.
