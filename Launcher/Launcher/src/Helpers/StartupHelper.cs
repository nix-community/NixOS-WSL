using WSL;

namespace Launcher.Helpers; 

public static class StartupHelper {
    public static bool BootDistro() {
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
        } catch (WslApiException e) {
            goto fail;
        }

        return true;
        
        fail:
        Console.Error.WriteLine("An error occured when starting the distro");
        return false;
    }
}