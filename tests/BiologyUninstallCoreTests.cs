using System;
using System.IO;
using System.Text;
using System.Web.Script.Serialization;
using BiologyUninstall;

internal static class BiologyUninstallCoreTests
{
    private static int checks;

    private static void Main()
    {
        string root = Path.Combine(Path.GetTempPath(), "Biology-Uninstall-Tests-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(root);
        try
        {
            TestHappyPlanAndExecution(Path.Combine(root, "happy"));
            TestChangedBiologyIsPreserved(Path.Combine(root, "changed"));
            TestChangedGenericDependencyIsPreserved(Path.Combine(root, "changed-generic"));
            TestTimeOfCheckChangeIsPreserved(Path.Combine(root, "toctou"));
            TestMissingBiologyIsReported(Path.Combine(root, "missing"));
            TestUnsafeReceiptPaths(Path.Combine(root, "unsafe"));
            TestDuplicateAndIdentityFailures(Path.Combine(root, "identity"));
            TestMalformedManifestFailures(Path.Combine(root, "malformed"));
            TestBiologyOwnedAllowlist(Path.Combine(root, "allowlist"));
            TestSaveBackedPreferencePolicy(Path.Combine(root, "save-policy"));
            TestRedmodRefreshEvaluation();
            Console.WriteLine("PASS: " + checks + " Biology uninstall planner/executor safety checks.");
        }
        finally
        {
            try { Directory.Delete(root, true); } catch { }
        }
    }

    private static void TestHappyPlanAndExecution(string root)
    {
        PrepareGameRoot(root);
        string owned = WriteFile(root, "r6/scripts/CyberpunkRealism/TestOwned.reds", "owned-v1");
        string generic = WriteFile(root, "engine/tools/scc.exe", "generic-v1");
        string otherMod = WriteFile(root, "r6/scripts/OtherMod/Keep.reds", "keep-me");
        string saveOutside = Path.Combine(Path.GetDirectoryName(root), "player-save.sav");
        File.WriteAllText(saveOutside, "save-must-live");

        BiologyManifestFile ownedEntry = Entry("r6/scripts/CyberpunkRealism/TestOwned.reds", owned, "Biology", "biology-owned-runtime", BiologyUninstallPlanner.BiologyOwnedPolicy);
        BiologyManifestFile genericEntry = Entry("engine/tools/scc.exe", generic, "upstream:redscript", "redscript", BiologyUninstallPlanner.GenericDependencyPolicy);
        string manifestPath = WriteManifest(root, new[] { ownedEntry, genericEntry }, "Biology");

        BiologyUninstallPlan plan = BiologyUninstallPlanner.Build(root, manifestPath);
        Check(plan.Count(BiologyPlanAction.DeleteBiologyOwned) == 1, "happy plan did not authorize the exact Biology-owned file");
        Check(plan.Count(BiologyPlanAction.PreserveGenericDependency) == 1, "happy plan did not preserve exact generic dependency");

        BiologyExecutionResult result = BiologyUninstallExecutor.Execute(plan, new BiologyExecutionOptions { SkipRedmodRefresh = true });
        Check(!File.Exists(owned), "exact Biology-owned file survived happy uninstall");
        Check(File.Exists(generic), "generic dependency was deleted by player uninstall");
        Check(File.Exists(otherMod), "another mod under shared r6/scripts was deleted");
        Check(File.Exists(saveOutside) && File.ReadAllText(saveOutside) == "save-must-live", "save outside game root was touched");
        Check(!Directory.Exists(Path.Combine(root, "r6", "scripts", "CyberpunkRealism")), "empty Biology-owned script directory was not removed");
        Check(Directory.Exists(Path.Combine(root, "r6", "scripts")), "shared r6/scripts directory was removed");
        Check(result.ReceiptDeleted && !File.Exists(manifestPath), "clean uninstall did not remove the validated ownership receipt");
        Check(result.Notes.Exists(x => x.IndexOf("save-backed Biology preference", StringComparison.OrdinalIgnoreCase) >= 0), "uninstaller did not report save-backed preference preservation");
    }

    private static void TestChangedBiologyIsPreserved(string root)
    {
        PrepareGameRoot(root);
        string owned = WriteFile(root, "mods/Biology/info.json", "packaged");
        BiologyManifestFile entry = Entry("mods/Biology/info.json", owned, "Biology", "biology-redmod-identity", BiologyUninstallPlanner.BiologyOwnedPolicy);
        string manifestPath = WriteManifest(root, new[] { entry }, "Biology");
        File.WriteAllText(owned, "player-or-third-party-changed");

        BiologyUninstallPlan plan = BiologyUninstallPlanner.Build(root, manifestPath);
        Check(plan.Count(BiologyPlanAction.PreserveChangedBiologyOwned) == 1, "changed Biology file was not classified preserve");
        BiologyExecutionResult result = BiologyUninstallExecutor.Execute(plan, new BiologyExecutionOptions { SkipRedmodRefresh = true });
        Check(File.Exists(owned), "changed Biology file was automatically deleted");
        Check(File.Exists(manifestPath) && !result.ReceiptDeleted, "ownership receipt was deleted while a changed Biology file remains");
    }

    private static void TestChangedGenericDependencyIsPreserved(string root)
    {
        PrepareGameRoot(root);
        string generic = WriteFile(root, "engine/tools/scc.exe", "packaged-generic");
        BiologyManifestFile entry = Entry("engine/tools/scc.exe", generic, "upstream:redscript", "redscript", BiologyUninstallPlanner.GenericDependencyPolicy);
        string manifestPath = WriteManifest(root, new[] { entry }, "Biology");
        File.WriteAllText(generic, "updated-by-another-mod");

        BiologyUninstallPlan plan = BiologyUninstallPlanner.Build(root, manifestPath);
        Check(plan.Count(BiologyPlanAction.PreserveGenericDependency) == 1, "changed generic dependency was not classified preserve");
        BiologyExecutionResult result = BiologyUninstallExecutor.Execute(plan, new BiologyExecutionOptions { SkipRedmodRefresh = true });
        Check(File.Exists(generic) && File.ReadAllText(generic) == "updated-by-another-mod", "changed generic dependency was altered/deleted");
        Check(result.PreservedGeneric.Count == 1, "changed generic dependency was not reported as preserved");
    }

    private static void TestTimeOfCheckChangeIsPreserved(string root)
    {
        PrepareGameRoot(root);
        string owned = WriteFile(root, "r6/scripts/CyberpunkRealism/Race.reds", "packaged");
        BiologyManifestFile entry = Entry("r6/scripts/CyberpunkRealism/Race.reds", owned, "Biology", "biology-owned-runtime", BiologyUninstallPlanner.BiologyOwnedPolicy);
        string manifestPath = WriteManifest(root, new[] { entry }, "Biology");
        BiologyUninstallPlan plan = BiologyUninstallPlanner.Build(root, manifestPath);
        File.WriteAllText(owned, "changed-after-plan");
        BiologyExecutionResult result = BiologyUninstallExecutor.Execute(plan, new BiologyExecutionOptions { SkipRedmodRefresh = true });
        Check(File.Exists(owned), "file changed after planning was deleted");
        Check(result.PreservedChanged.Count == 1, "TOCTOU change was not reported as preserved");
        Check(File.Exists(manifestPath), "receipt was deleted after TOCTOU preservation");
    }

    private static void TestMissingBiologyIsReported(string root)
    {
        PrepareGameRoot(root);
        string owned = WriteFile(root, "r6/scripts/CyberpunkRealism/Missing.reds", "packaged");
        BiologyManifestFile entry = Entry("r6/scripts/CyberpunkRealism/Missing.reds", owned, "Biology", "biology-owned-runtime", BiologyUninstallPlanner.BiologyOwnedPolicy);
        string manifestPath = WriteManifest(root, new[] { entry }, "Biology");
        File.Delete(owned);
        BiologyUninstallPlan plan = BiologyUninstallPlanner.Build(root, manifestPath);
        Check(plan.Count(BiologyPlanAction.Missing) == 1, "missing Biology file was not reported");
    }

    private static void TestUnsafeReceiptPaths(string root)
    {
        string[] unsafePaths = new[]
        {
            "../outside.txt",
            "r6/scripts/../outside.txt",
            "C:\\Windows\\system.ini",
            "\\\\server\\share\\payload.bin",
            "r6//scripts/CyberpunkRealism/file.reds",
            "r6/scripts/./CyberpunkRealism/file.reds",
            "r6/scripts/CyberpunkRealism/file.reds:stream",
            ""
        };
        int index = 0;
        foreach (string unsafePath in unsafePaths)
        {
            string caseRoot = Path.Combine(root, "case-" + index++);
            PrepareGameRoot(caseRoot);
            BiologyManifestFile entry = new BiologyManifestFile
            {
                path = unsafePath,
                sha256 = new string('A', 64),
                owner = "Biology",
                component = "test",
                route = "test",
                replacePolicy = BiologyUninstallPlanner.BiologyOwnedPolicy
            };
            string manifestPath = WriteManifest(caseRoot, new[] { entry }, "Biology");
            ExpectFailure(delegate { BiologyUninstallPlanner.Build(caseRoot, manifestPath); }, "unsafe path accepted: " + unsafePath);
        }
    }

    private static void TestDuplicateAndIdentityFailures(string root)
    {
        PrepareGameRoot(root);
        string first = WriteFile(root, "mods/Biology/info.json", "x");
        BiologyManifestFile a = Entry("mods/Biology/info.json", first, "Biology", "id", BiologyUninstallPlanner.BiologyOwnedPolicy);
        BiologyManifestFile b = Entry("MODS/biology/INFO.JSON", first, "Biology", "id", BiologyUninstallPlanner.BiologyOwnedPolicy);
        string manifestPath = WriteManifest(root, new[] { a, b }, "Biology");
        ExpectFailure(delegate { BiologyUninstallPlanner.Build(root, manifestPath); }, "case-insensitive duplicate path accepted");

        string wrongRoot = Path.Combine(Path.GetDirectoryName(root), "wrong-product");
        PrepareGameRoot(wrongRoot);
        string wrong = WriteFile(wrongRoot, "mods/Biology/info.json", "x");
        string wrongManifest = WriteManifest(wrongRoot, new[] { Entry("mods/Biology/info.json", wrong, "Biology", "id", BiologyUninstallPlanner.BiologyOwnedPolicy) }, "NotBiology");
        ExpectFailure(delegate { BiologyUninstallPlanner.Build(wrongRoot, wrongManifest); }, "unexpected product identity accepted");
    }

    private static void TestMalformedManifestFailures(string root)
    {
        PrepareGameRoot(root);
        string owned = WriteFile(root, "mods/Biology/info.json", "x");
        string manifestPath = WriteManifest(root, new[] { Entry("mods/Biology/info.json", owned, "Biology", "id", BiologyUninstallPlanner.BiologyOwnedPolicy) }, "Biology");
        JavaScriptSerializer serializer = new JavaScriptSerializer();
        BiologyManifest manifest = serializer.Deserialize<BiologyManifest>(File.ReadAllText(manifestPath));
        manifest.schemaVersion = 99;
        File.WriteAllText(manifestPath, serializer.Serialize(manifest), new UTF8Encoding(false));
        ExpectFailure(delegate { BiologyUninstallPlanner.Build(root, manifestPath); }, "unsupported ownership receipt schema accepted");

        string policyRoot = Path.Combine(Path.GetDirectoryName(root), "bad-policy");
        PrepareGameRoot(policyRoot);
        string policyOwned = WriteFile(policyRoot, "mods/Biology/info.json", "x");
        string policyManifestPath = WriteManifest(policyRoot, new[] { Entry("mods/Biology/info.json", policyOwned, "Biology", "id", BiologyUninstallPlanner.BiologyOwnedPolicy) }, "Biology");
        BiologyManifest policyManifest = serializer.Deserialize<BiologyManifest>(File.ReadAllText(policyManifestPath));
        policyManifest.uninstall.genericDependencyPolicy = "delete";
        File.WriteAllText(policyManifestPath, serializer.Serialize(policyManifest), new UTF8Encoding(false));
        ExpectFailure(delegate { BiologyUninstallPlanner.Build(policyRoot, policyManifestPath); }, "unexpected uninstall policy accepted");
    }

    private static void TestBiologyOwnedAllowlist(string root)
    {
        PrepareGameRoot(root);
        string gameExe = Path.Combine(root, "bin", "x64", "Cyberpunk2077.exe");
        BiologyManifestFile malicious = Entry("bin/x64/Cyberpunk2077.exe", gameExe, "Biology", "fake", BiologyUninstallPlanner.BiologyOwnedPolicy);
        string manifestPath = WriteManifest(root, new[] { malicious }, "Biology");
        ExpectFailure(delegate { BiologyUninstallPlanner.Build(root, manifestPath); }, "receipt was allowed to claim a game/shared-root executable as Biology-owned");

        string genericRoot = Path.Combine(Path.GetDirectoryName(root), "generic-owner");
        PrepareGameRoot(genericRoot);
        string generic = WriteFile(genericRoot, "engine/tools/scc.exe", "generic");
        BiologyManifestFile wrongOwner = Entry("engine/tools/scc.exe", generic, "Biology", "redscript", BiologyUninstallPlanner.GenericDependencyPolicy);
        string wrongManifest = WriteManifest(genericRoot, new[] { wrongOwner }, "Biology");
        ExpectFailure(delegate { BiologyUninstallPlanner.Build(genericRoot, wrongManifest); }, "generic dependency without upstream ownership accepted");
    }

    private static void TestSaveBackedPreferencePolicy(string root)
    {
        PrepareGameRoot(root);
        string owned = WriteFile(root, "mods/Biology/info.json", "owned");
        string manifestPath = WriteManifest(root, new[] { Entry("mods/Biology/info.json", owned, "Biology", "id", BiologyUninstallPlanner.BiologyOwnedPolicy) }, "Biology");
        BiologyUninstallPlan plan = BiologyUninstallPlanner.Build(root, manifestPath);
        Check(plan.Manifest.uninstall.savePolicy == "never-target", "ownership receipt lost save safety policy");
        Check(plan.Manifest.uninstall.preferencePolicy == "stored-in-save-never-target", "ownership receipt lost save-backed preference policy");

        JavaScriptSerializer serializer = new JavaScriptSerializer();
        BiologyManifest manifest = serializer.Deserialize<BiologyManifest>(File.ReadAllText(manifestPath));
        manifest.uninstall.preferencePolicy = "delete-provider-file";
        File.WriteAllText(manifestPath, serializer.Serialize(manifest), new UTF8Encoding(false));
        ExpectFailure(delegate { BiologyUninstallPlanner.Build(root, manifestPath); }, "provider-specific preference deletion policy was accepted");
    }

    private static void TestRedmodRefreshEvaluation()
    {
        string reason;
        Check(BiologyRedmodRefresher.EvaluateRefresh(0, "[DEPLOY]\r\nCommandlet deploy has succeeded", 2, out reason), "remaining-REDmod deploy success was rejected");
        Check(!BiologyRedmodRefresher.EvaluateRefresh(0, "No mods found, no deployment is needed", 2, out reason), "no-mod result was accepted while other REDmods remain");
        Check(BiologyRedmodRefresher.EvaluateRefresh(0, "No mods found, no deployment is needed", 0, out reason), "empty REDmod state was rejected when Biology was the only REDmod");
        Check(!BiologyRedmodRefresher.EvaluateRefresh(0, "Invalid root path found", 0, out reason), "bad explicit-root signal was accepted");
        Check(!BiologyRedmodRefresher.EvaluateRefresh(5, "[DEPLOY] Commandlet deploy has succeeded", 0, out reason), "nonzero REDmod exit code was accepted");
    }

    private static void PrepareGameRoot(string root)
    {
        Directory.CreateDirectory(Path.Combine(root, "bin", "x64"));
        Directory.CreateDirectory(Path.Combine(root, "r6"));
        File.WriteAllText(Path.Combine(root, "bin", "x64", "Cyberpunk2077.exe"), "fixture");
    }

    private static string WriteFile(string root, string relative, string content)
    {
        string full = Path.Combine(root, relative.Replace('/', Path.DirectorySeparatorChar));
        Directory.CreateDirectory(Path.GetDirectoryName(full));
        File.WriteAllText(full, content, new UTF8Encoding(false));
        return full;
    }

    private static BiologyManifestFile Entry(string relative, string fullPath, string owner, string component, string policy)
    {
        return new BiologyManifestFile
        {
            path = relative,
            sha256 = BiologyUninstallPlanner.ComputeSha256(fullPath),
            owner = owner,
            component = component,
            route = "TEST",
            replacePolicy = policy
        };
    }

    private static string WriteManifest(string root, BiologyManifestFile[] files, string product)
    {
        BiologyManifest manifest = new BiologyManifest
        {
            schemaVersion = 2,
            product = product,
            buildId = "test-build",
            version = "test-version",
            gameVersion = "2.31",
            sourceRevision = new string('0', 40),
            playableRuntimeIncluded = true,
            officialPackageRoot = "mods/Biology",
            files = files,
            uninstall = new BiologyUninstallContract
            {
                schemaVersion = 2,
                playerBinary = "Uninstall Biology.exe",
                biologyOwnedPolicy = "biology-owned",
                genericDependencyPolicy = "preserve",
                savePolicy = "never-target",
                preferencePolicy = "stored-in-save-never-target",
                redmodRefresh = "official-redmod-deploy-explicit-root"
            }
        };
        string path = Path.Combine(root, "biology", "build-manifest.json");
        Directory.CreateDirectory(Path.GetDirectoryName(path));
        File.WriteAllText(path, new JavaScriptSerializer().Serialize(manifest), new UTF8Encoding(false));
        return path;
    }

    private static void ExpectFailure(Action action, string message)
    {
        bool failed = false;
        try { action(); }
        catch { failed = true; }
        Check(failed, message);
    }

    private static void Check(bool condition, string message)
    {
        if (!condition) throw new Exception("FAIL: " + message);
        checks++;
    }
}
