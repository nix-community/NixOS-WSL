using System.CommandLine;
using Launcher.Commands;

namespace Launcher;

internal static class Program {
    public static int result = 0;

    public static int Main(string[] args) {
        // Set title of the console
        Console.Title = DistributionInfo.WindowTitle;

        // Argparse docs: https://github.com/dotnet/command-line-api

        var rootCommand = new RootCommand(
            $"Manage the {DistributionInfo.DisplayName} WSL distribution"
        ) {
            Run.GetCommand(),
            Install.GetCommand(),
            Uninstall.GetCommand()
        };

        rootCommand.SetHandler(() => { Console.WriteLine("root"); });

        rootCommand.Invoke(args);

        return result;
    }
}