using System.Runtime.InteropServices;

namespace WSL;

public static partial class WslApiLoader {
    [DllImport("wslapi.dll", CallingConvention = CallingConvention.Winapi, CharSet = CharSet.Unicode)]
    public static extern bool WslIsDistributionRegistered(string distributionName);
}
