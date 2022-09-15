using System.Reflection;
using WSL;

namespace Launcher.Helpers;

public static class VersionHelper {
    public static Version? LauncherVersion => Assembly.GetEntryAssembly()?.GetName().Version;

    public static NixosWslVersion? InstalledVersion {
        get {
            try {
                if (StartupHelper.BootDistro()) {
                    var ver = WslApiLoader.WslLaunchGetOutput(
                        DistributionInfo.Name,
                        "nixos-wsl-version",
                        false,
                        out var exitCode,
                        true
                    ).Trim();

                    if (exitCode == 0) {
                        return new NixosWslVersion(ver);
                    }
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

        public Version AsVersion() => _version;
        public override string ToString() => _versionString;
    }
}