using System.Runtime.InteropServices;

using Windows.Win32.Foundation;

namespace WSL;

public static partial class WslApiLoader {
    public static void WslConfigureDistribution(
        string distributionName,
        ulong defaultUID,
        WslDistributionFlags wslDistributionFlags
    ) {
        [DllImport("wslapi.dll", CallingConvention = CallingConvention.Winapi, CharSet = CharSet.Unicode)]
        // ReSharper disable once LocalFunctionHidesMethod
        static extern HRESULT WslConfigureDistribution(
            string distributionName,
            ulong defaultUID,
            WslDistributionFlags wslDistributionFlags
        );

        CheckResult(WslConfigureDistribution(distributionName, defaultUID, wslDistributionFlags));
    }
}
