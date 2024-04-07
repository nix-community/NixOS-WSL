using System.Runtime.InteropServices;

using Windows.Win32.Foundation;

namespace Launcher.WSL;

public static partial class WslApiLoader {
    private static void CheckResult(
        HRESULT hresult
    ) {
        if (hresult.Failed) {
            Marshal.ThrowExceptionForHR(hresult);
        }
    }
}
