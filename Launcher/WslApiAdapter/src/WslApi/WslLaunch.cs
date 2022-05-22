using System.Diagnostics;
using System.Runtime.InteropServices;
using WslApiAdapter.Kernel32;

namespace WslApiAdapter.WslApi;

public static partial class WslApiLoader {
    public static void WslLaunch(
        string distributionName,
        string? command,
        bool useCurrentWorkingDirectory,
        IntPtr stdIn,
        IntPtr stdOut,
        IntPtr stdErr,
        out Process process
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
                out var processHandle
            )
        );
        process = Process.GetProcessById(Kernel32Loader.GetProcessId(processHandle));
        
        if (!Kernel32Loader.CloseHandle(processHandle)) {
            throw new ExternalException("Could not close process handle!");
        };
    }
}