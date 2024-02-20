#pragma warning disable CA1416

using System.Runtime.InteropServices;
using System.Text;
using Windows.Win32.Foundation;
using Windows.Win32.Security;
using Windows.Win32.System.Console;
using Microsoft.Win32.SafeHandles;
using static Windows.Win32.PInvoke;

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
        var stdin = new SafeFileHandle(GetStdHandle(STD_HANDLE.STD_INPUT_HANDLE), false);
        var stderr = new SafeFileHandle(GetStdHandle(STD_HANDLE.STD_ERROR_HANDLE), false);

        var attributes = new SECURITY_ATTRIBUTES {
            lpSecurityDescriptor = null,
            bInheritHandle = true
        };
        attributes.nLength = (uint)Marshal.SizeOf(attributes);

        if (!CreatePipe(out var readPipe, out var writePipe, attributes, 0))
            throw new Exception("Cannot create stdout pipe");

        SafeFileHandle? stderrRead = null;
        SafeFileHandle? stderrWrite = null;
        if (noStderr) {
            if (!CreatePipe(out stderrRead, out stderrWrite, attributes, 0))
                throw new Exception("Cannot create stderr pipe");
            stderr = stderrWrite;
        }

        try {
            WslLaunch(distributionName, command, useCurrentWorkingDirectory, stdin, writePipe, stderr,
                out var hProcess);
            WaitForSingleObject(hProcess, INFINITE);

            if (!GetExitCodeProcess(hProcess, out exitCode)) {
                hProcess.Close();
                throw new Exception("Could not get exit code of WSL process");
            }

            hProcess.Close();
            writePipe.Close(); // Make sure the pipe is closed if the spawned process has not done that

            const int bufferLength = 65536;
            var bufferPointer = Marshal.AllocHGlobal(bufferLength);
            var outputContents = new StringBuilder();
            var encoding = new UTF8Encoding(false);
            var read = 0U;

            do {
                if (!ReadFile(new HANDLE(readPipe.DangerousGetHandle()), (byte*)bufferPointer, bufferLength, &read,
                        null)) {
                    var lastError = Marshal.GetLastWin32Error();

                    if (lastError != 0) {
                        Marshal.FreeHGlobal(bufferPointer);
                        throw new Exception("Could not read from pipe");
                    }

                    break;
                }

                outputContents.Append(encoding.GetString((byte*)bufferPointer.ToPointer(), (int)read));
            } while (read == bufferLength);

            Marshal.FreeHGlobal(bufferPointer);

            return outputContents.ToString();
        } finally {
            readPipe.Close();
            writePipe.Close();
            if (noStderr) {
                stderrRead?.Close();
                stderrWrite?.Close();
            }
        }
    }
}
