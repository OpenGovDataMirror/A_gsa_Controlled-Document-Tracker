
public class ApprovalStepCheckRecursive{
    // flag to identify the execution i.e first time or second time.
    private static Boolean alreadyUpdated = false;
    // method to return the flag value
    public static Boolean hasAlreadyUpdated(){
        return alreadyUpdated;
    }
    // method to set the flag to true
    public static void setAlreadyUpdated(){
        alreadyUpdated = true;
    }    
}