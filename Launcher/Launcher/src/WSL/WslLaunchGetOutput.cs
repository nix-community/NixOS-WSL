using System.Runtime.InteropServices;
using System.Text;
using WSL.Kernel32;

namespace WSL;

public static partial class WslApiLoader {

    // Contains code from https://github.com/wslhub/wsl-sdk-dotnet/blob/892e8b5564170eae9944649cf8ab424ce0fbce52/src/Wslhub.Sdk/Wsl.cs#L364
    public static unsafe string WslLaunchGetOutput(
        string distributionName,
        string command,
        bool useCurrentWorkingDirectory,
        out uint exitCode,
        bool noStderr = false
    ) {
        var stdin = Kernel32Loader.GetStdHandle(Kernel32Loader.STD_INPUT_HANDLE);
        var stderr = Kernel32Loader.GetStdHandle(Kernel32Loader.STD_ERROR_HANDLE);

        var attributes = new Kernel32Loader.SECURITY_ATTRIBUTES {
            lpSecurityDescriptor = IntPtr.Zero,
            bInheritHandle = true,
        };
        attributes.nLength = Marshal.SizeOf(attributes);

        if (!Kernel32Loader.CreatePipe(out IntPtr readPipe, out IntPtr writePipe, ref attributes, 0))
            throw new Exception("Cannot create stdout pipe");

        var stderrRead = IntPtr.Zero;
        var stderrWrite = IntPtr.Zero;
        if (noStderr) {
            if (!Kernel32Loader.CreatePipe(out stderrRead, out stderrWrite, ref attributes, 0))
                throw new Exception("Cannot create stderr pipe");
            stderr = stderrWrite;
        }

        try {
            WslLaunch(distributionName, command, useCurrentWorkingDirectory, stdin, writePipe, stderr,
                out var hProcess);
            Kernel32Loader.WaitForSingleObject(hProcess, Kernel32Loader.INFINITE);

            if (!Kernel32Loader.GetExitCodeProcess(hProcess, out exitCode)) {
                Kernel32Loader.CloseHandle(hProcess);
                throw new Exception("Could not get exit code of WSL process");
            }

            Kernel32Loader.CloseHandle(hProcess);
            Kernel32Loader.CloseHandle(writePipe); // Make sure the pipe is closed if the spawned process has not done that

            const int bufferLength = 65536;
            var bufferPointer = Marshal.AllocHGlobal(bufferLength);
            var outputContents = new StringBuilder();
            var encoding = new UTF8Encoding(false);
            var read = 0;

            do {
                if (!Kernel32Loader.ReadFile(readPipe, bufferPointer, bufferLength, out read, IntPtr.Zero)) {
                    var lastError = Marshal.GetLastWin32Error();

                    if (lastError != 0) {
                        Marshal.FreeHGlobal(bufferPointer);
                        throw new Exception("Could not read from pipe");
                    }

                    break;
                }

                outputContents.Append(encoding.GetString((byte*)bufferPointer.ToPointer(), read));
            } while (read == bufferLength);

            Marshal.FreeHGlobal(bufferPointer);

            return outputContents.ToString();
        } finally {
            Kernel32Loader.CloseHandle(readPipe);
            Kernel32Loader.CloseHandle(writePipe);
            if (noStderr) {
                Kernel32Loader.CloseHandle(stderrRead);
                Kernel32Loader.CloseHandle(stderrWrite);
            }
        }
    }

}
