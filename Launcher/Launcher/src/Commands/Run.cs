using System.CommandLine;

using Launcher.i18n;
using Launcher.WSL;

namespace Launcher.Commands;

public static class Run {
    public static Command GetCommand() {
        var command = new Command("run") {
            Description = Translations.Run_Description
        };
        var argCmd = new Argument<string>("command") {
            Arity = ArgumentArity.ZeroOrOne
        };
        command.AddArgument(argCmd);

        command.SetHandler(cmd => {
            uint exitCode = 1;

            if (!WslApiLoader.WslIsDistributionRegistered(DistributionInfo.Name)) {
                Console.Error.WriteLine(Translations.Error_NotInstalled, DistributionInfo.DisplayName);
                Program.Result = 1;
                return;
            }

            ExceptionContext.AddIfThrown(
                () => WslApiLoader.WslLaunchInteractive(DistributionInfo.Name, cmd, true, out exitCode),
                "when starting the command"
            );

            Program.Result = (int) exitCode;
        }, argCmd);

        return command;
    }
}
