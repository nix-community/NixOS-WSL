using System.Runtime.InteropServices;

namespace WSL;

public static partial class WslApiLoader {
    public static void WslConfigureDistribution(
        string distributionName,
        ulong defaultUID,
        WSL_DISTRIBUTION_FLAGS wslDistributionFlags
    ) {
        [DllImport("wslapi.dll", CallingConvention = CallingConvention.Winapi, CharSet = CharSet.Unicode)]
        // ReSharper disable once LocalFunctionHidesMethod
        static extern long WslConfigureDistribution(
            string distributionName,
            ulong defaultUID,
            WSL_DISTRIBUTION_FLAGS wslDistributionFlags
        );
        WslApiException.checkResult(WslConfigureDistribution(distributionName, defaultUID, wslDistributionFlags));
    }
}
