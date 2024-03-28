using System.Reflection;
using WSL;

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

        // Determine tarball location
        var tarPath = FindTarball();
        if (tarPath == null) {
            Console.Error.WriteLine("Could not find distro tarball");
            return 1;
        }

        ExceptionContext.AddOnCatch(
            () => WslApiLoader.WslRegisterDistribution(
                DistributionInfo.Name,
                tarPath
            ),
            "when registering the distribution"
        );

        Console.WriteLine("Installation finished successfully");
        return 0;
    }

    /// <summary>
    ///     Unregister the distribution
    /// </summary>
    /// <returns>true on success</returns>
    public static bool Uninstall() {
        Console.WriteLine($"Uninstalling {DistributionInfo.DisplayName}...");
        if (!WslApiLoader.WslIsDistributionRegistered(DistributionInfo.Name)) {
            Console.Error.WriteLine($"{DistributionInfo.DisplayName} is not installed!");
            return false;
        }

        ExceptionContext.AddOnCatch(
            () => WslApiLoader.WslUnregisterDistribution(DistributionInfo.Name),
            "when unregistering the distribution"
        );

        Console.WriteLine("Uninstall completed");
        return true;
    }

    /// <summary>
    ///     Find the path of the installer tarball
    /// </summary>
    /// <returns>the full path to the tarball or null</returns>
    public static string? FindTarball() {
        const string tarFileName = "nixos-wsl.tar.gz";

        // Accept a tarball in the current directory when running a debug build
#if (DEBUG)
        var pwd = Directory.GetCurrentDirectory();
        var debugTarPath = Path.Combine(pwd, tarFileName);
        if (File.Exists(debugTarPath)) return debugTarPath;
#endif

        // Look for the tarball in the same directory as the executable
        var assemblyPath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
        if (assemblyPath == null) return null;

        var tarPath = Path.Combine(assemblyPath, tarFileName);
        if (File.Exists(tarPath)) return tarPath;

        // In the APPX package, the tarball is in the parent directory
        var parentDirectory = Directory.GetParent(assemblyPath)?.FullName;
        if (parentDirectory == null) return null;

        tarPath = Path.Combine(parentDirectory, tarFileName);
        return File.Exists(tarPath)
            ? tarPath
            : null;
    }
}
