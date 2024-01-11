using System.Reflection;
using System.Text.Json;
using WSL;

namespace Launcher.Helpers;

public static class VersionHelper {
    public static Version? LauncherVersion => typeof(VersionHelper).Assembly.GetName().Version;

    public static NixosWslVersion? InstalledVersion {
        get {
            try {
                if (StartupHelper.BootDistro()) {
                    var output = WslApiLoader.WslLaunchGetOutput(
                        DistributionInfo.Name,
                        "/bin/sh --login -c \"nixos-wsl-version --json\"",
                        false,
                        out var exitCode,
                        true
                    ).Trim();

                    var json = JsonSerializer.Deserialize<Dictionary<string, string>>(output);
                    var version = json!["release"];

                    if (exitCode == 0) return new NixosWslVersion(version);
                }
            } catch (Exception) {
                // ignored
            }

            return null;
        }
    }

    public class NixosWslVersion {
        private readonly Version _version;
        private readonly string _versionString;

        internal NixosWslVersion(string versionString) {
            _versionString = versionString;

            if (Version.TryParse(versionString, out var ver)) {
                _version = ver;
                return;
            }

            _version = versionString == "DEV_BUILD"
                ? new Version(int.MaxValue, int.MaxValue, int.MaxValue, int.MaxValue)
                : new Version(0, 0, 0, 0);
        }

        public Version AsVersion() {
            return _version;
        }

        public override string ToString() {
            return _versionString;
        }
    }
}
