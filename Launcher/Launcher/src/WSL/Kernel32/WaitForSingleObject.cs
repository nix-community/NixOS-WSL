using System.Runtime.InteropServices;

namespace WSL.Kernel32;

public static partial class Kernel32Loader {
    public const UInt32 INFINITE = 0xFFFFFFFF;
    const UInt32 WAIT_ABANDONED = 0x00000080;
    const UInt32 WAIT_OBJECT_0 = 0x00000000;
    const UInt32 WAIT_TIMEOUT = 0x00000102;

    public static void WaitForSingleObject(IntPtr hHandle, UInt32 dwMilliseconds) {
        [DllImport("kernel32.dll", SetLastError = true)]
        // ReSharper disable once LocalFunctionHidesMethod
        static extern UInt32 WaitForSingleObject(IntPtr hHandle, UInt32 dwMilliseconds);

        var result = WaitForSingleObject(hHandle, dwMilliseconds);
        if (result == WAIT_OBJECT_0) {
            return;
        }
        if (result == WAIT_TIMEOUT) {
            throw new TimeoutException();
        }
        if (result == WAIT_ABANDONED) {
            throw new AbandonedMutexException();
        }
        throw new Exception("WaitForSingleObject failed");
    }
}
