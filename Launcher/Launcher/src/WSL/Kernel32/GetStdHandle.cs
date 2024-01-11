using System.Runtime.InteropServices;

namespace WSL.Kernel32;

public static partial class Kernel32Loader {
    public static int STD_INPUT_HANDLE = -10;
    public static int STD_OUTPUT_HANDLE = -11;
    public static int STD_ERROR_HANDLE = -12;

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetStdHandle(int nStdHandle);
}
