# Attended managed candidate preparation — f643bbc1

Date: 2026-09-16
Parent: P01.2
Candidate source revision: `f643bbc1c50a69d223c2cf54e9fc7f68215e33fd`
Build ID: `biology-integrated-20260916-180825-f643bbc1c50a`

## Returned managed evidence

User returned one managed evidence bundle:

`Biology-Operator-Evidence-biology-integrated-20260916-180825-f643bbc1c50a.zip`

Returned bundle SHA-256: `9D415BCE6E67515864DE81B20AE3C16D498170C5B458344FD4AF8AEDF0B4B8EC`
Returned bundle bytes: `11282`

The bundle contained exactly `evidence.json` and `report.txt`.

## Candidate identity

- Managed result: `PASS`
- Cyberpunk product version: `2.31`
- Cyberpunk executable SHA-256: `A7DE82945C03E041FC7339FCF9066224D98DB2F5D80FEA50F7947BB350A60991`
- REDmod product version: `2.31`
- REDmod executable SHA-256: `144DF5A984669528CD957B40BB2126FE83B73D66BD0E041CA614C80F74E76A7F`
- Candidate artifact: `biology-integrated-20260916-180825-f643bbc1c50a.zip`
- Candidate artifact SHA-256: `F1000D2B8CAD3BB3889CAA77F86DA82BBDCC33DC4B53518623F2C6C77FB7322B`
- Candidate artifact bytes: `1980350`
- Installed receipt SHA-256 carried in managed evidence: `8D1386556A4545792F9BF98ADE3AD9B158EE087DC5051C09D5AD934B31482923`
- Managed report normalized SHA-256: `AC9D526CCE8A00587F0C2CFBA77357699FF93631DAC5F43347729007045CE26E`

## Preparation result

The returned evidence records:

- W11 transition evidence authenticated from the repository;
- 42 retired W11 paths still absent;
- Biology-specific residue verification PASS before install;
- exact compilation PASS for 62 Biology REDscript sources;
- redscript `0.5.31` and standalone cybercmd `0.0.13` verified;
- collision-safe install preflight PASS;
- release install PASS with 81 inventoried files;
- protected `bin/x64/global.ini` and `bin/x64/version.dll` created because absent, not overwritten;
- `bin/x64/plugins/cybercmd.asi` created with no replacement needed;
- installed receipt exact revision verification PASS;
- official REDmod deploy PASS through all five stages with `Commandlet deploy has succeeded`;
- tool stopped before game launch.

This proves exact candidate build/install/deploy preparation only. It does not yet prove that the configured REDscript runtime blob is regenerated on game startup or that Biology UI/body/E3 behavior is live.

## Next attended gate

Before the first launch, run the W13.1 installed-runtime activation probe read-only against this exact installed candidate. The first acceptance question is whether the configured `r6/cache/modded/final.redscripts` state is stale before launch and then regenerates after the first launch with standalone cybercmd present.
