using System.CommandLine;
using Launcher.Commands;
using Launcher.Helpers;
using WslApiAdapter.WslApi;

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

        rootCommand.SetHandler(() => {
            if (!WslApiLoader.WslIsDistributionRegistered(DistributionInfo.Name)) {
                result = InstallationHelper.Install();
                if (result != 0)
                { 
                    return;
                }
            }

            try {
                WslApiLoader.WslLaunchInteractive(DistributionInfo.Name, null, true, out var exitCode);
                Program.result = (int) exitCode;
            }
            catch (WslApiException e) {
                Console.Error.WriteLine("An error occured when starting the shell");
                Program.result = e.HResult;
            }
        });

        rootCommand.Invoke(args);

        return result;
    }
}