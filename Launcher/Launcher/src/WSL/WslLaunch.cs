using System.Runtime.InteropServices;

using Microsoft.Win32.SafeHandles;

using Windows.Win32.Foundation;

namespace Launcher.WSL;

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

        ArgumentNullException.ThrowIfNull(stdIn);
        ArgumentNullException.ThrowIfNull(stdOut);
        ArgumentNullException.ThrowIfNull(stdErr);

        var hresult = WslLaunch(
            distributionName,
            command,
            useCurrentWorkingDirectory,
            stdIn.DangerousGetHandle(),
            stdOut.DangerousGetHandle(),
            stdErr.DangerousGetHandle(),
            out var internalProcess
        );

        CheckResult(hresult);

        process = new SafeProcessHandle(internalProcess, true);
    }
}
