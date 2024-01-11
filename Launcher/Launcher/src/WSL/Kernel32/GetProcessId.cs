using System.Runtime.InteropServices;

namespace WSL.Kernel32;

public static partial class Kernel32Loader {
    [DllImport("kernel32.dll")]
    public static extern int GetProcessId(IntPtr handle);
}
