using WSL;

namespace Launcher.Helpers;

public static class StartupHelper {
    private static bool booted;

    public static bool BootDistro() {
        if (booted) return true;
        try {
            WslApiLoader.WslLaunchInteractive(
                DistributionInfo.Name,
                "/bin/sh -c \"exit\"", // Don't run anything, exit after we get a shell
                false,
                out var exitCode
            );
            if (exitCode != 0) {
                Console.Error.WriteLine("An error occured during the distro's startup process");
                return false;
            }
        } catch (WslApiException) {
            Console.Error.WriteLine("An error occured while trying to run a command in the distro");
            return false;
        }

        booted = true;
        return true;
    }
}
