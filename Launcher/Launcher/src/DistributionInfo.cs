namespace Launcher;

internal static class DistributionInfo {
    public const string DisplayName = "NixOS";
    public const string WindowTitle = "NixOS";

    // Name that the distro is registered as in WSL. Can be overridden with --distro-name
    public static string Name = "NixOS";
}
