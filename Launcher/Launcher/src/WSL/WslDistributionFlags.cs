using System.Diagnostics.CodeAnalysis;

namespace Launcher.WSL;

public static partial class WslApiLoader {
    [Flags]
    [SuppressMessage("Naming", "CA1711")] // Flags suffix is appropriate
    public enum WslDistributionFlags {
        None = 0x0,
        EnableInterop = 0x1,
        AppendNtPath = 0x2,
        EnableDriveMounting = 0x4
    }

    public const WslDistributionFlags WslDistributionFlagsValid =
        WslDistributionFlags.EnableInterop |
        WslDistributionFlags.AppendNtPath |
        WslDistributionFlags.EnableDriveMounting;

    public const WslDistributionFlags WslDistributionFlagsDefault =
        WslDistributionFlags.EnableInterop |
        WslDistributionFlags.AppendNtPath |
        WslDistributionFlags.EnableDriveMounting;
}
