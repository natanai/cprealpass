using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using BiologyUninstall;

internal static class BiologyPriorInstallTransitionProgram
{
    private static int Main(string[] args)
    {
        string gameRoot = GetArgument(args, "--game-root=");
        string reportPath = GetArgument(args, "--report=");
        List<string> report = new List<string>();
        bool mutationStarted = false;
        BiologyUninstallPlan plan = null;
        BiologyExecutionResult result = null;
        int exitCode = 1;

        report.Add("BIOLOGY PRIOR-INSTALL REPLACEMENT TRANSITION");
        report.Add("Started: " + DateTime.UtcNow.ToString("o"));

        try
        {
            if (string.IsNullOrWhiteSpace(gameRoot))
            {
                throw new InvalidDataException("--game-root is required for prior-install transition.");
            }
            if (string.IsNullOrWhiteSpace(reportPath))
            {
                throw new InvalidDataException("--report is required for prior-install transition.");
            }

            gameRoot = BiologyUninstallPlanner.ValidateGameRoot(gameRoot);
            reportPath = Path.GetFullPath(reportPath);
            EnsureGameStopped();

            string manifestPath = Path.Combine(gameRoot, "biology", "build-manifest.json");
            plan = BiologyUninstallPlanner.Build(gameRoot, manifestPath);
            report.Add("Game root: " + gameRoot);
            report.Add("Prior build ID: " + (plan.Manifest.buildId ?? string.Empty));
            report.Add("Prior source revision: " + (plan.Manifest.sourceRevision ?? string.Empty));
            report.Add("Biology-owned exact deletions planned: " + plan.Count(BiologyPlanAction.DeleteBiologyOwned));
            report.Add("Biology-owned changed files detected: " + plan.Count(BiologyPlanAction.PreserveChangedBiologyOwned));
            report.Add("Shared dependencies preserved: " + plan.Count(BiologyPlanAction.PreserveGenericDependency));
            report.Add("Already-missing receipt entries: " + plan.Count(BiologyPlanAction.Missing));

            AssertReplacementPreflight(plan);
            report.Add("Replacement transition preflight: PASS");
            report.Add("All receipt-owned Biology files were revalidated before mutation; shared dependencies remain preserve-only.");

            mutationStarted = true;
            result = BiologyUninstallExecutor.Execute(plan, new BiologyExecutionOptions { SkipRedmodRefresh = true });
            AppendExecution(report, result);

            if (result.PreservedChanged.Count != 0 || result.Errors.Count != 0 || !result.ReceiptDeleted)
            {
                throw new InvalidDataException("Prior Biology candidate could not be retired completely after the final pre-mutation revalidation.");
            }

            foreach (BiologyPlanItem item in plan.Items.Where(x => string.Equals(x.Entry.replacePolicy, BiologyUninstallPlanner.BiologyOwnedPolicy, StringComparison.Ordinal)))
            {
                if (File.Exists(item.FullPath))
                {
                    throw new InvalidDataException("Receipt-owned Biology file remained after replacement transition: " + item.Entry.path);
                }
            }
            if (File.Exists(plan.ManifestPath))
            {
                throw new InvalidDataException("Biology ownership receipt remained after replacement transition.");
            }

            report.Add("RESULT: PASS");
            report.Add("The prior schema-2 Biology candidate was retired through the same hash/path-bounded uninstaller core used by the player uninstaller.");
            report.Add("REDmod refresh intentionally skipped because the exact replacement candidate is installed/deployed by the same attended preparation session.");
            exitCode = 0;
        }
        catch (Exception ex)
        {
            report.Add("RESULT: " + (mutationStarted ? "PARTIAL" : "FAIL-CLOSED"));
            report.Add("Exception type: " + ex.GetType().FullName);
            report.Add("Error: " + ex.Message);
            if (!mutationStarted)
            {
                report.Add("No game mutation began; the prior installed Biology candidate was preserved.");
            }
            else
            {
                report.Add("Mutation began only after complete receipt/hash preflight. Exact execution details above define the bounded partial state; do not improvise cleanup.");
            }
        }
        finally
        {
            report.Add("Game mutation started: " + mutationStarted);
            report.Add("Completed: " + DateTime.UtcNow.ToString("o"));
            if (!string.IsNullOrWhiteSpace(reportPath))
            {
                try
                {
                    string fullReport = Path.GetFullPath(reportPath);
                    string parent = Path.GetDirectoryName(fullReport);
                    if (!string.IsNullOrEmpty(parent)) Directory.CreateDirectory(parent);
                    File.WriteAllLines(fullReport, report.ToArray(), new UTF8Encoding(false));
                }
                catch
                {
                    // The caller still receives the nonzero process result. Never
                    // broaden game mutation because diagnostic report writing failed.
                    if (exitCode == 0) exitCode = 1;
                }
            }
        }

        return exitCode;
    }

    private static void AssertReplacementPreflight(BiologyUninstallPlan plan)
    {
        if (plan == null) throw new ArgumentNullException("plan");
        if (plan.Count(BiologyPlanAction.PreserveChangedBiologyOwned) != 0)
        {
            throw new InvalidDataException("Prior Biology candidate contains changed Biology-owned files; replacement transition refused before mutation.");
        }
        if (!File.Exists(plan.ManifestPath) ||
            !string.Equals(BiologyUninstallPlanner.ComputeSha256(plan.ManifestPath), plan.ManifestSha256, StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidDataException("Prior Biology ownership receipt changed after planning; replacement transition refused before mutation.");
        }

        foreach (BiologyPlanItem item in plan.Items)
        {
            if (item.Action == BiologyPlanAction.PreserveGenericDependency) continue;
            if (item.Action == BiologyPlanAction.PreserveChangedBiologyOwned)
            {
                throw new InvalidDataException("Changed Biology-owned content reached replacement preflight: " + item.Entry.path);
            }
            if (item.Action == BiologyPlanAction.Missing)
            {
                if (File.Exists(item.FullPath))
                {
                    throw new InvalidDataException("A previously missing Biology-owned path appeared after planning: " + item.Entry.path);
                }
                continue;
            }
            if (!File.Exists(item.FullPath))
            {
                throw new InvalidDataException("A Biology-owned path disappeared after planning: " + item.Entry.path);
            }
            FileAttributes attributes = File.GetAttributes(item.FullPath);
            if ((attributes & FileAttributes.ReparsePoint) != 0)
            {
                throw new InvalidDataException("Replacement transition refuses a Biology-owned reparse-point file: " + item.Entry.path);
            }
            string current = BiologyUninstallPlanner.ComputeSha256(item.FullPath);
            if (!string.Equals(current, item.Entry.sha256, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidDataException("Biology-owned content changed after planning; replacement transition refused before mutation: " + item.Entry.path);
            }
        }

        AssertNoUntrackedOwnedNamespaceContent(plan);
    }

    private static void AssertNoUntrackedOwnedNamespaceContent(BiologyUninstallPlan plan)
    {
        Dictionary<string, BiologyManifestFile> inventoried = new Dictionary<string, BiologyManifestFile>(StringComparer.OrdinalIgnoreCase);
        foreach (BiologyManifestFile entry in plan.Manifest.files)
        {
            inventoried[BiologyUninstallPlanner.NormalizeRelativePath(entry.path)] = entry;
        }
        inventoried[BiologyUninstallPlanner.NormalizeRelativePath(BiologyUninstallPlanner.ManifestRelativePath)] = null;

        string[] roots = new[]
        {
            "mods\\Biology",
            "r6\\scripts\\CyberpunkRealism",
            "biology"
        };
        foreach (string relativeRoot in roots)
        {
            string fullRoot = BiologyUninstallPlanner.ResolveSafeChildPath(plan.GameRoot, relativeRoot);
            if (!Directory.Exists(fullRoot)) continue;
            DirectoryInfo rootInfo = new DirectoryInfo(fullRoot);
            if ((rootInfo.Attributes & FileAttributes.ReparsePoint) != 0)
            {
                throw new InvalidDataException("Replacement transition refuses a Biology-owned reparse-point directory: " + relativeRoot);
            }

            Stack<DirectoryInfo> pending = new Stack<DirectoryInfo>();
            pending.Push(rootInfo);
            while (pending.Count > 0)
            {
                DirectoryInfo directory = pending.Pop();
                foreach (FileSystemInfo entry in directory.GetFileSystemInfos())
                {
                    if ((entry.Attributes & FileAttributes.ReparsePoint) != 0)
                    {
                        throw new InvalidDataException("Replacement transition refuses reparse-point content inside Biology-owned namespace: " + entry.FullName);
                    }
                    DirectoryInfo childDirectory = entry as DirectoryInfo;
                    if (childDirectory != null)
                    {
                        pending.Push(childDirectory);
                        continue;
                    }

                    string rootPrefix = plan.GameRoot.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar) + Path.DirectorySeparatorChar;
                    string relative = entry.FullName.Substring(rootPrefix.Length);
                    string normalized = BiologyUninstallPlanner.NormalizeRelativePath(relative);
                    BiologyManifestFile manifestEntry;
                    if (!inventoried.TryGetValue(normalized, out manifestEntry))
                    {
                        throw new InvalidDataException("Replacement transition found untracked content inside Biology-owned namespace: " + normalized);
                    }
                    if (manifestEntry != null && !string.Equals(manifestEntry.replacePolicy, BiologyUninstallPlanner.BiologyOwnedPolicy, StringComparison.Ordinal))
                    {
                        throw new InvalidDataException("Replacement transition refuses preserve-only shared content inside a Biology-owned namespace: " + normalized);
                    }
                }
            }
        }
    }

    private static void AppendExecution(List<string> report, BiologyExecutionResult result)
    {
        report.Add("Deleted Biology-owned files: " + result.Deleted.Count);
        report.Add("Preserved changed Biology-owned files: " + result.PreservedChanged.Count);
        report.Add("Preserved generic/shared dependency files: " + result.PreservedGeneric.Count);
        report.Add("Already missing: " + result.Missing.Count);
        report.Add("Execution errors: " + result.Errors.Count);
        report.Add("Ownership receipt deleted: " + result.ReceiptDeleted);
        foreach (string item in result.PreservedGeneric) report.Add("PRESERVE SHARED | " + item);
        foreach (string item in result.PreservedChanged) report.Add("PRESERVE CHANGED | " + item);
        foreach (string item in result.Errors) report.Add("ERROR | " + item);
    }

    private static void EnsureGameStopped()
    {
        Process[] processes = Process.GetProcessesByName("Cyberpunk2077");
        try
        {
            if (processes.Length > 0)
            {
                throw new InvalidOperationException("Cyberpunk 2077 is running. Close the game completely before prior-install transition.");
            }
        }
        finally
        {
            foreach (Process process in processes) process.Dispose();
        }
    }

    private static string GetArgument(string[] args, string prefix)
    {
        foreach (string arg in args)
        {
            if (arg.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
            {
                return arg.Substring(prefix.Length).Trim('"');
            }
        }
        return null;
    }
}
