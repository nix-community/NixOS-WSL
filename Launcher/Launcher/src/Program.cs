using System.CommandLine;
using System.CommandLine.Builder;
using System.CommandLine.Parsing;
using Launcher.Commands;
using Launcher.Helpers;
using WslApiAdapter.WslApi;

namespace Launcher;

internal static class Program {
    public static int result = 0;

    public static async Task<int> Main(string[] args) {
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

        var distroNameOption = new Option<string>("--distro-name") {
            Description = "WSL distribution name",
            Arity = ArgumentArity.ZeroOrOne
        };
        distroNameOption.SetDefaultValue(DistributionInfo.Name);
        
        // Add the --distro-name option to the root command and all subcommands
        rootCommand.AddOption(distroNameOption);
        foreach (var subcommand in rootCommand.Subcommands) {
            subcommand.AddOption(distroNameOption);
        }

        rootCommand.SetHandler(() => {
            if (!WslApiLoader.WslIsDistributionRegistered(DistributionInfo.Name)) {
                result = InstallationHelper.Install();
                if (result != 0) {
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

        var commandLineBuilder = new CommandLineBuilder(rootCommand);
        
        // Implement a global --distro-name option
        commandLineBuilder.AddMiddleware(async (context, next) => {
            var distroNameResult = context.ParseResult.FindResultFor(distroNameOption);

            if (distroNameResult != null) {
                DistributionInfo.Name = distroNameResult.Tokens[0].ToString();
            }
            
            await next(context);
        });

        commandLineBuilder.UseDefaults();
        await commandLineBuilder.Build().InvokeAsync(args);

        return result;
    }
}