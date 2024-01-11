using System.Runtime.InteropServices;

namespace WSL;

public static partial class WslApiLoader {
    public static unsafe void WslLaunchInteractive(
        string distributionName,
        string? command,
        bool useCurrentWorkingDirectory,
        out uint exitCode
    ) {
        [DllImport("wslapi.dll", CallingConvention = CallingConvention.Winapi, CharSet = CharSet.Unicode, ExactSpelling = true, PreserveSig = true)]
        // ReSharper disable once LocalFunctionHidesMethod
        static extern long WslLaunchInteractive(
            [In] string distributionName,
            [In] string? command,
            [In] bool useCurrentWorkingDirectory,
            [Out, MarshalAs(UnmanagedType.U4)] out uint exitCode
        );

        WslApiException.checkResult(
            WslLaunchInteractive(
                distributionName,
                command,
                useCurrentWorkingDirectory,
                out exitCode
            )
        );
        Console.WriteLine(exitCode);
    }
}
