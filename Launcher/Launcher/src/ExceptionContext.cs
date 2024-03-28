namespace Launcher;

public static class ExceptionContext {
    public static void AddContext(this Exception e, string context) {
        throw new ExceptionWithContext(context, e);
    }

    public static void AddOnCatch(Action action, string context) {
        try {
            action();
        } catch (Exception e) {
            e.AddContext(context);
        }
    }

    internal class ExceptionWithContext : Exception {
        public ExceptionWithContext(string context, Exception innerException) : base(context, innerException) { }
    }
}
