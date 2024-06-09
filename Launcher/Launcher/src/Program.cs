using System.CommandLine;
using System.CommandLine.Builder;
using System.CommandLine.Invocation;
using System.CommandLine.IO;
using System.CommandLine.Parsing;
using System.Diagnostics.CodeAnalysis;
using System.Globalization;

using Launcher.Commands;
using Launcher.Helpers;
using Launcher.i18n;
using Launcher.WSL;

using Windows.Win32.Foundation;

namespace Launcher;

internal static class Program {
    public static int Result;

    public static async Task<int> Main(string[] args) {
        // Set title of the console
        Console.Title = DistributionInfo.WindowTitle;

        // Argparse docs: https://github.com/dotnet/command-line-api

        var rootCommand = new RootCommand(
            string.Format(CultureInfo.CurrentCulture, Translations.Root_Description, DistributionInfo.DisplayName)
        ) {
            Run.GetCommand(),
            Install.GetCommand(),
            Registered.GetCommand(),
            Uninstall.GetCommand()
        };

        var distroNameOption = new Option<string>("--distro-name") {
            Description = Translations.Option_DistroName,
            Arity = ArgumentArity.ZeroOrOne
        };
        distroNameOption.SetDefaultValue(DistributionInfo.Name);

        var versionOption = new Option<bool>("--version") {
            Description = Translations.Option_Version
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

            ExceptionContext.AddIfThrown(() => {
                WslApiLoader.WslLaunchInteractive(DistributionInfo.Name, null, false, out var exitCode);
                Result = (int) exitCode;
            }, "when starting the shell");
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
                CrashHandler(exception);
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
                var vi = VersionHelper.InstalledVersion ?? "UNKNOWN";

                context.Console.Out.WriteLine(string.Format(CultureInfo.CurrentCulture, Translations.Version_Launcher, vl));
                context.Console.Out.WriteLine(string.Format(CultureInfo.CurrentCulture, Translations.Version_Module, vi));
            } else {
                await next(context).ConfigureAwait(false);
            }
        }, (MiddlewareOrder) (-1200)); // Internal value for the builtin version option

        await commandLineBuilder.Build().InvokeAsync(args).ConfigureAwait(false);

        return Result;
    }

    [DoesNotReturn]
    private static void CrashHandler(Exception exception) {
        var unwrapped = exception;
        while (unwrapped is ContextualizedException) {
            unwrapped = unwrapped.InnerException;
        }

        switch (unwrapped) {
            case DllNotFoundException:
            case { HResult: var hr } when (hr & 0xFFFF) == (int) WIN32_ERROR.ERROR_LINUX_SUBSYSTEM_NOT_PRESENT: { // Only compare the lowest 16 bits (the Win32 error code)
                Console.Error.WriteLine(Translations.Error_WslMissing, "https://aka.ms/wslinstall");
                break;
            }
            default: {
                Console.Error.WriteLine("");
                Console.Error.WriteLine("===== BEGIN STACK TRACE =====");
                Console.Error.WriteLine(exception);
                Console.Error.WriteLine("====== END STACK TRACE ======");
                Console.Error.WriteLine("");
                Console.Error.WriteLine(Translations.Error_Crashed);
                Console.Error.WriteLine("https://github.com/nix-community/NixOS-WSL/issues/new/choose");
                break;
            }
        }

        var exitCode = exception.HResult;
        if (exitCode == 0) { // Ensure that the result is non-zero
            exitCode = 1;
        }

        Environment.Exit(exitCode);
    }
}
