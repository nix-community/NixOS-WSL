using System.CommandLine;
using Launcher.Helpers;

namespace Launcher.Commands;

public static class Uninstall {
    public static Command GetCommand() {
        var command = new Command("uninstall") {
            Description = $"Uninstall {DistributionInfo.DisplayName}"
        };

        command.SetHandler(() => { Program.result = InstallationHelper.Uninstall(); });

        return command;
    }
}
