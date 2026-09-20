using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Web.Script.Serialization;
using BiologyInstall;
using BiologyUninstall;

internal static class BiologyInstallCoreTests
{
    private static int checks;
    private static void Check(bool value, string message) { checks++; if (!value) throw new Exception(message); }
    private static void Refuse(Action action, string message) { bool refused = false; try { action(); } catch (Exception) { refused = true; } Check(refused, message); }
    private static string Write(string root, string relative, string text)
    {
        string path = Path.Combine(root, relative.Replace('/', '\\'));
        Directory.CreateDirectory(Path.GetDirectoryName(path)); File.WriteAllText(path, text); return path;
    }
    private static BiologyManifest Manifest(string package, string version, params string[] paths)
    {
        var result = new BiologyManifest { schemaVersion = 2, product = "Biology", version = version, buildId = version, gameVersion = "2.31", sourceRevision = new string('a',40), playableRuntimeIncluded = true, officialPackageRoot = "mods/Biology",
            uninstall = new BiologyUninstallContract { schemaVersion=2,playerBinary="Uninstall Biology.exe",biologyOwnedPolicy="biology-owned",genericDependencyPolicy="preserve",savePolicy="never-target",preferencePolicy="stored-in-save-never-target",redmodRefresh="official-redmod-deploy-explicit-root" },
            files = paths.Select(p => new BiologyManifestFile { path=p, sha256=BiologyUninstallPlanner.ComputeSha256(Path.Combine(package,p.Replace('/','\\'))),owner=p.StartsWith("bin/")?"upstream:cybercmd":"Biology",component="fixture",route="TEST",replacePolicy=p.StartsWith("bin/")?"generic-dependency-shared":"biology-owned" }).ToArray() };
        Save(package, result); return result;
    }
    private static void Save(string package, BiologyManifest manifest) { Write(package, "biology/build-manifest.json", new JavaScriptSerializer().Serialize(manifest)); }
    private static string Game(string root, string name) { string game=Path.Combine(root,name); Write(game,"bin/x64/Cyberpunk2077.exe","fixture"); Directory.CreateDirectory(Path.Combine(game,"r6")); return game; }
    private static int Main(string[] args)
    {
        if (args.Length == 1) { Refuse(() => BiologyUninstallPlanner.ResolveSafeChildPath(args[0], "redirect/file.txt"), "Reparse point accepted"); return 0; }
        string root = Path.Combine(Path.GetTempPath(), "BiologyInstallTests-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(root);
        try
        {
            string game=Game(root,"game"), package=Path.Combine(root,"package");
            Write(package,"mods/Biology/info.json","v1"); Write(package,"r6/scripts/CyberpunkRealism/old.reds","old"); Write(package,"bin/x64/version.dll","shared");
            Manifest(package,"v1","mods/Biology/info.json","r6/scripts/CyberpunkRealism/old.reds","bin/x64/version.dll");
            Write(game,"unrelated/sentinel.txt","keep");
            InstallPlan clean=BiologyInstaller.Plan(package,game);
            Check(!File.Exists(Path.Combine(game,"mods/Biology/info.json")),"Preflight wrote payload");
            Check(clean.Files.Last().Relative==BiologyUninstallPlanner.ManifestRelativePath,"Receipt not last");
            BiologyInstaller.Execute(clean);
            Check(File.ReadAllText(Path.Combine(game,"mods/Biology/info.json"))=="v1","Clean install failed");
            Check(BiologyUninstallPlanner.ComputeSha256(Path.Combine(game,"biology/build-manifest.json"))==BiologyUninstallPlanner.ComputeSha256(Path.Combine(package,"biology/build-manifest.json")),"Receipt drift");
            BiologyInstaller.Execute(BiologyInstaller.Plan(package,game));
            Check(File.ReadAllText(Path.Combine(game,"bin/x64/version.dll"))=="shared","Reinstall changed shared file");

            Write(package,"mods/Biology/info.json","v2"); Write(package,"r6/scripts/CyberpunkRealism/new.reds","new");
            BiologyManifest v2=Manifest(package,"v2","mods/Biology/info.json","r6/scripts/CyberpunkRealism/new.reds","bin/x64/version.dll");
            BiologyInstaller.Execute(BiologyInstaller.Plan(package,game));
            Check(!File.Exists(Path.Combine(game,"r6/scripts/CyberpunkRealism/old.reds")),"Upgrade left stale runtime source");
            Check(File.ReadAllText(Path.Combine(game,"mods/Biology/info.json"))=="v2","Upgrade missing");
            Check(File.ReadAllText(Path.Combine(game,"unrelated/sentinel.txt"))=="keep","Unrelated file changed");
            Check(!Directory.EnumerateFiles(game,"*.biology-*",SearchOption.AllDirectories).Any(),"Successful transaction left backups");

            Write(game,"mods/Biology/info.json","user edit");
            Refuse(()=>BiologyInstaller.Plan(package,game),"Changed receipt-owned file overwritten");
            Check(File.ReadAllText(Path.Combine(game,"mods/Biology/info.json"))=="user edit","Changed file not preserved");
            Write(game,"mods/Biology/info.json","v2");
            string unexpected=Write(game,"r6/scripts/CyberpunkRealism/untracked.reds","keep");
            Refuse(()=>BiologyInstaller.Plan(package,game),"Untracked executing file ignored"); File.Delete(unexpected);
            Write(game,"bin/x64/version.dll","other loader");
            Refuse(()=>BiologyInstaller.Plan(package,game),"Shared dependency conflict overwritten");
            Write(game,"bin/x64/version.dll","shared");

            string fresh=Game(root,"fresh"); Write(fresh,"mods/Biology/info.json","unowned");
            Refuse(()=>BiologyInstaller.Plan(package,fresh),"Unowned Biology namespace overwritten");
            string badSource=Write(package,"mods/Biology/info.json","corrupt");
            Refuse(()=>BiologyInstaller.Plan(package,game),"Corrupt package accepted"); Write(package,"mods/Biology/info.json","v2");
            InstallPlan race=BiologyInstaller.Plan(package,game); Write(game,"mods/Biology/info.json","concurrent");
            Refuse(()=>BiologyInstaller.Execute(race),"Stale destination plan executed"); Write(game,"mods/Biology/info.json","v2");
            race=BiologyInstaller.Plan(package,game); Write(package,"mods/Biology/info.json","tampered after plan");
            Refuse(()=>BiologyInstaller.Execute(race),"Stale source plan executed"); Write(package,"mods/Biology/info.json","v2");

            v2.files=v2.files.Concat(new[]{v2.files[0]}).ToArray(); Save(package,v2);
            Refuse(()=>BiologyInstaller.Plan(package,game),"Duplicate path accepted");
            v2=Manifest(package,"v2","mods/Biology/info.json","r6/scripts/CyberpunkRealism/new.reds","bin/x64/version.dll");
            foreach(string path in new[]{"../outside","/absolute","C:/outside","mods/Biology/.. /escape","mods/Biology/CON.txt","mods/Biology/trailing.","mods/Biology/stream:ads","mods/Biology//duplicate"})
                Refuse(()=>BiologyUninstallPlanner.ResolveSafeChildPath(game,path),"Unsafe path accepted: "+path);
            Refuse(()=>BiologyInstaller.Plan(game,game),"Install from game root allowed");

            // A sharing violation during the second real write must restore the
            // first replacement and leave the previous receipt byte-identical.
            string receiptBefore=BiologyUninstallPlanner.ComputeSha256(Path.Combine(game,"biology/build-manifest.json"));
            Write(package,"mods/Biology/info.json","v3"); Write(package,"r6/scripts/CyberpunkRealism/new.reds","new-v3");
            Manifest(package,"v3","mods/Biology/info.json","r6/scripts/CyberpunkRealism/new.reds","bin/x64/version.dll");
            InstallPlan failing=BiologyInstaller.Plan(package,game);
            using(var locked=File.Open(Path.Combine(game,"r6/scripts/CyberpunkRealism/new.reds"),FileMode.Open,FileAccess.Read,FileShare.Read))
                Refuse(()=>BiologyInstaller.Execute(failing),"Locked destination accepted");
            Check(File.ReadAllText(Path.Combine(game,"mods/Biology/info.json"))=="v2","Rollback failed to restore earlier replacement");
            Check(BiologyUninstallPlanner.ComputeSha256(Path.Combine(game,"biology/build-manifest.json"))==receiptBefore,"Failed transaction changed receipt");
            Check(!Directory.EnumerateFiles(game,"*.biology-*",SearchOption.AllDirectories).Any(),"Clean rollback left backups");
            Console.WriteLine("PASS: " + checks + " native installer ownership, collision, upgrade, preflight and rollback checks.");
            return 0;
        }
        catch(Exception ex) { Console.Error.WriteLine(ex); return 1; }
        finally
        {
            string full=Path.GetFullPath(root);
            string prefix=Path.GetFullPath(Path.GetTempPath()).TrimEnd('\\')+"\\BiologyInstallTests-";
            if(full.StartsWith(prefix,StringComparison.OrdinalIgnoreCase) && Directory.Exists(full)) Directory.Delete(full,true);
        }
    }
}
