using System.Runtime.InteropServices;

namespace WSL;

public static partial class WslApiLoader {
    public static void WslRegisterDistribution(
        string distributionName,
        string tarGzFilename
    ) {
        [DllImport("wslapi.dll", CallingConvention = CallingConvention.Winapi, CharSet = CharSet.Unicode)]
        // ReSharper disable once LocalFunctionHidesMethod
        static extern long WslRegisterDistribution(
            string distributionName,
            string tarGzFilename
        );

        WslApiException.checkResult(
            WslRegisterDistribution(
                distributionName,
                tarGzFilename
            )
        );
    }
}
