using System.Runtime.InteropServices;

namespace WSL.Kernel32;

public static partial class Kernel32Loader {
    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetExitCodeProcess(IntPtr hProcess, out uint lpExitCode);
}
