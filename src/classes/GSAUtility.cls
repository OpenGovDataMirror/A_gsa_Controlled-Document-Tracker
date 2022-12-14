
public class GSAUtility {
/** 
* Passing Object and its Fields to the JSON method. The purpose of this menthod will convert into JSON variable
*/
 public static String getFieldValueFromObject(SObject obj, String fieldName) {
 //Serializing to JSON format
        String objJSON = JSON.serializePretty(obj);
//Parsing the serializd JSON        
        JSONParser parser = JSON.createParser(objJSON);
        String fieldValue = null;
//Looping through the fields        
        while (parser.nextToken() != null) {     
                       if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == fieldName)) {                       
                        parser.nextToken();
                        fieldValue = parser.getText();
                        system.debug('fieldvalue>>>>> ' + fieldvalue);
                        system.debug('fieldName>>>>' + fieldName);
                   //fieldValue = parser.getCurrentName();
                    }
            
        }
//Return field values        
         return fieldValue;
        }
    
    // map to hold global describe data
    private static Map<String,Schema.SObjectType> gd;
    
    // map to store objects and their prefixes
    private static Map<String, String> keyPrefixMap;

    // to hold set of all sObject prefixes
    private static Set<String> keyPrefixSet;
    
    public static String getApiNameByRecordId(String recId) {
        String tPrefix = recId;
        tPrefix = tPrefix.subString(0,3);
        
        // get all objects from the org
        gd = Schema.getGlobalDescribe();
        
        // to store objects and their prefixes
        //keyPrefixMap = new Map<String, String>{};
        
        //get the object prefix in IDs
        keyPrefixSet = gd.keySet();

        String apiName = null;       
        // fill up the prefixes map
        for(String sObj : keyPrefixSet)
        {            
            Schema.DescribeSObjectResult r =  gd.get(sObj).getDescribe();            
           
             String tempPrefix = r.getKeyPrefix();
             //system.debug('This is R ====>>>>> ' + r);
             apiName = r.getName(); 
             system.debug('This is before break ' + apiName);
             //Checking if the first 3 characters match             
              if(tPrefix.equals(tempPrefix)) {
               //system.debug('This is Result ' + apiName);
                //If there is a match breaking the loop
                break;
            }
        }
        //Returning Object API Name
        system.debug('API Name ' + apiName);
        return apiName;
    }
    
}