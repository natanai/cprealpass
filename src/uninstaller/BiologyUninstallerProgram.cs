using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Text;
using System.Windows.Forms;

namespace BiologyUninstall
{
    internal static class BiologyUninstallerProgram
    {
        [STAThread]
        private static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            try
            {
                bool tempMode = HasFlag(args, "--temp");
                if (!tempMode)
                {
                    RelaunchFromTemporaryCopy();
                    return;
                }

                string gameRoot = GetArgument(args, "--game-root=");
                if (string.IsNullOrWhiteSpace(gameRoot))
                {
                    throw new InvalidDataException("The temporary uninstaller did not receive the Cyberpunk 2077 game root.");
                }
                Application.Run(new BiologyUninstallForm(gameRoot));
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Biology uninstall refused", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                if (HasFlag(args, "--temp"))
                {
                    ScheduleTemporarySelfDelete(Application.ExecutablePath);
                }
            }
        }

        private static void RelaunchFromTemporaryCopy()
        {
            string executable = Application.ExecutablePath;
            string gameRoot = Path.GetDirectoryName(executable);
            BiologyUninstallPlanner.ValidateGameRoot(gameRoot);
            string expectedName = BiologyUninstallPlanner.ExpectedBinary;
            if (!string.Equals(Path.GetFileName(executable), expectedName, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidDataException("Run the packaged 'Uninstall Biology.exe' from the Cyberpunk 2077 game root.");
            }
            string manifest = Path.Combine(gameRoot, "biology", "build-manifest.json");
            BiologyUninstallPlanner.Build(gameRoot, manifest);

            string temp = Path.Combine(Path.GetTempPath(), "Biology-Uninstall-" + Guid.NewGuid().ToString("N") + ".exe");
            File.Copy(executable, temp, false);
            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = temp;
            psi.UseShellExecute = true;
            psi.Arguments = "--temp --game-root=\"" + gameRoot.Replace("\"", "\\\"") + "\"";
            Process.Start(psi);
        }

        private static void ScheduleTemporarySelfDelete(string executable)
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = Environment.GetEnvironmentVariable("ComSpec") ?? "cmd.exe";
                psi.UseShellExecute = false;
                psi.CreateNoWindow = true;
                psi.WindowStyle = ProcessWindowStyle.Hidden;
                psi.Arguments = "/c timeout /t 2 /nobreak >nul & del /f /q \"" + executable.Replace("\"", "\"\"") + "\"";
                Process.Start(psi);
            }
            catch
            {
                // The temporary copy is outside the game and carries no user data.
                // Failure to remove it must not turn a completed safe uninstall into
                // a destructive retry against the game directory.
            }
        }

        private static bool HasFlag(string[] args, string flag)
        {
            foreach (string arg in args)
            {
                if (string.Equals(arg, flag, StringComparison.OrdinalIgnoreCase)) return true;
            }
            return false;
        }

        private static string GetArgument(string[] args, string prefix)
        {
            foreach (string arg in args)
            {
                if (arg.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                {
                    return arg.Substring(prefix.Length);
                }
            }
            return null;
        }
    }

    internal sealed class BiologyUninstallForm : Form
    {
        private readonly string gameRoot;
        private BiologyUninstallPlan plan;
        private readonly Label summary;
        private readonly Button uninstall;
        private readonly Button close;
        private readonly TextBox report;

        public BiologyUninstallForm(string gameRoot)
        {
            this.gameRoot = gameRoot;
            Text = "Uninstall Biology";
            StartPosition = FormStartPosition.CenterScreen;
            MinimumSize = new Size(700, 500);
            Size = new Size(780, 580);
            Font = new Font("Segoe UI", 9F, FontStyle.Regular, GraphicsUnit.Point);

            Label title = new Label();
            title.Text = "Uninstall Biology";
            title.Font = new Font(Font.FontFamily, 16F, FontStyle.Bold);
            title.AutoSize = true;
            title.Left = 18;
            title.Top = 16;
            Controls.Add(title);

            summary = new Label();
            summary.Left = 20;
            summary.Top = 58;
            summary.Width = 730;
            summary.Height = 90;
            Controls.Add(summary);

            uninstall = new Button();
            uninstall.Text = "Remove Biology";
            uninstall.Left = 20;
            uninstall.Top = 150;
            uninstall.Width = 150;
            uninstall.Height = 34;
            uninstall.Click += OnUninstall;
            Controls.Add(uninstall);

            close = new Button();
            close.Text = "Close";
            close.Left = 180;
            close.Top = 150;
            close.Width = 100;
            close.Height = 34;
            close.Click += delegate { Close(); };
            Controls.Add(close);

            report = new TextBox();
            report.Left = 20;
            report.Top = 200;
            report.Width = 730;
            report.Height = 330;
            report.Multiline = true;
            report.ReadOnly = true;
            report.ScrollBars = ScrollBars.Vertical;
            report.Font = new Font("Consolas", 9F, FontStyle.Regular, GraphicsUnit.Point);
            report.Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right;
            Controls.Add(report);

            Load += OnLoaded;
        }

        private void OnLoaded(object sender, EventArgs e)
        {
            try
            {
                EnsureGameStopped();
                string manifest = Path.Combine(gameRoot, "biology", "build-manifest.json");
                plan = BiologyUninstallPlanner.Build(gameRoot, manifest);
                summary.Text = string.Format(
                    "Build: {0}\r\nBiology-owned files ready to remove: {1}   Changed Biology files preserved: {2}\r\nGeneric/shared dependency files preserved: {3}   Already missing: {4}",
                    string.IsNullOrWhiteSpace(plan.Manifest.version) ? plan.Manifest.buildId : plan.Manifest.version,
                    plan.Count(BiologyPlanAction.DeleteBiologyOwned),
                    plan.Count(BiologyPlanAction.PreserveChangedBiologyOwned),
                    plan.Count(BiologyPlanAction.PreserveGenericDependency),
                    plan.Count(BiologyPlanAction.Missing));
                report.Text = BuildPlanReport(plan);
            }
            catch (Exception ex)
            {
                uninstall.Enabled = false;
                summary.Text = "Automatic uninstall was refused before any file was changed.";
                report.Text = ex.ToString();
            }
        }

        private void OnUninstall(object sender, EventArgs e)
        {
            if (plan == null) return;
            try
            {
                EnsureGameStopped();
                string warning = "Biology will remove only receipt-listed Biology-owned files whose SHA-256 still matches.\r\n\r\n" +
                                 "Changed files and generic/shared dependencies will be preserved. Saves are never touched.\r\n\r\nContinue?";
                if (MessageBox.Show(warning, "Confirm Biology uninstall", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) != DialogResult.Yes)
                {
                    return;
                }

                uninstall.Enabled = false;
                BiologyExecutionOptions options = new BiologyExecutionOptions();
                // The UI owns the final refresh decision so it can verify the Biology
                // REDmod namespace is actually gone before asking REDmod to deploy.
                // This prevents a changed/untracked partial mods/Biology package from
                // being redeployed during a conservative partial uninstall.
                options.SkipRedmodRefresh = true;
                BiologyExecutionResult result = BiologyUninstallExecutor.Execute(plan, options);
                FinalizeResidualAndRedmodState(result);
                report.Text = BuildExecutionReport(result);
                summary.Text = result.BiologyPayloadFullyRemoved
                    ? "Biology-owned payload removal finished and REDmod state was refreshed safely."
                    : "Biology was only partially removed. Changed, residual, or failed files were deliberately preserved; review the report below.";
            }
            catch (Exception ex)
            {
                report.Text += "\r\n\r\nUNINSTALL STOPPED\r\n" + ex.ToString();
                summary.Text = "Uninstall stopped safely; review the report. No recursive cleanup is attempted.";
                uninstall.Enabled = false;
            }
        }

        private void FinalizeResidualAndRedmodState(BiologyExecutionResult result)
        {
            string biologyRedmod = Path.Combine(gameRoot, "mods", "Biology");
            string biologyScripts = Path.Combine(gameRoot, "r6", "scripts", "CyberpunkRealism");
            string biologyMetadata = Path.Combine(gameRoot, "biology");

            AppendResidualDirectory(result, biologyScripts, "r6/scripts/CyberpunkRealism");
            AppendResidualDirectory(result, biologyMetadata, "biology");

            if (Directory.Exists(biologyRedmod))
            {
                AppendResidualDirectory(result, biologyRedmod, "mods/Biology");
                result.RedmodRefresh = new RedmodRefreshResult();
                result.RedmodRefresh.Attempted = false;
                result.RedmodRefresh.Succeeded = false;
                result.RedmodRefresh.OtherRedmodCount = BiologyRedmodRefresher.CountOtherRedmods(gameRoot);
                result.RedmodRefresh.Outcome = "REDmod refresh was deliberately not run because mods/Biology still contains preserved, changed, untracked, or otherwise unresolved content. Redeploying could reactivate a partial Biology package.";
                result.Errors.Add("REDmod refresh withheld because mods/Biology still exists; manual review is required before claiming Biology fully removed.");
                return;
            }

            result.RedmodRefresh = BiologyRedmodRefresher.Refresh(gameRoot);
            if (!result.RedmodRefresh.Succeeded)
            {
                result.Errors.Add("REDmod refresh did not complete safely: " + result.RedmodRefresh.Outcome);
            }
        }

        private static void AppendResidualDirectory(BiologyExecutionResult result, string fullPath, string displayPath)
        {
            if (!Directory.Exists(fullPath)) return;
            string message = "Biology-specific directory remains after exact-file removal: " + displayPath + ". Preserved or untracked content requires manual review.";
            if (!result.Errors.Contains(message)) result.Errors.Add(message);
        }

        private static void EnsureGameStopped()
        {
            Process[] processes = Process.GetProcessesByName("Cyberpunk2077");
            try
            {
                if (processes.Length > 0)
                {
                    throw new InvalidOperationException("Cyberpunk 2077 is running. Close the game completely, then run the Biology uninstaller again.");
                }
            }
            finally
            {
                foreach (Process process in processes) process.Dispose();
            }
        }

        private static string BuildPlanReport(BiologyUninstallPlan plan)
        {
            StringBuilder builder = new StringBuilder();
            builder.AppendLine("PLAN — no files changed yet");
            builder.AppendLine("Game root: " + plan.GameRoot);
            builder.AppendLine("Receipt: biology/build-manifest.json");
            builder.AppendLine();
            foreach (BiologyPlanItem item in plan.Items)
            {
                builder.AppendLine(string.Format("[{0}] {1} — {2}", item.Action, item.Entry.path, item.Reason));
            }
            builder.AppendLine();
            builder.AppendLine("Preferences: Biology's E3 preference is stored in Cyberpunk save state; saves are never targeted.");
            builder.AppendLine("Saves: never targeted.");
            builder.AppendLine("Directories: only now-empty Biology-owned directories are eligible; shared roots are never recursively deleted.");
            return builder.ToString();
        }

        private static string BuildExecutionReport(BiologyExecutionResult result)
        {
            StringBuilder builder = new StringBuilder();
            builder.AppendLine("BIOLOGY UNINSTALL REPORT");
            builder.AppendLine("Deleted Biology-owned files: " + result.Deleted.Count);
            builder.AppendLine("Preserved changed Biology-owned files: " + result.PreservedChanged.Count);
            builder.AppendLine("Preserved generic/shared dependency files: " + result.PreservedGeneric.Count);
            builder.AppendLine("Already missing: " + result.Missing.Count);
            builder.AppendLine("Errors: " + result.Errors.Count);
            builder.AppendLine("Ownership receipt deleted: " + result.ReceiptDeleted);
            builder.AppendLine();

            if (result.PreservedChanged.Count > 0)
            {
                builder.AppendLine("CHANGED BIOLOGY FILES PRESERVED");
                foreach (string item in result.PreservedChanged) builder.AppendLine("  " + item);
                builder.AppendLine();
            }
            if (result.PreservedGeneric.Count > 0)
            {
                builder.AppendLine("GENERIC/SHARED DEPENDENCIES PRESERVED");
                foreach (string item in result.PreservedGeneric) builder.AppendLine("  " + item);
                builder.AppendLine();
            }
            if (result.Errors.Count > 0)
            {
                builder.AppendLine("ERRORS / MANUAL REVIEW REQUIRED");
                foreach (string item in result.Errors) builder.AppendLine("  " + item);
                builder.AppendLine();
            }
            foreach (string note in result.Notes) builder.AppendLine("NOTE: " + note);
            if (result.RedmodRefresh != null)
            {
                builder.AppendLine();
                builder.AppendLine("REDMOD REFRESH");
                builder.AppendLine("  Attempted: " + result.RedmodRefresh.Attempted);
                builder.AppendLine("  Succeeded: " + result.RedmodRefresh.Succeeded);
                builder.AppendLine("  Other REDmods detected: " + result.RedmodRefresh.OtherRedmodCount);
                builder.AppendLine("  Outcome: " + result.RedmodRefresh.Outcome);
                if (!string.IsNullOrWhiteSpace(result.RedmodRefresh.Output))
                {
                    builder.AppendLine("  Output:");
                    builder.AppendLine(result.RedmodRefresh.Output);
                }
            }
            builder.AppendLine();
            builder.AppendLine("Save files were not accessed or changed; save-backed Biology preference/state was therefore preserved.");
            return builder.ToString();
        }
    }
}
