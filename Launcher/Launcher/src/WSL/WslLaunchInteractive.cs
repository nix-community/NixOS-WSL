using System.Runtime.InteropServices;

using Windows.Win32.Foundation;

namespace Launcher.WSL;

public static partial class WslApiLoader {
    public static void WslLaunchInteractive(
        string distributionName,
        string? command,
        bool useCurrentWorkingDirectory,
        out uint exitCode
    ) {
        [DllImport("wslapi.dll", CallingConvention = CallingConvention.Winapi, CharSet = CharSet.Unicode,
            ExactSpelling = true, PreserveSig = true)]
        // ReSharper disable once LocalFunctionHidesMethod
        static extern HRESULT WslLaunchInteractive(
            [In] string distributionName,
            [In] string? command,
            [In] bool useCurrentWorkingDirectory,
            [Out][MarshalAs(UnmanagedType.U4)] out uint exitCode
        );

        CheckResult(
            WslLaunchInteractive(
                distributionName,
                command,
                useCurrentWorkingDirectory,
                out exitCode
            )
        );
    }
}
