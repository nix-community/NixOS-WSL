using System.CommandLine;
using System.Globalization;

using Launcher.Helpers;
using Launcher.i18n;

namespace Launcher.Commands;

public static class Install {
    public static Command GetCommand() {
        var command = new Command("install") {
            Description = string.Format(CultureInfo.CurrentCulture, Translations.Install_Description, DistributionInfo.DisplayName)
        };
        var reinstallOpt = new Option<bool>("--reinstall") {
            Description = Translations.Install_OptionReinstall
        };
        command.Add(reinstallOpt);

        command.SetHandler(reinstall => {
            if (reinstall) {
                if (!InstallationHelper.Uninstall()) {
                    Program.Result = 1;
                    return;
                }
            }

            Program.Result = InstallationHelper.Install();
        }, reinstallOpt);

        return command;
    }
}
