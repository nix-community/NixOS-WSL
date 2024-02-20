using System.Runtime.InteropServices;
using Windows.Win32.Foundation;
using Microsoft.Win32.SafeHandles;

namespace WSL;

public static partial class WslApiLoader {
    public static void WslLaunch(
        string distributionName,
        string? command,
        bool useCurrentWorkingDirectory,
        SafeFileHandle stdIn,
        SafeFileHandle stdOut,
        SafeFileHandle stdErr,
        out SafeProcessHandle process
    ) {
        [DllImport("wslapi.dll", CallingConvention = CallingConvention.Winapi, CharSet = CharSet.Unicode)]
        // ReSharper disable once LocalFunctionHidesMethod
        static extern HRESULT WslLaunch(
            string distributionName,
            string? command,
            bool useCurrentWorkingDirectory,
            IntPtr stdIn,
            IntPtr stdOut,
            IntPtr stdErr,
            out IntPtr process
        );

        var hresult = WslLaunch(
            distributionName,
            command,
            useCurrentWorkingDirectory,
            stdIn.DangerousGetHandle(),
            stdOut.DangerousGetHandle(),
            stdErr.DangerousGetHandle(),
            out var _process
        );

        CheckResult(hresult);

        process = new SafeProcessHandle(_process, true);
    }
}
