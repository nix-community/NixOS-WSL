using System.Runtime.InteropServices;

namespace WslApiAdapter.WslApi;

public static partial class WslApiLoader {
    public static void WslLaunchInteractive(
        string distributionName,
        string? command,
        bool useCurrentWorkingDirectory,
        out ulong exitCode
    ) {
        [DllImport("wslapi.dll", CallingConvention = CallingConvention.Winapi, CharSet = CharSet.Unicode)]
        // ReSharper disable once LocalFunctionHidesMethod
        static extern long WslLaunchInteractive(
            string distributionName,
            string? command,
            bool useCurrentWorkingDirectory,
            out ulong exitCode
        );

        WslApiException.checkResult(
            WslLaunchInteractive(
                distributionName,
                command,
                useCurrentWorkingDirectory,
                out exitCode
            )
        );
    }
}