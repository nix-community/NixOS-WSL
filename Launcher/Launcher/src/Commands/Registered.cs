using System.CommandLine;
using WSL;

namespace Launcher.Commands;

public static class Registered {
    public static Command GetCommand() {
        var command = new Command("registered") {
            Description = "Check whether or not the distribution is registered"
        };
        var quietOpt = new Option<bool>(new[] { "--quiet", "-q" }) {
            Description = "Only return the appropriate exit code, dont write to the console"
        };
        command.Add(quietOpt);

        command.SetHandler((bool quiet) => {
            var registered = WslApiLoader.WslIsDistributionRegistered(DistributionInfo.Name);

            if (!quiet) {
                if (registered)
                    Console.WriteLine($"{DistributionInfo.Name} is registered");
                else
                    Console.WriteLine($"{DistributionInfo.Name} is not registered");
            }

            Program.result = registered ? 0 : 1;
        }, quietOpt);

        return command;
    }
}
