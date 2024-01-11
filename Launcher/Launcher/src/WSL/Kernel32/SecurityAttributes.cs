using System.Runtime.InteropServices;

namespace WSL.Kernel32;

public static partial class Kernel32Loader {
    [StructLayout(LayoutKind.Sequential)]
    public struct SECURITY_ATTRIBUTES {
        public int nLength;
        public IntPtr lpSecurityDescriptor;
        public bool bInheritHandle;
    }
}
