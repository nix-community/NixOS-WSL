using System.Runtime.InteropServices;
using Windows.Win32.Foundation;

namespace WSL;

public static partial class WslApiLoader {
    public static void CheckResult(
        HRESULT hresult
    ) {
        if (hresult.Failed) {
            Marshal.ThrowExceptionForHR(hresult);
        }
    }
}
