global without sharing class GrantAccessToChatterFiles {
	
	webservice static void grantAccessToCDChatterFiles(Id cdid){
		system.debug('===========>>>>>>> cdid ::: '+cdid);
		
		List<Controlled_Document_Feed__c> cdocList = [SELECT Id, Controlled_Document__c, User__c, Status__c
												FROM Controlled_Document_Feed__c 
												WHERE Controlled_Document__c = :cdid
												  AND User__c = :UserInfo.getUserId() 
												  AND Status__c = :'Pending' LIMIT 1];
		
		if(cdocList.isEmpty())	{
			Controlled_Document_Feed__c cdf = new Controlled_Document_Feed__c();
			cdf.Status__c = 'Pending';
			cdf.Controlled_Document__c = cdid;
			cdf.User__c = UserInfo.getUserId();
			insert cdf;
		}	
	}	
	
}