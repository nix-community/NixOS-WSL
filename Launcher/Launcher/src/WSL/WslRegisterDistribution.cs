using System.Runtime.InteropServices;

using Windows.Win32.Foundation;

namespace Launcher.WSL;

public static partial class WslApiLoader {
    public static void WslRegisterDistribution(
        string distributionName,
        string tarGzFilename
    ) {
        [DllImport("wslapi.dll", CallingConvention = CallingConvention.Winapi, CharSet = CharSet.Unicode)]
        // ReSharper disable once LocalFunctionHidesMethod
        static extern HRESULT WslRegisterDistribution(
            string distributionName,
            string tarGzFilename
        );

        CheckResult(
            WslRegisterDistribution(
                distributionName,
                tarGzFilename
            )
        );
    }
}
