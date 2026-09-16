# Attended runtime activation acceptance — f643bbc1

Date: 2026-09-16
Parent: P01.2
Candidate source revision: `f643bbc1c50a69d223c2cf54e9fc7f68215e33fd`
Build ID: `biology-integrated-20260916-180825-f643bbc1c50a`
Cyberpunk 2077: 2.31
W13 worker head used for both probes: `6736e456d90879abe1c4d3fd0c96c2df8da7bd05`

## Pre-launch baseline

Returned report:
`Biology-Installed-Runtime-Activation-Probe-20260916-131631-adce1b26.txt`
SHA-256: `70713FE37DCA3B390732451B1927AB90C61FBE0FD68A42259C9C560D0485D465`

The read-only pre-launch probe proved:

- exact installed candidate source revision matched `f643bbc1...`;
- 81/81 receipt files hash-verified, 0 missing, 0 mismatched;
- all 62 Biology REDscript sources were installed;
- standalone cybercmd task-runner plumbing was present (`cybercmd.asi`, `version.dll`, `global.ini`);
- `scc.toml` configured `InvokeScc` to `r6/cache/modded/final.redscripts`;
- configured blob existed but was stale, dated 2026-09-15T15:30:34.7021522Z, bytes `16035530`, SHA-256 `2119046F3F3466206D8A16A4803B0EF0F3C90926AB689F9ABBD5B8E42E28EE86`;
- `final.redscripts.ts` did not exist;
- Boundary 2 classified as `BROKEN/STALE` before launch.

## Attended launch observations

The user launched the exact candidate with REDlauncher mods enabled, loaded normal gameplay, inspected Biology and Cyberware, then exited normally.

Observed in-game:

- Biology top-level screen is materially present and usable enough to navigate;
- Cyberware remains functional as an internal submode;
- the prior `[ BIOLOGY ERROR ] BODY RUNTIME SYSTEM MISSING` message is no longer visible;
- Biology overview shows `BODY STABLE`;
- first-use Biology drill-down initially routed multiple selections to the shoulder area; switching to Cyberware and back caused subsequent drill-down targeting to behave more correctly;
- selected Biology drill-downs zoom to anatomy but reveal no substantive selected-system information;
- ordinary first-person gameplay still reads as current/modern HUD; intended E3-inspired presentation is not materially present in the attended capture.

These downstream findings remain routed to open attended follow-ups #39 (Biology shell/navigation/detail state), #40 (E3 presentation), and #41 (authoritative body/detail population).

## Post-launch proof

Returned post-launch report:
`Biology-Installed-Runtime-Activation-Probe-20260916-132950-1926ad81.txt`
SHA-256: `EAA415E1139F8275A7DBA6830A95B7EC9FFA787320148A4646771D83D67DA2B3`

A duplicate read-only post-launch probe at 13:28 returned the same installed-state result; the 13:29 report is retained as the canonical post-launch evidence.

The post-launch probe proved:

- exact installed candidate remained intact: 81/81 receipt files hash-verified;
- configured `r6/cache/modded/final.redscripts` regenerated at 2026-09-16T18:21:15.7305869Z, after the candidate payload;
- regenerated blob bytes: `16384772`;
- regenerated blob SHA-256: `D9351B838A194D366CD81DAEA079782F7C506DBA7EC0A4324B18012A7509781E`;
- `r6/cache/modded/final.redscripts.ts` now exists, dated 2026-09-16T18:21:15.7414682Z;
- current REDscript log is also current and records compilation of all 62 Biology REDscript sources with zero error/failure signal lines;
- log explicitly ends with `Compilation complete` and `Output successfully saved to ...\r6\cache\modded\final.redscripts`;
- Boundary 2 classified `OUTPUT-CURRENT`;
- probe reports `FIRST PROVEN BROKEN BOUNDARY: NONE FROM READ-ONLY EXTERNAL EVIDENCE YET`.

## Disposition

**W13.1 startup/runtime-activation repair is attended-accepted.**

The original startup boundary is no longer blocking downstream Biology behavior: the standalone cybercmd path executes the configured `scc.toml` task on supported launch and regenerates the REDscript blob from the installed candidate.

This does not accept the remaining Biology UI/detail/body-state or E3 presentation defects. Those continue under #39, #40, and #41.
