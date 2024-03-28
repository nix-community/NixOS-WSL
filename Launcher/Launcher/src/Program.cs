using System.CommandLine;
using System.CommandLine.Builder;
using System.CommandLine.Invocation;
using System.CommandLine.IO;
using System.CommandLine.Parsing;
using System.ComponentModel;

using Launcher.Commands;
using Launcher.Helpers;

using Windows.Win32.Foundation;

using WSL;

namespace Launcher;

internal static class Program {
    public static int Result;

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
            Uninstall.GetCommand()
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
                Result = InstallationHelper.Install();
                if (Result != 0) {
                    return;
                }
            }

            try {
                WslApiLoader.WslLaunchInteractive(DistributionInfo.Name, null, true, out var exitCode);
                Result = (int) exitCode;
            } catch (Win32Exception e) {
                Console.Error.WriteLine("An error occured when starting the shell");
                Console.Error.WriteLine(e.Message);
                Console.Error.WriteLine(e.StackTrace);
                Result = e.HResult;
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
            .UseExceptionHandler(onException: (exception, _) => {
                Result = exception.HResult; //Set exit code

                var unwrapped = exception;
                while (unwrapped is ContextualizedException) {
                    unwrapped = unwrapped.InnerException;
                }

                switch (unwrapped) {
                    case DllNotFoundException:
                    case { HResult: var hr } when (hr & 0xFFFF) == (int) WIN32_ERROR.ERROR_LINUX_SUBSYSTEM_NOT_PRESENT: { // Only compare the lowest 16 bits (the Win32 error code)
                        Console.Error.WriteLine("Error: The Windows Subsystem for Linux is not enabled!");
                        Console.Error.WriteLine("Please refer to https://aka.ms/wslinstall for details on how to install it.");
                        break;
                    }
                    default: {
                        Console.Error.WriteLine("");
                        Console.Error.WriteLine("===== BEGIN STACK TRACE =====");
                        Console.Error.WriteLine(exception);
                        Console.Error.WriteLine("====== END STACK TRACE ======");
                        Console.Error.WriteLine("");
                        Console.Error.WriteLine("An error occurred!");
                        Console.Error.WriteLine("Please report this issue on GitHub and make sure to attach the stack trace above.");
                        Console.Error.WriteLine("https://github.com/nix-community/NixOS-WSL/issues/new/choose");
                        break;
                    }
                }
            })
            .CancelOnProcessTermination();

        // Implement --distro-name option
        commandLineBuilder.AddMiddleware(async (context, next) => {
            var distroNameResult = context.ParseResult.FindResultFor(distroNameOption);

            if (distroNameResult is { Tokens.Count: > 0 }) {
                DistributionInfo.Name = distroNameResult.Tokens[0].ToString();
            }

            await next(context).ConfigureAwait(false);
        }, (MiddlewareOrder) (-1300)); // Run before --version

        // Implement --version option
        commandLineBuilder.AddMiddleware(async (context, next) => {
            var versionResult = context.ParseResult.FindResultFor(versionOption);

            if (versionResult != null) {
                var vl = VersionHelper.LauncherVersion?.ToString();
                var vi = VersionHelper.InstalledVersion?.ToString() ?? "UNKNOWN";

                context.Console.Out.WriteLine($"Launcher: {vl}");
                context.Console.Out.WriteLine($"Module:   {vi}");
            } else {
                await next(context).ConfigureAwait(false);
            }
        }, (MiddlewareOrder) (-1200)); // Internal value for the builtin version option

        await commandLineBuilder.Build().InvokeAsync(args).ConfigureAwait(false);

        return Result;
    }
}
