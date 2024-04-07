using System.Runtime.InteropServices;

using Windows.Win32.Foundation;

namespace Launcher.WSL;

public static partial class WslApiLoader {
    public static void WslUnregisterDistribution(
        string distributionName
    ) {
        [DllImport("wslapi.dll", CallingConvention = CallingConvention.Winapi, CharSet = CharSet.Unicode)]
        // ReSharper disable once LocalFunctionHidesMethod
        static extern HRESULT WslUnregisterDistribution(string distributionName);

        CheckResult(
            WslUnregisterDistribution(
                distributionName
            )
        );
    }
}
