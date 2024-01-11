using System.Runtime.InteropServices;

namespace WSL;

public static partial class WslApiLoader {
    public static void WslUnregisterDistribution(
        string distributionName
    ) {
        [DllImport("wslapi.dll", CallingConvention = CallingConvention.Winapi, CharSet = CharSet.Unicode)]
        // ReSharper disable once LocalFunctionHidesMethod
        static extern long WslUnregisterDistribution(string distributionName);

        WslApiException.checkResult(
            WslUnregisterDistribution(
                distributionName
            )
        );
    }
}
