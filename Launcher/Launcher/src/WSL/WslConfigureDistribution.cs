using System.Runtime.InteropServices;

using Windows.Win32.Foundation;

namespace Launcher.WSL;

public static partial class WslApiLoader {
    public static void WslConfigureDistribution(
        string distributionName,
        ulong defaultUid,
        WslDistributionFlags wslDistributionFlags
    ) {
        [DllImport("wslapi.dll", CallingConvention = CallingConvention.Winapi, CharSet = CharSet.Unicode)]
        // ReSharper disable once LocalFunctionHidesMethod
        static extern HRESULT WslConfigureDistribution(
            string distributionName,
            ulong defaultUid,
            WslDistributionFlags wslDistributionFlags
        );

        CheckResult(WslConfigureDistribution(distributionName, defaultUid, wslDistributionFlags));
    }
}
