namespace WSL;

public class WslApiException : Exception {

    private long hresult;
    WslApiException(long hresult) {
        this.hresult = hresult;
    }

    public static void checkResult(long hresult) {
        if (hresult != 0) {
            throw new WslApiException(hresult);
        }
    }

    public override string Message => $"WSL API Error {hresult}";
}
