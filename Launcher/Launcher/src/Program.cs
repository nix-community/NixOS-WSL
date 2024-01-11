using System.CommandLine;
using System.CommandLine.Builder;
using System.CommandLine.Invocation;
using System.CommandLine.IO;
using System.CommandLine.Parsing;
using Launcher.Commands;
using Launcher.Helpers;
using WSL;

namespace Launcher;

internal static class Program {
    public static int result;

    public static async Task<int> Main(string[] args) {
        // Set title of the console
        Console.Title = DistributionInfo.WindowTitle;

        // Argparse docs: https://github.com/dotnet/command-line-api

        var rootCommand = new RootCommand(
            $"Manage the {DistributionInfo.DisplayName} WSL distribution"
        ) {
            Run.GetCommand(),
            Install.GetCommand(),
            Registered.GetCommand(),
            Uninstall.GetCommand(),
        };

        var distroNameOption = new Option<string>("--distro-name") {
            Description = "WSL distribution name",
            Arity = ArgumentArity.ZeroOrOne
        };
        distroNameOption.SetDefaultValue(DistributionInfo.Name);

        var versionOption = new Option<bool>("--version") {
            Description = "Show version information"
        };

        // Add the global options to the root command and all subcommands
        rootCommand.AddOption(distroNameOption);
        rootCommand.AddOption(versionOption);
        foreach (var subcommand in rootCommand.Subcommands) {
            subcommand.AddOption(distroNameOption);
            subcommand.AddOption(versionOption);
        }

        rootCommand.SetHandler(() => {
            if (!WslApiLoader.WslIsDistributionRegistered(DistributionInfo.Name)) {
                result = InstallationHelper.Install();
                if (result != 0) return;
            }

            try {
                WslApiLoader.WslLaunchInteractive(DistributionInfo.Name, null, true, out var exitCode);
                result = (int)exitCode;
            } catch (WslApiException e) {
                Console.Error.WriteLine("An error occured when starting the shell");
                result = e.HResult;
            }
        });

        var commandLineBuilder = new CommandLineBuilder(rootCommand)
            .UseHelp()
            .UseEnvironmentVariableDirective()
            .UseParseDirective()
            .UseSuggestDirective()
            .RegisterWithDotnetSuggest()
            .UseTypoCorrections()
            .UseParseErrorReporting()
            .UseExceptionHandler()
            .CancelOnProcessTermination();

        // Implement --distro-name option
        commandLineBuilder.AddMiddleware(async (context, next) => {
            var distroNameResult = context.ParseResult.FindResultFor(distroNameOption);

            if (distroNameResult is { Tokens.Count: > 0 }) DistributionInfo.Name = distroNameResult.Tokens[0].ToString();

            await next(context);
        }, (MiddlewareOrder)(-1300)); // Run before --version

        // Implement --version option
        commandLineBuilder.AddMiddleware(async (context, next) => {
            var versionResult = context.ParseResult.FindResultFor(versionOption);

            if (versionResult != null) {
                var vl = VersionHelper.LauncherVersion?.ToString();
                var vi = VersionHelper.InstalledVersion?.ToString() ?? "UNKNOWN";

                context.Console.Out.WriteLine($"Launcher: {vl}");
                context.Console.Out.WriteLine($"Module:   {vi}");
            } else {
                await next(context);
            }
        }, (MiddlewareOrder)(-1200)); // Internal value for the builtin version option

        await commandLineBuilder.Build().InvokeAsync(args);

        return result;
    }
}
