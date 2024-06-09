using System.Runtime.InteropServices;

namespace Launcher.WSL;

public static partial class WslApiLoader {
    public static bool WslIsDistributionRegistered(string distributionName) {
        [DllImport("wslapi.dll", CallingConvention = CallingConvention.Winapi, CharSet = CharSet.Unicode)]
        // ReSharper disable once LocalFunctionHidesMethod
        static extern bool WslIsDistributionRegistered(string distributionName);

        return WslIsDistributionRegistered(distributionName);
    }

}
