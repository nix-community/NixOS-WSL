using System.Reflection;
using WslApiAdapter.WslApi;

namespace Launcher.Helpers;

public static class InstallationHelper {
    /// <summary>
    ///     Registers the distribution and runs first-time setup
    /// </summary>
    /// <returns>0 on success, an error code otherwise</returns>
    public static int Install() {
        Console.WriteLine($"Registering {DistributionInfo.DisplayName}...");

        if (WslApiLoader.WslIsDistributionRegistered(DistributionInfo.Name)) {
            Console.Error.WriteLine($"{DistributionInfo.DisplayName} is already installed!");
            return 0;
        }

        const string tarFileName = "nixos-wsl-installer.tar.gz";

        // Determine tarball location
        var assemblyPath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);

        if (assemblyPath == null) goto tarFail;

        var tarPath = Path.Combine(assemblyPath, tarFileName);
        if (!File.Exists(tarPath)) {
            var parentDirectory = Directory.GetParent(assemblyPath)?.FullName;
            if (parentDirectory != null) {
                tarPath = Path.Combine(parentDirectory, tarFileName);
                if (!File.Exists(tarPath)) goto tarFail;
            } else {
                goto tarFail;
            }
        }

        try {
            WslApiLoader.WslRegisterDistribution(
                DistributionInfo.Name,
                tarPath
            );
        } catch (WslApiException e) {
            Console.Error.WriteLine("There was an error registering the distribution");
            return e.HResult;
        }

        Console.WriteLine("Performing first-time setup...");

        try {
            WslApiLoader.WslLaunchInteractive(
                DistributionInfo.Name,
                "sh -c \"exit\"", // Don't run anything, exit after we get a shell
                false,
                out var exitCode
            );
            if (exitCode != 0) {
                Console.Error.WriteLine("An error occured during first-time setup");
                var result = (int) exitCode;
                return result == 0 ? 1 : result;
            }
        } catch (WslApiException e) {
            Console.Error.WriteLine("An internal error occured, when starting first-time setup!");
            return e.HResult;
        }

        Console.WriteLine("Installation finished successfully");
        return 0;

        tarFail:
        Console.Error.WriteLine("Could not find distro tarball");
        return 1;
    }

    /// <summary>
    ///     Unregister the distribution
    /// </summary>
    /// <returns>0 on success and an error code otherwise</returns>
    public static int Uninstall() {
        Console.WriteLine($"Uninstalling {DistributionInfo.DisplayName}...");
        if (!WslApiLoader.WslIsDistributionRegistered(DistributionInfo.Name)) {
            Console.Error.WriteLine($"{DistributionInfo.DisplayName} is not installed!");
            return 1;
        }

        try {
            WslApiLoader.WslUnregisterDistribution(DistributionInfo.Name);
        } catch (WslApiException e) {
            Console.Error.WriteLine("An error occured when unregistering the distribution!");
            return e.HResult;
        }

        Console.WriteLine("Uninstall completed");
        return 0;
    }
}