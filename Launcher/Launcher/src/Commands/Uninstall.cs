using System.CommandLine;

using Launcher.Helpers;
using Launcher.i18n;

namespace Launcher.Commands;

public static class Uninstall {
    public static Command GetCommand() {
        var command = new Command("uninstall") {
            Description = string.Format(Translations.Install_UninstallDescription, DistributionInfo.DisplayName)
        };

        command.SetHandler(() => { Program.Result = InstallationHelper.Uninstall() ? 0 : 1; });

        return command;
    }
}
