using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Web.Script.Serialization;
using BiologyUninstall;

namespace BiologyInstall
{
    public sealed class InstallFile
    {
        public string Relative, Source, Destination, Expected, Prior;
        public bool Delete;
    }
    public sealed class InstallPlan
    {
        public string PackageRoot, GameRoot, Version;
        public readonly List<InstallFile> Files = new List<InstallFile>();
    }
    public static class BiologyInstaller
    {
        // Exact retained loader payload only. An upstream attribution alone is
        // never permission to write arbitrary game files.
        private static readonly HashSet<string> Shared = new HashSet<string>(StringComparer.OrdinalIgnoreCase) {
            "engine\\tools\\scc.exe", "engine\\tools\\scc_lib.dll", "engine\\config\\base\\scripts.ini",
            "r6\\config\\cybercmd\\scc.toml", "bin\\x64\\global.ini",
            "bin\\x64\\version.dll", "bin\\x64\\plugins\\cybercmd.asi",
            "LICENSES\\redscript.txt", "LICENSES\\cybercmd.txt"
        };
        public static void EnsureStopped()
        {
            Process[] processes = Process.GetProcessesByName("Cyberpunk2077");
            try { if (processes.Length != 0) throw new InvalidOperationException("Close Cyberpunk 2077 before changing Biology."); }
            finally { foreach (Process process in processes) process.Dispose(); }
        }
        public static string HashOrNull(string path)
        {
            BiologyUninstallPlanner.AssertNoReparsePoint(path);
            if (Directory.Exists(path)) throw new IOException("A directory occupies a required file path: " + path);
            return File.Exists(path) ? BiologyUninstallPlanner.ComputeSha256(path) : null;
        }
        private static BiologyManifest ReadManifest(string path)
        {
            BiologyUninstallPlanner.AssertNoReparsePoint(path);
            BiologyManifest manifest = new JavaScriptSerializer().Deserialize<BiologyManifest>(File.ReadAllText(path, Encoding.UTF8));
            BiologyUninstallPlanner.ValidateManifest(manifest);
            if (manifest.gameVersion != "2.31") throw new InvalidDataException("This package requires Cyberpunk 2077 2.31.");
            return manifest;
        }
        private static Dictionary<string, BiologyManifestFile> Entries(BiologyManifest manifest)
        {
            var result = new Dictionary<string, BiologyManifestFile>(StringComparer.OrdinalIgnoreCase);
            foreach (BiologyManifestFile entry in manifest.files)
            {
                if (entry == null) throw new InvalidDataException("Null package inventory entry.");
                string path = BiologyUninstallPlanner.NormalizeRelativePath(entry.path);
                BiologyUninstallPlanner.ValidateEntry(entry, path);
                if (path.Equals("biology\\build-manifest.json", StringComparison.OrdinalIgnoreCase))
                    throw new InvalidDataException("The receipt cannot inventory itself.");
                if (entry.replacePolicy == "generic-dependency-shared" && !Shared.Contains(path))
                    throw new InvalidDataException("Unrecognized shared dependency destination: " + path);
                if (result.ContainsKey(path)) throw new InvalidDataException("Duplicate inventory path: " + path);
                result.Add(path, entry);
            }
            return result;
        }
        public static InstallPlan Plan(string packageRoot, string gameRoot)
        {
            string package = Path.GetFullPath(packageRoot).TrimEnd('\\', '/');
            string game = BiologyUninstallPlanner.ValidateGameRoot(gameRoot);
            if (package.Equals(game, StringComparison.OrdinalIgnoreCase) || package.StartsWith(game + "\\", StringComparison.OrdinalIgnoreCase) || game.StartsWith(package + "\\", StringComparison.OrdinalIgnoreCase))
                throw new InvalidDataException("Extract Biology into a separate folder outside the game folder, then run Install Biology.exe there.");
            BiologyUninstallPlanner.AssertNoReparsePoint(package);
            BiologyUninstallPlanner.AssertNoReparsePoint(game);
            string receipt = BiologyUninstallPlanner.ResolveSafeChildPath(package, BiologyUninstallPlanner.ManifestRelativePath);
            string destinationReceipt = BiologyUninstallPlanner.ResolveSafeChildPath(game, BiologyUninstallPlanner.ManifestRelativePath);
            BiologyManifest incoming = ReadManifest(receipt);
            var entries = Entries(incoming);
            var previous = File.Exists(destinationReceipt) ? Entries(ReadManifest(destinationReceipt)) : new Dictionary<string, BiologyManifestFile>(StringComparer.OrdinalIgnoreCase);
            var plan = new InstallPlan { PackageRoot = package, GameRoot = game, Version = incoming.version };

            // Changed previous files and untracked namespace content are never
            // silently overwritten or left executing beside a new release.
            foreach (var old in previous)
            {
                if (old.Value.replacePolicy != "biology-owned") continue;
                string target = BiologyUninstallPlanner.ResolveSafeChildPath(game, old.Key);
                string hash = HashOrNull(target);
                if (hash != null && !hash.Equals(old.Value.sha256, StringComparison.OrdinalIgnoreCase))
                    throw new IOException("A previously installed Biology file changed. Preserve/reconcile it before upgrade: " + old.Key);
                if (hash != null && !entries.ContainsKey(old.Key))
                    plan.Files.Add(new InstallFile { Relative = old.Key, Destination = target, Prior = hash, Delete = true });
            }
            foreach (string owned in new[] { "mods/Biology", "r6/scripts/CyberpunkRealism", "biology" })
                CheckNamespace(game, owned, previous);

            foreach (var item in entries)
            {
                string source = BiologyUninstallPlanner.ResolveSafeChildPath(package, item.Key);
                string target = BiologyUninstallPlanner.ResolveSafeChildPath(game, item.Key);
                string expected = item.Value.sha256.ToUpperInvariant();
                if (HashOrNull(source) != expected) throw new InvalidDataException("Package checksum mismatch: " + item.Key);
                string prior = HashOrNull(target);
                if (prior != null && prior != expected)
                {
                    BiologyManifestFile old;
                    if (item.Value.replacePolicy != "biology-owned" || !previous.TryGetValue(item.Key, out old) || old.replacePolicy != "biology-owned" || !prior.Equals(old.sha256, StringComparison.OrdinalIgnoreCase))
                        throw new IOException("Existing file conflict; no files changed: " + item.Key);
                }
                plan.Files.Add(new InstallFile { Relative = item.Key, Source = source, Destination = target, Expected = expected, Prior = prior });
            }
            // Receipt is committed last. It cannot hash itself.
            plan.Files.Add(new InstallFile { Relative = BiologyUninstallPlanner.ManifestRelativePath, Source = receipt, Destination = destinationReceipt, Expected = HashOrNull(receipt), Prior = HashOrNull(destinationReceipt) });
            return plan;
        }
        private static void CheckNamespace(string game, string relative, Dictionary<string, BiologyManifestFile> previous)
        {
            string path = BiologyUninstallPlanner.ResolveSafeChildPath(game, relative);
            if (!Directory.Exists(path)) return;
            foreach (string file in Directory.EnumerateFiles(path))
            {
                BiologyUninstallPlanner.AssertNoReparsePoint(file);
                string local = file.Substring(game.Length + 1).Replace('/', '\\');
                if (local.Equals("biology\\build-manifest.json", StringComparison.OrdinalIgnoreCase)) continue;
                BiologyManifestFile old;
                if (!previous.TryGetValue(local, out old) || old.replacePolicy != "biology-owned")
                    throw new IOException("Untracked file in the Biology namespace; preserve/reconcile before install: " + local);
            }
            foreach (string child in Directory.EnumerateDirectories(path)) CheckNamespace(game, child.Substring(game.Length + 1), previous);
        }
        public static void ValidateSupportedGame(string gameRoot)
        {
            string binary = BiologyUninstallPlanner.ResolveSafeChildPath(gameRoot, "bin/x64/Cyberpunk2077.exe");
            if (FileVersionInfo.GetVersionInfo(binary).ProductVersion != "2.31") throw new InvalidDataException("Biology supports Cyberpunk 2077 2.31. The selected game version differs.");
        }
        private sealed class Written
        {
            public InstallFile File;
            public string Backup;
        }
        public static void Execute(InstallPlan plan)
        {
            EnsureStopped();
            // Revalidate the complete plan before even the first payload write.
            foreach (InstallFile file in plan.Files)
            {
                BiologyUninstallPlanner.ResolveSafeChildPath(plan.GameRoot, file.Relative);
                if (HashOrNull(file.Destination) != file.Prior) throw new IOException("Destination changed after preflight: " + file.Relative);
                if (!file.Delete && HashOrNull(file.Source) != file.Expected) throw new IOException("Package changed after preflight: " + file.Relative);
            }
            var written = new List<Written>();
            try
            {
                foreach (InstallFile file in plan.Files)
                {
                    if (!file.Delete && file.Prior == file.Expected) continue;
                    EnsureStopped();
                    BiologyUninstallPlanner.ResolveSafeChildPath(plan.GameRoot, file.Relative);
                    if (HashOrNull(file.Destination) != file.Prior) throw new IOException("Destination changed before write: " + file.Relative);
                    Directory.CreateDirectory(Path.GetDirectoryName(file.Destination));
                    string backup = file.Prior == null ? null : file.Destination + ".biology-rollback-" + Guid.NewGuid().ToString("N");
                    if (file.Delete)
                    {
                        File.Move(file.Destination, backup);
                        written.Add(new Written { File = file, Backup = backup });
                        if (HashOrNull(backup) != file.Prior) throw new IOException("Upgrade removal changed: " + file.Relative);
                        continue;
                    }
                    string temp = file.Destination + ".biology-install-" + Guid.NewGuid().ToString("N");
                    try
                    {
                        File.Copy(file.Source, temp, false);
                        if (HashOrNull(temp) != file.Expected) throw new IOException("Staged copy checksum mismatch: " + file.Relative);
                        if (HashOrNull(file.Destination) != file.Prior) throw new IOException("Concurrent destination change: " + file.Relative);
                        if (backup == null) File.Move(temp, file.Destination);
                        else File.Replace(temp, file.Destination, backup, true);
                        written.Add(new Written { File = file, Backup = backup });
                        if (backup != null && HashOrNull(backup) != file.Prior) throw new IOException("Concurrent replace detected: " + file.Relative);
                        if (HashOrNull(file.Destination) != file.Expected) throw new IOException("Installed checksum mismatch: " + file.Relative);
                    }
                    finally { if (File.Exists(temp)) File.Delete(temp); }
                }
            }
            catch (Exception failure)
            {
                var errors = new List<string>();
                foreach (Written change in written.AsEnumerable().Reverse())
                {
                    try
                    {
                        InstallFile file = change.File;
                        BiologyUninstallPlanner.ResolveSafeChildPath(plan.GameRoot, file.Relative);
                        string current = HashOrNull(file.Destination);
                        if (current != (file.Delete ? null : file.Expected)) throw new IOException("Concurrent change preserved at " + file.Relative);
                        if (change.Backup == null) File.Delete(file.Destination);
                        else
                        {
                            if (HashOrNull(change.Backup) != file.Prior) throw new IOException("Backup changed; preserved for review: " + change.Backup);
                            if (current == null) File.Move(change.Backup, file.Destination);
                            else File.Replace(change.Backup, file.Destination, null, true);
                        }
                    }
                    catch (Exception ex) { errors.Add(ex.Message); }
                }
                throw new IOException("Installation stopped; rollback " + (errors.Count == 0 ? "completed." : "requires review: " + string.Join("; ", errors)) + " Original failure: " + failure.Message, failure);
            }
            foreach (Written change in written)
                if (change.Backup != null && HashOrNull(change.Backup) == change.File.Prior) File.Delete(change.Backup);
        }
    }
}
