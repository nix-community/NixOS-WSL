using System.CommandLine;

using Launcher.i18n;
using Launcher.WSL;

namespace Launcher.Commands;

public static class Registered {
    private static readonly string[] Aliases = { "--quiet", "-q" };

    public static Command GetCommand() {
        var command = new Command("registered") {
            Description = Translations.Registered_Description
        };
        var quietOpt = new Option<bool>(Aliases) {
            Description = Translations.Registered_OptionQuiet
        };
        command.Add(quietOpt);

        command.SetHandler(quiet => {
            var registered = WslApiLoader.WslIsDistributionRegistered(DistributionInfo.Name);

            if (!quiet) {
                Console.WriteLine(
                    registered
                        ? Translations.Registered_True
                        : Translations.Registered_False,
                    DistributionInfo.Name
                );
            }

            Program.Result = registered ? 0 : 1;
        }, quietOpt);

        return command;
    }
}
