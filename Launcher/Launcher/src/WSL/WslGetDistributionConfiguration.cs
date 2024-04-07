using System.Data;
using System.Runtime.InteropServices;

using Windows.Win32.Foundation;

namespace Launcher.WSL;

public static partial class WslApiLoader {
    // Wrap this method, so that we can get a managed string array out of it instead of char***
    public static unsafe void WslGetDistributionConfiguration(
        string distributionName,
        out ulong distributionVersion,
        out ulong defaultUid,
        out WslDistributionFlags wslDistributionFlags,
        out string[] defaultEnvironmentVariables
    ) {
        [DllImport("wslapi.dll", CallingConvention = CallingConvention.Winapi, CharSet = CharSet.Unicode)]
        // ReSharper disable once LocalFunctionHidesMethod
        static extern HRESULT WslGetDistributionConfiguration(
            string distributionName,
            out ulong distributionVersion,
            out ulong defaultUid,
            out WslDistributionFlags wslDistributionFlags,
            out byte** defaultEnvironmentVariables,
            out ulong defaultEnvironmentVariableCount
        );

        byte** envv;
        ulong envc;

        CheckResult(
            WslGetDistributionConfiguration(
                distributionName,
                out distributionVersion,
                out defaultUid,
                out wslDistributionFlags,
                out envv,
                out envc)
        );

        defaultEnvironmentVariables = new string[envc];

        var anyNull = false;
        for (ulong i = 0; i < envc; i++) {
            var ptr = new IntPtr(*(envv + i)); // Get the pointer to the string at offset i and dereference it
            var str = Marshal
                .PtrToStringAnsi(ptr); // Create a managed string from the char* pointer (_needs_ to be ANSI)

            if (str == null) {
                anyNull = true;
                continue;
            }

            Marshal.FreeHGlobal(ptr); // Free the string

            defaultEnvironmentVariables[i] = str;
        }

        Marshal.FreeHGlobal(new IntPtr(envv)); // Free the array

        if (anyNull)
            throw new NoNullAllowedException(
                "One of the strings in the environment array returned by wslapi.dll is null");
    }
}
