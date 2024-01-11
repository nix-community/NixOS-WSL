using System.Runtime.InteropServices;

namespace WSL.Kernel32;

public static partial class Kernel32Loader {
    [DllImport(@"kernel32.dll", SetLastError = true)]
    public static extern unsafe bool ReadFile(
        IntPtr hFile,
        IntPtr pBuffer,
        int NumberOfBytesToRead,
        out int pNumberOfBytesRead,
        IntPtr lpOverlapped
    );
}
