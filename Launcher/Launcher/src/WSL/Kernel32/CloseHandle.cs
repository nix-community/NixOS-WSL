using System.Runtime.ConstrainedExecution;
using System.Runtime.InteropServices;
using System.Security;

namespace WSL.Kernel32;

public static partial class Kernel32Loader {
    [DllImport("kernel32.dll", SetLastError = true)]
    [SuppressUnmanagedCodeSecurity]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool CloseHandle(IntPtr hObject);
}
