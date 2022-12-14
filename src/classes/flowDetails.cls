public class flowDetails {
    @InvocableMethod
    public static List<String> callapex(List<String> recId){
        List<String> numlist = new List<String>();
        String msg='';
        System.debug('val'+String.valueof(recId[0]));
        try{
            Integer val=CDTBatchUtil.reassignExecSecUsers(recId[0]);
            if(val==-1){
                msg='You are not an ExecSec Admin. This action is not available to you.'; 
            }
            else if(val==0){
                msg='The step needs to be initiated in order for this button to work.';
            }
            else if(val==1){
                msg='Your request for Proxy Access is in process. You will receive an email once the request is complete.';
            }
            else if(val==2){
                msg='You already have a pending request to reassign this approval step. Please allow the system some time to process it.';
            }
            else{
                msg='Unexpected error. Please contact an admin. (CDTBatchUtil.cls)';
            }
        }
        catch(Exception e) {
            msg='There was an issue processing your request. Please contact a Salesforce admin. Error: ' + e.getMessage();
        }
        
        numlist.add(msg);
        System.debug(numlist);
        return numlist ;
    }
    
}