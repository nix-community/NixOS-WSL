namespace Launcher;

public static class ExceptionContext {
    public static void AddContext(this Exception e, string context) => throw new ContextualizedException(context, e);

    public static void AddIfThrown(Action action, string context) {
        try {
            ArgumentNullException.ThrowIfNull(action);
            action();
        } catch (Exception e) {
            throw new ContextualizedException(context, e);
        }
    }
}

public class ContextualizedException : Exception {
    public ContextualizedException(string context, Exception innerException) : base(context, innerException) { }

    private ContextualizedException() { }
    private ContextualizedException(string message) : base(message) { }
}
