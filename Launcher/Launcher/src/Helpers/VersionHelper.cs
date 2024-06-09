using System.Runtime.InteropServices;
using System.Text.Json;

using Launcher.WSL;

namespace Launcher.Helpers;

public static class VersionHelper {
    public static Version? LauncherVersion => typeof(VersionHelper).Assembly.GetName().Version;

    public static string? InstalledVersion {
        get {
            try {
                var output = WslApiLoader.WslLaunchGetOutput(
                    DistributionInfo.Name,
                    "/bin/sh --login -c \"nixos-wsl-version --json\"",
                    false,
                    out uint _,
                    true
                ).Trim();

                var json = JsonSerializer.Deserialize<Dictionary<string, string>>(output);
                return json?["release"];
            } catch (COMException) {
                // ignored
            }

            return null;
        }
    }
}
