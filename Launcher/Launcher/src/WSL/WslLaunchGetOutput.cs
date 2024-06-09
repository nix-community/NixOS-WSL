using System.ComponentModel;
using System.Diagnostics.CodeAnalysis;
using System.Runtime.InteropServices;
using System.Text;

using Microsoft.Win32.SafeHandles;

using Windows.Win32.Foundation;
using Windows.Win32.Security;
using Windows.Win32.System.Console;

using static Windows.Win32.PInvoke;

namespace Launcher.WSL;

public static partial class WslApiLoader {
    // Contains code from https://github.com/wslhub/wsl-sdk-dotnet/blob/892e8b5564170eae9944649cf8ab424ce0fbce52/src/Wslhub.Sdk/Wsl.cs#L364
    [SuppressMessage("Maintainability", "CA1508")] // Compiler thinks (read == bufferLength) is always false, because read is set through a pointer
    [SuppressMessage("Maintainability", "CA1416")] // Some methods used here are not available on anything older than Windows XP
    public static unsafe string WslLaunchGetOutput(
        string distributionName,
        string command,
        bool useCurrentWorkingDirectory,
        out uint exitCode,
        bool noStderr = false
    ) {
        using SafeFileHandle realStdin = new(GetStdHandle(STD_HANDLE.STD_INPUT_HANDLE), false);
        using SafeFileHandle realStderr = new(GetStdHandle(STD_HANDLE.STD_ERROR_HANDLE), false);
        var stdin = realStdin;
        var stderr = realStderr;

        var attributes = new SECURITY_ATTRIBUTES {
            lpSecurityDescriptor = null,
            bInheritHandle = true
        };
        attributes.nLength = (uint) Marshal.SizeOf(attributes);

        if (!CreatePipe(out var readPipe, out var writePipe, attributes, 0))
            throw new IOException("Cannot create stdout pipe");

        SafeFileHandle? stderrRead = null;
        SafeFileHandle? stderrWrite = null;
        if (noStderr) {
            if (!CreatePipe(out stderrRead, out stderrWrite, attributes, 0))
                throw new IOException("Cannot create stderr pipe");
            stderr = stderrWrite;
        }

        try {
            SafeProcessHandle? hProcess = null;
            try {
                WslLaunch(distributionName, command, useCurrentWorkingDirectory, stdin, writePipe, stderr,
                    out hProcess);
                WaitForSingleObject(hProcess, INFINITE);

                if (!GetExitCodeProcess(hProcess, out exitCode)) {
                    hProcess.Close();
                    throw new Win32Exception("Could not get exit code of WSL process");
                }
            } finally {
                hProcess?.Close();
                hProcess?.Dispose();
            }

            const int bufferLength = 65536;
            var bufferPointer = Marshal.AllocHGlobal(bufferLength);
            var outputContents = new StringBuilder();
            var encoding = new UTF8Encoding(false);
            var read = 0U;

            do {
                if (!ReadFile(new HANDLE(readPipe.DangerousGetHandle()), (byte*) bufferPointer, bufferLength, &read,
                        null)) {
                    var lastError = Marshal.GetLastWin32Error();

                    if (lastError != 0) {
                        Marshal.FreeHGlobal(bufferPointer);
                        throw new IOException("Could not read from pipe");
                    }

                    break;
                }

                outputContents.Append(encoding.GetString((byte*) bufferPointer.ToPointer(), (int) read));
            } while (read == bufferLength);

            Marshal.FreeHGlobal(bufferPointer);

            return outputContents.ToString();
        } finally {
            readPipe.Close();
            writePipe.Close(); // Make sure the pipe is closed if the spawned process has not done that
            stderrRead?.Close();
            stderrWrite?.Close();
            readPipe.Dispose();
            writePipe.Dispose();
            stderrRead?.Dispose();
            stderrWrite?.Dispose();
        }
    }
}
