using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using Microsoft.Win32;

namespace BiologyInstall
{
    internal static class BiologyInstallerProgram
    {
        [STAThread]
        private static int Main(string[] args)
        {
            bool command = args.Contains("--install") || args.Contains("--check");
            try
            {
                string package = Path.GetDirectoryName(Application.ExecutablePath);
                if (command)
                {
                    string rootArg = args.FirstOrDefault(a => a.StartsWith("--game-root=", StringComparison.Ordinal));
                    if (rootArg == null) throw new ArgumentException("Supply --game-root=<Cyberpunk 2077 folder>.");
                    string root = rootArg.Substring("--game-root=".Length);
                    BiologyInstaller.EnsureStopped();
                    BiologyInstaller.ValidateSupportedGame(root);
                    InstallPlan plan = BiologyInstaller.Plan(package, root);
                    if (args.Contains("--install")) BiologyInstaller.Execute(plan);
                    Console.WriteLine("PASS: Biology " + (args.Contains("--install") ? "installed" : "preflight") + "; version " + plan.Version + "; " + plan.Files.Count + " verified files.");
                    return 0;
                }
                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new BiologyInstallForm(package));
                return 0;
            }
            catch (Exception ex)
            {
                if (command) Console.Error.WriteLine(ex.Message);
                else MessageBox.Show(ex.Message, "Biology installation stopped", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return 1;
            }
        }
    }
    internal sealed class BiologyInstallForm : Form
    {
        private readonly string package;
        private readonly TextBox folder, report;
        private readonly Button install;
        public BiologyInstallForm(string package)
        {
            this.package = package;
            Text = "Install Biology";
            StartPosition = FormStartPosition.CenterScreen;
            ClientSize = new Size(720, 420);
            MinimumSize = Size;
            Font = new Font("Segoe UI", 10F);
            var title = new Label { Text = "Biology", Font = new Font(Font.FontFamily, 22F, FontStyle.Bold), AutoSize = true, Location = new Point(22, 18) };
            Controls.Add(title);
            Controls.Add(new Label { Text = "Choose your Cyberpunk 2077 folder. Close the game before installing.", AutoSize = true, Location = new Point(25, 72) });
            folder = new TextBox { Left = 25, Top = 106, Width = 550, Text = FindGame() };
            Controls.Add(folder);
            var browse = new Button { Text = "Browse…", Left = 590, Top = 103, Width = 100, Height = 30 };
            browse.Click += delegate {
                using (var dialog = new FolderBrowserDialog { Description = "Select the Cyberpunk 2077 game folder", SelectedPath = folder.Text, ShowNewFolderButton = false })
                    if (dialog.ShowDialog(this) == DialogResult.OK) folder.Text = dialog.SelectedPath;
            };
            Controls.Add(browse);
            install = new Button { Text = "Install Biology", Left = 25, Top = 151, Width = 165, Height = 36 };
            install.Click += Install;
            Controls.Add(install);
            var close = new Button { Text = "Close", Left = 205, Top = 151, Width = 95, Height = 36 };
            close.Click += delegate { Close(); };
            Controls.Add(close);
            report = new TextBox { Left = 25, Top = 210, Width = 665, Height = 185, Multiline = true, ReadOnly = true, ScrollBars = ScrollBars.Vertical,
                Text = "Requires Cyberpunk 2077 2.31 with the official REDmod tools.\r\n\r\nThe installer checks package hashes and existing files before making changes. Your saves and unrelated mods are preserved." };
            Controls.Add(report);
        }
        private static string FindGame()
        {
            string installed = Registry.GetValue(@"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 1091500", "InstallLocation", null) as string;
            if (!string.IsNullOrEmpty(installed) && File.Exists(Path.Combine(installed, "bin", "x64", "Cyberpunk2077.exe"))) return installed;
            return "";
        }
        private void Install(object sender, EventArgs e)
        {
            install.Enabled = false;
            UseWaitCursor = true;
            try
            {
                BiologyInstaller.EnsureStopped();
                BiologyInstaller.ValidateSupportedGame(folder.Text);
                InstallPlan plan = BiologyInstaller.Plan(package, folder.Text);
                BiologyInstaller.Execute(plan);
                report.Text = "Biology " + plan.Version + " installed successfully.\r\n\r\nEnable mods in REDlauncher, then launch the game. REDlauncher deploys the Biology REDmod package.\r\n\r\nTo remove Biology, close the game and double-click Uninstall Biology.exe in the game folder.";
            }
            catch (Exception ex) { report.Text = "Installation stopped.\r\n\r\n" + ex.Message; install.Enabled = true; }
            finally { UseWaitCursor = false; }
        }
    }
}
