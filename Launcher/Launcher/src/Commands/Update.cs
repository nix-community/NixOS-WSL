using System.CommandLine;
using Launcher.Helpers;
using WSL;

namespace Launcher.Commands;

public static class Update {
    public static Command GetCommand() {
        var command = new Command("update") {
            Description = $"Update {DistributionInfo.DisplayName} to the version bundled with this launcher"
        };

        command.SetHandler(() => {
            ulong Run() {
                if (!StartupHelper.BootDistro()) return 1;

                var tarball = InstallationHelper.FindTarball();
                if (tarball == null) return 1;

                var path = Path.GetDirectoryName(tarball);
                if (path == null) return 1;
                Directory.SetCurrentDirectory(path);

                var tmpDir = $"/tmp/nixos-wsl-{VersionHelper.LauncherVersion.ToString()}";

                Console.WriteLine("Unpacking installer...\n");
                WslApiLoader.WslLaunchInteractive(
                    DistributionInfo.Name,
                    $"sh -c 'rm -rf \"{tmpDir}\" && mkdir -p \"{tmpDir}\" && tar -C \"{tmpDir}\" -xvf ./{Path.GetFileName(tarball)}'",
                    true,
                    out var exitCode
                );
                if (exitCode != 0) {
                    Console.Error.WriteLine("Failed to unpack installer");
                    return exitCode;
                }

                Console.WriteLine("\nStarting update script...\n");
                WslApiLoader.WslLaunchInteractive(
                    DistributionInfo.Name,
                    $"sudo {tmpDir}/nix/wsl-installer/updater.sh",
                    false,
                    out exitCode
                );

                Console.WriteLine("\nCleaning up...\n");
                WslApiLoader.WslLaunchInteractive(
                    DistributionInfo.Name,
                    $"rm -rf \"{tmpDir}\"",
                    false,
                    out _
                );

                if (exitCode != 0)
                    Console.Error.WriteLine("\nAn error occured in the update script");
                else
                    Console.WriteLine("\nUpdate finished successfully");

                return exitCode;
            }

            Program.result = (int)Run();
        });

        return command;
    }
}
