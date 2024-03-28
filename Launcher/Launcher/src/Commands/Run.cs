using System.CommandLine;
using System.ComponentModel;
using WSL;

namespace Launcher.Commands;

public static class Run {
    public static Command GetCommand() {
        var command = new Command("run") {
            Description =
                "Run a command in the current directory. If no command is specified, the default shell is launched"
        };
        var argCmd = new Argument<string>("command") {
            Arity = ArgumentArity.ZeroOrOne
        };
        command.AddArgument(argCmd);

        command.SetHandler(cmd => {
            uint exitCode = 1;

            if (!WslApiLoader.WslIsDistributionRegistered(DistributionInfo.Name)) {
                Console.Error.WriteLine($"{DistributionInfo.DisplayName} is not installed!");
                Program.result = 1;
                return;
            }

            ExceptionContext.AddOnCatch(
                () => WslApiLoader.WslLaunchInteractive(DistributionInfo.Name, cmd, true, out exitCode),
                "when starting the command"
            );

            Program.result = (int)exitCode;
        }, argCmd);

        return command;
    }
}
