﻿using System.Reflection;
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

        if (!StartupHelper.BootDistro()) {
            Console.Error.WriteLine("An error occured during first-time setup");
            return 1;
        }

        Console.WriteLine("Installation finished successfully");
        return 0;
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

    /// <summary>
    ///     Find the path of the installer tarball
    /// </summary>
    /// <returns>the full path to the tarball or null</returns>
    private static string? FindTarball() {
        const string tarFileName = "nixos-wsl-installer.tar.gz";

        var tarPath = "";
        
        // Accept a tarball in the current directory when running a debug build
        #if (DEBUG)
        var pwd = Directory.GetCurrentDirectory();
        tarPath = Path.Combine(pwd, tarFileName);
        if (File.Exists(tarPath)) return tarPath;
        #endif
        
        // Look for the tarball in the same directory as the executable
        var assemblyPath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
        if (assemblyPath != null) {
            tarPath = Path.Combine(assemblyPath, tarFileName);
            if (File.Exists(tarPath)) return tarPath;
        
            // In the APPX package, the tarball is in the parent directory
            var parentDirectory = Directory.GetParent(assemblyPath)?.FullName;
            if (parentDirectory != null) {
                tarPath = Path.Combine(parentDirectory, tarFileName);
                if (File.Exists(tarPath)) return tarPath;
            }    
        }
        
        return null;
    }
}