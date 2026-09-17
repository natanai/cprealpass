using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Web.Script.Serialization;

namespace BiologyUninstall
{
    public sealed class BiologyManifest
    {
        public int schemaVersion { get; set; }
        public string product { get; set; }
        public string buildId { get; set; }
        public string version { get; set; }
        public string gameVersion { get; set; }
        public string sourceRevision { get; set; }
        public bool playableRuntimeIncluded { get; set; }
        public string officialPackageRoot { get; set; }
        public BiologyManifestFile[] files { get; set; }
        public BiologyUninstallContract uninstall { get; set; }
    }

    public sealed class BiologyManifestFile
    {
        public string path { get; set; }
        public string sha256 { get; set; }
        public string owner { get; set; }
        public string component { get; set; }
        public string route { get; set; }
        public string replacePolicy { get; set; }
    }

    public sealed class BiologyUninstallContract
    {
        public int schemaVersion { get; set; }
        public string playerBinary { get; set; }
        public string biologyOwnedPolicy { get; set; }
        public string genericDependencyPolicy { get; set; }
        public string savePolicy { get; set; }
        public string preferencePolicy { get; set; }
        public string redmodRefresh { get; set; }
    }

    public enum BiologyPlanAction
    {
        DeleteBiologyOwned,
        PreserveGenericDependency,
        PreserveChangedBiologyOwned,
        Missing
    }

    public sealed class BiologyPlanItem
    {
        public BiologyManifestFile Entry { get; set; }
        public string FullPath { get; set; }
        public BiologyPlanAction Action { get; set; }
        public string ActualSha256 { get; set; }
        public string Reason { get; set; }
    }

    public sealed class BiologyUninstallPlan
    {
        public string GameRoot { get; set; }
        public string ManifestPath { get; set; }
        public string ManifestSha256 { get; set; }
        public BiologyManifest Manifest { get; set; }
        public List<BiologyPlanItem> Items { get; private set; }

        public BiologyUninstallPlan()
        {
            Items = new List<BiologyPlanItem>();
        }

        public int Count(BiologyPlanAction action)
        {
            return Items.Count(x => x.Action == action);
        }
    }

    public sealed class BiologyExecutionOptions
    {
        public bool SkipRedmodRefresh { get; set; }
    }

    public sealed class BiologyExecutionResult
    {
        public readonly List<string> Deleted = new List<string>();
        public readonly List<string> PreservedGeneric = new List<string>();
        public readonly List<string> PreservedChanged = new List<string>();
        public readonly List<string> Missing = new List<string>();
        public readonly List<string> Errors = new List<string>();
        public readonly List<string> Notes = new List<string>();
        public bool ReceiptDeleted { get; set; }
        public RedmodRefreshResult RedmodRefresh { get; set; }

        public bool BiologyPayloadFullyRemoved
        {
            get { return PreservedChanged.Count == 0 && Errors.Count == 0; }
        }
    }

    public sealed class RedmodRefreshResult
    {
        public bool Attempted { get; set; }
        public bool Succeeded { get; set; }
        public int ExitCode { get; set; }
        public int OtherRedmodCount { get; set; }
        public string Outcome { get; set; }
        public string Output { get; set; }
    }

    public static class BiologyUninstallPlanner
    {
        public const int SupportedManifestSchema = 2;
        public const string Product = "Biology";
        public const string BiologyOwnedPolicy = "biology-owned";
        public const string GenericDependencyPolicy = "generic-dependency-shared";
        public const string ExpectedBinary = "Uninstall Biology.exe";
        public const string ManifestRelativePath = "biology/build-manifest.json";

        private static readonly Regex Sha256Pattern = new Regex("^[A-Fa-f0-9]{64}$", RegexOptions.CultureInvariant);
        private static readonly string[] BiologyOwnedPrefixes = new[]
        {
            "mods\\Biology\\",
            "r6\\scripts\\CyberpunkRealism\\",
            "biology\\"
        };
        private static readonly HashSet<string> BiologyOwnedRootFiles = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "Install Biology.ps1",
            "BiologyReleaseInstall.Core.ps1",
            "INSTALL.txt",
            "UNINSTALL.txt",
            "BIOLOGY-VERSION.txt",
            "SHA256SUMS.txt",
            ExpectedBinary
        };

        public static BiologyUninstallPlan Build(string gameRoot, string manifestPath)
        {
            string root = ValidateGameRoot(gameRoot);
            string expectedManifest = ResolveSafeChildPath(root, ManifestRelativePath);
            string suppliedManifest = Path.GetFullPath(manifestPath);
            if (!string.Equals(expectedManifest, suppliedManifest, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidDataException("The ownership receipt is not at biology/build-manifest.json under this game root.");
            }
            if (!File.Exists(suppliedManifest))
            {
                throw new FileNotFoundException("Biology ownership receipt is missing; automatic uninstall cannot prove what Biology owns.", suppliedManifest);
            }

            string json = File.ReadAllText(suppliedManifest, Encoding.UTF8);
            BiologyManifest manifest;
            try
            {
                manifest = new JavaScriptSerializer().Deserialize<BiologyManifest>(json);
            }
            catch (Exception ex)
            {
                throw new InvalidDataException("Biology ownership receipt is not valid JSON.", ex);
            }
            ValidateManifest(manifest);

            BiologyUninstallPlan plan = new BiologyUninstallPlan();
            plan.GameRoot = root;
            plan.ManifestPath = suppliedManifest;
            plan.ManifestSha256 = ComputeSha256(suppliedManifest);
            plan.Manifest = manifest;

            HashSet<string> seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (BiologyManifestFile entry in manifest.files)
            {
                string relative = NormalizeRelativePath(entry.path);
                if (!seen.Add(relative))
                {
                    throw new InvalidDataException("Duplicate path in Biology ownership receipt: " + relative);
                }
                ValidateEntry(entry, relative);
                string full = ResolveSafeChildPath(root, relative);
                BiologyPlanItem item = new BiologyPlanItem();
                item.Entry = entry;
                item.FullPath = full;

                if (!File.Exists(full))
                {
                    item.Action = BiologyPlanAction.Missing;
                    item.Reason = "already absent";
                    plan.Items.Add(item);
                    continue;
                }

                string actual = ComputeSha256(full);
                item.ActualSha256 = actual;
                if (string.Equals(entry.replacePolicy, GenericDependencyPolicy, StringComparison.Ordinal))
                {
                    item.Action = BiologyPlanAction.PreserveGenericDependency;
                    item.Reason = string.Equals(actual, entry.sha256, StringComparison.OrdinalIgnoreCase)
                        ? "generic/shared dependency is preserved even when unchanged"
                        : "generic/shared dependency changed and is preserved";
                }
                else if (string.Equals(actual, entry.sha256, StringComparison.OrdinalIgnoreCase))
                {
                    item.Action = BiologyPlanAction.DeleteBiologyOwned;
                    item.Reason = "Biology-owned file matches the immutable receipt hash";
                }
                else
                {
                    item.Action = BiologyPlanAction.PreserveChangedBiologyOwned;
                    item.Reason = "Biology-owned file changed since packaging; automatic deletion refused";
                }
                plan.Items.Add(item);
            }
            return plan;
        }

        public static string ValidateGameRoot(string gameRoot)
        {
            if (string.IsNullOrWhiteSpace(gameRoot))
            {
                throw new InvalidDataException("Cyberpunk 2077 game root was not supplied.");
            }
            string root = Path.GetFullPath(gameRoot).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            if (!File.Exists(Path.Combine(root, "bin", "x64", "Cyberpunk2077.exe")))
            {
                throw new InvalidDataException("Selected folder is not a Cyberpunk 2077 game root (bin/x64/Cyberpunk2077.exe is missing).");
            }
            if (!Directory.Exists(Path.Combine(root, "r6")))
            {
                throw new InvalidDataException("Selected folder is not a Cyberpunk 2077 game root (r6 is missing).");
            }
            return root;
        }

        public static string NormalizeRelativePath(string path)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                throw new InvalidDataException("Ownership receipt contains an empty path.");
            }
            if (path.IndexOf('\0') >= 0 || path.IndexOf(':') >= 0)
            {
                throw new InvalidDataException("Ownership receipt contains an unsafe path: " + path);
            }
            string value = path.Replace('/', '\\').Trim();
            if (value.StartsWith("\\", StringComparison.Ordinal) || Path.IsPathRooted(value))
            {
                throw new InvalidDataException("Ownership receipt contains a rooted/UNC path: " + path);
            }
            string[] segments = value.Split(new[] { '\\' }, StringSplitOptions.None);
            if (segments.Length == 0 || segments.Any(x => x.Length == 0 || x == "." || x == ".."))
            {
                throw new InvalidDataException("Ownership receipt contains traversal or an ambiguous path segment: " + path);
            }
            return string.Join("\\", segments);
        }

        public static string ResolveSafeChildPath(string gameRoot, string relativePath)
        {
            string root = Path.GetFullPath(gameRoot).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            string normalized = NormalizeRelativePath(relativePath);
            string full = Path.GetFullPath(Path.Combine(root, normalized));
            string prefix = root + Path.DirectorySeparatorChar;
            if (!full.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidDataException("Ownership receipt path escapes the game root: " + relativePath);
            }
            return full;
        }

        public static string ComputeSha256(string path)
        {
            using (SHA256 sha = SHA256.Create())
            using (FileStream stream = File.Open(path, FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                byte[] hash = sha.ComputeHash(stream);
                return BitConverter.ToString(hash).Replace("-", string.Empty).ToUpperInvariant();
            }
        }

        private static void ValidateManifest(BiologyManifest manifest)
        {
            if (manifest == null || manifest.schemaVersion != SupportedManifestSchema || !string.Equals(manifest.product, Product, StringComparison.Ordinal))
            {
                throw new InvalidDataException("Unsupported or non-Biology ownership receipt; automatic uninstall refused.");
            }
            if (!manifest.playableRuntimeIncluded || !string.Equals(manifest.officialPackageRoot, "mods/Biology", StringComparison.Ordinal))
            {
                throw new InvalidDataException("Ownership receipt is not the supported playable Biology package shape.");
            }
            if (manifest.files == null || manifest.files.Length == 0)
            {
                throw new InvalidDataException("Biology ownership receipt has no file inventory.");
            }
            if (manifest.uninstall == null || manifest.uninstall.schemaVersion != 2)
            {
                throw new InvalidDataException("Biology ownership receipt does not contain the supported uninstall contract.");
            }
            if (!string.Equals(manifest.uninstall.playerBinary, ExpectedBinary, StringComparison.Ordinal) ||
                !string.Equals(manifest.uninstall.biologyOwnedPolicy, BiologyOwnedPolicy, StringComparison.Ordinal) ||
                !string.Equals(manifest.uninstall.genericDependencyPolicy, "preserve", StringComparison.Ordinal) ||
                !string.Equals(manifest.uninstall.savePolicy, "never-target", StringComparison.Ordinal) ||
                !string.Equals(manifest.uninstall.preferencePolicy, "stored-in-save-never-target", StringComparison.Ordinal) ||
                !string.Equals(manifest.uninstall.redmodRefresh, "official-redmod-deploy-explicit-root", StringComparison.Ordinal))
            {
                throw new InvalidDataException("Biology ownership receipt uninstall policy is unexpected; automatic uninstall refused.");
            }
        }

        private static void ValidateEntry(BiologyManifestFile entry, string relative)
        {
            if (entry == null || string.IsNullOrWhiteSpace(entry.owner) || string.IsNullOrWhiteSpace(entry.component) || string.IsNullOrWhiteSpace(entry.route))
            {
                throw new InvalidDataException("Ownership receipt contains incomplete metadata for: " + relative);
            }
            if (string.IsNullOrWhiteSpace(entry.sha256) || !Sha256Pattern.IsMatch(entry.sha256))
            {
                throw new InvalidDataException("Ownership receipt contains an invalid SHA-256 for: " + relative);
            }

            if (string.Equals(entry.replacePolicy, BiologyOwnedPolicy, StringComparison.Ordinal))
            {
                if (!string.Equals(entry.owner, Product, StringComparison.Ordinal) || !IsAllowedBiologyOwnedPath(relative))
                {
                    throw new InvalidDataException("Biology-owned deletion is not allowed at this path: " + relative);
                }
            }
            else if (string.Equals(entry.replacePolicy, GenericDependencyPolicy, StringComparison.Ordinal))
            {
                if (!entry.owner.StartsWith("upstream:", StringComparison.OrdinalIgnoreCase))
                {
                    throw new InvalidDataException("Generic dependency ownership is not attributed to upstream at: " + relative);
                }
            }
            else
            {
                throw new InvalidDataException("Unsupported replacement/uninstall policy for: " + relative);
            }
        }

        private static bool IsAllowedBiologyOwnedPath(string relative)
        {
            string normalized = relative.Replace('/', '\\');
            if (BiologyOwnedRootFiles.Contains(normalized))
            {
                return true;
            }
            foreach (string prefix in BiologyOwnedPrefixes)
            {
                if (normalized.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }
            }
            return false;
        }
    }

    public static class BiologyUninstallExecutor
    {
        private static readonly HashSet<string> SharedRootNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "archive", "bin", "engine", "r6", "red4ext", "mods", "LICENSES"
        };

        public static BiologyExecutionResult Execute(BiologyUninstallPlan plan, BiologyExecutionOptions options)
        {
            if (plan == null) throw new ArgumentNullException("plan");
            if (options == null) options = new BiologyExecutionOptions();
            BiologyExecutionResult result = new BiologyExecutionResult();
            HashSet<string> parentCandidates = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            foreach (BiologyPlanItem item in plan.Items)
            {
                if (item.Action == BiologyPlanAction.PreserveGenericDependency)
                {
                    result.PreservedGeneric.Add(item.Entry.path + " — " + item.Reason);
                    continue;
                }
                if (item.Action == BiologyPlanAction.PreserveChangedBiologyOwned)
                {
                    result.PreservedChanged.Add(item.Entry.path + " — " + item.Reason);
                    continue;
                }
                if (item.Action == BiologyPlanAction.Missing)
                {
                    result.Missing.Add(item.Entry.path);
                    continue;
                }

                try
                {
                    if (!File.Exists(item.FullPath))
                    {
                        result.Missing.Add(item.Entry.path);
                        continue;
                    }
                    string current = BiologyUninstallPlanner.ComputeSha256(item.FullPath);
                    if (!string.Equals(current, item.Entry.sha256, StringComparison.OrdinalIgnoreCase))
                    {
                        result.PreservedChanged.Add(item.Entry.path + " — changed after uninstall planning; deletion refused");
                        continue;
                    }
                    File.Delete(item.FullPath);
                    result.Deleted.Add(item.Entry.path);
                    string parent = Path.GetDirectoryName(item.FullPath);
                    if (!string.IsNullOrEmpty(parent)) parentCandidates.Add(parent);
                }
                catch (Exception ex)
                {
                    result.Errors.Add(item.Entry.path + " — " + ex.Message);
                }
            }

            // Biology's only public preference is persisted inside Cyberpunk save
            // state. The uninstaller never targets saves, so no provider-specific
            // settings-file mutation is needed or permitted here.
            result.Notes.Add("Cyberpunk saves and save-backed Biology preference/state were not targeted.");

            bool canRemoveReceipt = result.PreservedChanged.Count == 0 && result.Errors.Count == 0;
            if (canRemoveReceipt)
            {
                try
                {
                    if (File.Exists(plan.ManifestPath))
                    {
                        string currentReceiptHash = BiologyUninstallPlanner.ComputeSha256(plan.ManifestPath);
                        if (string.Equals(currentReceiptHash, plan.ManifestSha256, StringComparison.OrdinalIgnoreCase))
                        {
                            File.Delete(plan.ManifestPath);
                            result.ReceiptDeleted = true;
                            string parent = Path.GetDirectoryName(plan.ManifestPath);
                            if (!string.IsNullOrEmpty(parent)) parentCandidates.Add(parent);
                        }
                        else
                        {
                            result.Errors.Add("biology/build-manifest.json changed while uninstall was running; receipt preserved.");
                        }
                    }
                }
                catch (Exception ex)
                {
                    result.Errors.Add("biology/build-manifest.json — " + ex.Message);
                }
            }
            else
            {
                result.Notes.Add("Ownership receipt preserved because changed/failed Biology-owned files remain.");
            }

            RemoveOnlyEmptyOwnedParents(plan.GameRoot, parentCandidates, result);

            if (!options.SkipRedmodRefresh)
            {
                result.RedmodRefresh = BiologyRedmodRefresher.Refresh(plan.GameRoot);
                if (!result.RedmodRefresh.Succeeded)
                {
                    result.Errors.Add("REDmod refresh did not complete safely: " + result.RedmodRefresh.Outcome);
                }
            }
            return result;
        }

        private static void RemoveOnlyEmptyOwnedParents(string gameRoot, IEnumerable<string> starts, BiologyExecutionResult result)
        {
            string root = Path.GetFullPath(gameRoot).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            foreach (string start in starts.OrderByDescending(x => x.Length))
            {
                string dir = start;
                while (!string.IsNullOrEmpty(dir) && !string.Equals(dir, root, StringComparison.OrdinalIgnoreCase))
                {
                    if (!IsBiologyOwnedDirectory(root, dir)) break;
                    string parent = Path.GetDirectoryName(dir);
                    string name = Path.GetFileName(dir.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar));
                    if (SharedRootNames.Contains(name) && string.Equals(parent, root, StringComparison.OrdinalIgnoreCase))
                    {
                        break;
                    }
                    if (!Directory.Exists(dir)) break;
                    if (Directory.EnumerateFileSystemEntries(dir).Any()) break;
                    try
                    {
                        Directory.Delete(dir, false);
                    }
                    catch (Exception ex)
                    {
                        result.Notes.Add("Empty directory retained: " + dir + " — " + ex.Message);
                        break;
                    }
                    dir = parent;
                }
            }
        }

        private static bool IsBiologyOwnedDirectory(string gameRoot, string directory)
        {
            string root = Path.GetFullPath(gameRoot).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            string full = Path.GetFullPath(directory).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            string[] owned = new[]
            {
                Path.Combine(root, "mods", "Biology"),
                Path.Combine(root, "r6", "scripts", "CyberpunkRealism"),
                Path.Combine(root, "biology")
            };
            foreach (string candidate in owned)
            {
                string normalized = Path.GetFullPath(candidate).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
                if (string.Equals(full, normalized, StringComparison.OrdinalIgnoreCase) ||
                    full.StartsWith(normalized + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }
            }
            return false;
        }
    }

    public static class BiologyRedmodRefresher
    {
        public static RedmodRefreshResult Refresh(string gameRoot)
        {
            RedmodRefreshResult result = new RedmodRefreshResult();
            result.OtherRedmodCount = CountOtherRedmods(gameRoot);
            string redmod = Path.Combine(gameRoot, "tools", "redmod", "bin", "redMod.exe");
            if (!File.Exists(redmod))
            {
                result.Outcome = "Official REDmod executable is missing; shared REDmod caches were deliberately not deleted.";
                return result;
            }

            result.Attempted = true;
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = redmod;
                psi.WorkingDirectory = Path.GetDirectoryName(redmod);
                psi.UseShellExecute = false;
                psi.CreateNoWindow = true;
                psi.RedirectStandardOutput = true;
                psi.RedirectStandardError = true;
                psi.Arguments = "deploy -root=\"" + gameRoot.Replace("\"", "\\\"") + "\"";
                using (Process process = Process.Start(psi))
                {
                    string stdout = process.StandardOutput.ReadToEnd();
                    string stderr = process.StandardError.ReadToEnd();
                    process.WaitForExit();
                    result.ExitCode = process.ExitCode;
                    result.Output = (stdout + Environment.NewLine + stderr).Trim();
                }
            }
            catch (Exception ex)
            {
                result.Outcome = "Could not run official REDmod deploy: " + ex.Message;
                return result;
            }

            string reason;
            result.Succeeded = EvaluateRefresh(result.ExitCode, result.Output, result.OtherRedmodCount, out reason);
            result.Outcome = reason;
            return result;
        }

        public static bool EvaluateRefresh(int exitCode, string output, int otherRedmods, out string reason)
        {
            string text = output ?? string.Empty;
            if (exitCode != 0)
            {
                reason = "REDmod deploy exited with " + exitCode.ToString(CultureInfo.InvariantCulture) + ".";
                return false;
            }
            if (Regex.IsMatch(text, "No root specified|Invalid root path found", RegexOptions.IgnoreCase | RegexOptions.Multiline))
            {
                reason = "REDmod did not consume the explicit game root.";
                return false;
            }
            bool deployed = Regex.IsMatch(text, "\\[DEPLOY\\]", RegexOptions.IgnoreCase | RegexOptions.Multiline) &&
                            Regex.IsMatch(text, "Commandlet deploy has succeeded", RegexOptions.IgnoreCase | RegexOptions.Multiline);
            bool noMods = Regex.IsMatch(text, "No mods found, no deployment is needed", RegexOptions.IgnoreCase | RegexOptions.Multiline);
            if (otherRedmods > 0)
            {
                if (!deployed)
                {
                    reason = "Other REDmods remain installed, but REDmod did not report a completed deploy stage.";
                    return false;
                }
                reason = "Official REDmod redeployed the remaining REDmods without Biology.";
                return true;
            }
            if (deployed)
            {
                reason = "Official REDmod completed a deploy after Biology removal.";
                return true;
            }
            if (noMods)
            {
                reason = "Official REDmod reports no installed REDmods remain; shared modded cache was not recursively deleted.";
                return true;
            }
            reason = "REDmod returned success without recognized deploy/no-mod evidence.";
            return false;
        }

        public static int CountOtherRedmods(string gameRoot)
        {
            string mods = Path.Combine(gameRoot, "mods");
            if (!Directory.Exists(mods)) return 0;
            int count = 0;
            foreach (string dir in Directory.GetDirectories(mods))
            {
                if (string.Equals(Path.GetFileName(dir), "Biology", StringComparison.OrdinalIgnoreCase)) continue;
                if (File.Exists(Path.Combine(dir, "info.json"))) count++;
            }
            return count;
        }
    }
}