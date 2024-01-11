using System.Diagnostics;
using System.Runtime.InteropServices;
using WSL.Kernel32;

namespace WSL;

public static partial class WslApiLoader {
    public static void WslLaunch(
        string distributionName,
        string? command,
        bool useCurrentWorkingDirectory,
        IntPtr stdIn,
        IntPtr stdOut,
        IntPtr stdErr,
        out IntPtr process
    ) {
        [DllImport("wslapi.dll", CallingConvention = CallingConvention.Winapi, CharSet = CharSet.Unicode)]
        // ReSharper disable once LocalFunctionHidesMethod
        static extern long WslLaunch(
            string distributionName,
            string? command,
            bool useCurrentWorkingDirectory,
            IntPtr stdIn,
            IntPtr stdOut,
            IntPtr stdErr,
            out IntPtr process
        );

        WslApiException.checkResult(
            WslLaunch(
                distributionName,
                command,
                useCurrentWorkingDirectory,
                stdIn,
                stdOut,
                stdErr,
                out process
            )
        );
    }
}
