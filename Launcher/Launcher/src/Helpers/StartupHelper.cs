using WSL;

namespace Launcher.Helpers;

public static class StartupHelper {
    private static bool booted;

    public static bool BootDistro() {
        if (booted) return true;
        try {
            // TODO: Only do this if the distro isn't running already
            WslApiLoader.WslLaunchInteractive(
                DistributionInfo.Name,
                "sh -c \"exit\"", // Don't run anything, exit after we get a shell
                false,
                out var exitCode
            );
            if (exitCode != 0) {
                goto fail;
            }
        } catch (WslApiException) {
            goto fail;
        }

        booted = true;
        return true;

        fail:
        Console.Error.WriteLine("An error occured when starting the distro");
        return false;
    }
}