using System.ComponentModel;
using WSL;

namespace Launcher.Helpers;

public static class StartupHelper {
    private static bool booted;

    public static bool BootDistro() {
        if (booted) return true;

        ExceptionContext.AddOnCatch(
            () => {
                WslApiLoader.WslLaunchInteractive(
                    DistributionInfo.Name,
                    "/bin/sh -c \"exit\"", // Don't run anything, exit after we get a shell
                    false,
                    out var exitCode
                );
                if (exitCode != 0) {
                    Console.Error.WriteLine("An error occured during the distro's startup process");
                    booted = false;
                }
            },
            "when trying to run a command in the distro"
        );

        booted = true;
        return booted;
    }
}
