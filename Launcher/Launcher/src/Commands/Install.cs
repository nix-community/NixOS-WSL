using System.CommandLine;
using Launcher.Helpers;

namespace Launcher.Commands;

public static class Install {
    public static Command GetCommand() {
        var command = new Command("install") {
            Description = $"Install {DistributionInfo.DisplayName} if it has not been installed already"
        };
        var reinstallOpt = new Option<bool>("--reinstall") {
            Description = "Delete the existing installation and install a fresh copy"
        };
        command.Add(reinstallOpt);

        command.SetHandler((bool reinstall) => {
            if (reinstall) {
                var result = InstallationHelper.Uninstall();
                if (result != 0) {
                    Program.result = result;
                    return;
                }
            }

            Program.result = InstallationHelper.Install();
        }, reinstallOpt);

        return command;
    }
}
