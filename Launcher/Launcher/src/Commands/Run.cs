using System.CommandLine;
using System.ComponentModel;
using Launcher.Helpers;
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

        command.SetHandler((string? cmd) => {
            uint exitCode;

            if (!WslApiLoader.WslIsDistributionRegistered(DistributionInfo.Name)) {
                Console.Error.WriteLine($"{DistributionInfo.DisplayName} is not installed!");
                Program.result = 1;
                return;
            }

            try {
                WslApiLoader.WslLaunchInteractive(DistributionInfo.Name, cmd, true, out exitCode);
            } catch (Win32Exception e) {
                Console.Error.WriteLine("An error occured when starting the command!");
                Console.WriteLine(e.Message);
                Console.WriteLine(e.StackTrace);
                Program.result = e.HResult;
                return;
            }

            Program.result = (int)exitCode;
        }, argCmd);

        return command;
    }
}
