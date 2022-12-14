
@isTest(SeeAllData=true)
public class CIS_TestSpendBudgetHandler{
    static testMethod void handleAssetsInsert() {
        CIS_Contact__c contactOne = new CIS_Contact__c();
        contactOne.Name = 'TESTLASTNAME';
        contactOne.First_Name__c = 'TESTFIRSTNAME';
        contactOne.Type__c = 'Member of Congress';
        insert contactOne;
    
        CIS_MemberOfCongress__c memOfCongress = new CIS_MemberOfCongress__c();
        Schema.DescribeSObjectResult memOfCongressSchema = Schema.SObjectType.CIS_MemberOfCongress__c;
        Map<String,Schema.RecordTypeInfo> memOfCongressRecordTypeInfo = memOfCongressSchema.getRecordTypeInfosByName(); 
        memOfCongress.recordTypeId = memOfCongressRecordTypeInfo.get('Senate').getRecordTypeId();
        memOfCongress.State_of_Office__c = 'AL';
        memOfCongress.Region__c = '01';
        memOfCongress.Original_Budget__c = 10000.00;
        memOfCongress.Election_Year__c = '2010';
        memOfCongress.Member_of_Congress_Name__c = contactOne.Id;        
        insert memOfCongress;
        
        Schema.DescribeSObjectResult pmoOfficeSchema = Schema.SObjectType.CIS_Offices__c;
        Map<String,Schema.RecordTypeInfo> pmoOfficeRecordTypeInfo = pmoOfficeSchema.getRecordTypeInfosByName();      
        CIS_Offices__c pmoOffice = new CIS_Offices__c();
        pmoOffice.recordTypeId = pmoOfficeRecordTypeInfo.get('Senate').getRecordTypeId();
        pmoOffice.PMO_AO_Number__c = 'TE12';
        pmoOffice.Space_Assigned__c = 'GSA';
        pmoOffice.Member_ID__c = memOfCongress.Id;
        insert  pmoOffice;
        
      
        pmoOffice = [SELECT Id,Name, PMO_AO_Number__c,Member_ID__c FROM CIS_Offices__c WHERE PMO_AO_Number__c = 'TE12' and Member_ID__c = :memOfCongress.Id][0];

        CIS_Assets__c asset = new CIS_Assets__c();
        asset.Name = 'TE01';
        asset.CIS_Office__c = pmoOffice.Id;
        asset.Unit_Cost__c = 100;
        asset.Quantity__c = 2;
        asset.Expense_Type__c = 'B - Carpet/Drapes';
        insert asset;
        
        //After insert
        memOfCongress = [SELECT Id, Spent_Asset_Budget__c FROM CIS_MemberOfCongress__c WHERE Id = :memOfCongress.Id][0];
        asset = [SELECT Id, Total_Cost__c FROM CIS_Assets__c WHERE Id = :asset.Id ][0];
        System.assertEquals(memOfCongress.Spent_Asset_Budget__c,asset.Total_Cost__c);
    }


    static testMethod void handleAssetsUpdate() {
    Test.startTest();
        /*    
        // To test error condition
        CIS_Offices__c errorOffice = new CIS_Offices__c();  
        Schema.DescribeSObjectResult errorOfficeSchema = Schema.SObjectType.CIS_Offices__c;
        Map<String,Schema.RecordTypeInfo> errorOfficeRecordTypeInfo= errorOfficeSchema.getRecordTypeInfosByName();      
        errorOffice.recordTypeId = errorOfficeRecordTypeInfo.get('Senate').getRecordTypeId();
        errorOffice.PMO_AO_Number__c = 'ERRR';
        errorOffice.Space_Assigned__c = 'GSA';
        insert  errorOffice;

        CIS_Assets__c errorAsset = new CIS_Assets__c();
        errorAsset.Name = 'ERROR_TABLE';
        errorAsset.CIS_Office__c = errorOffice.Id;
        errorAsset.Unit_Cost__c = 100;
        errorAsset.Quantity__c = 2;
        Date errorOrdered = Date.newInstance(2010,12,2);
        errorAsset.Date_Ordered__c = errorOrdered ;
        Date errorReceived = Date.newInstance(2011,12,2);
        errorAsset.Date_Received__c = errorReceived;
        insert errorAsset;
        */

        CIS_Contact__c contactOne = new CIS_Contact__c();
        contactOne.Name = 'TESTLASTNAME';
        contactOne.First_Name__c = 'TESTFIRSTNAME';
        contactOne.Type__c = 'Member of Congress';
        insert contactOne;
        contactOne =[select Id,Name,First_Name__c from CIS_Contact__c where Name = 'TESTLASTNAME' and First_Name__c = 'TESTFIRSTNAME'][0];
        
        CIS_MemberOfCongress__c memOfCongress = new CIS_MemberOfCongress__c();
        Schema.DescribeSObjectResult memOfCongressSchema = Schema.SObjectType.CIS_MemberOfCongress__c;
        Map<String,Schema.RecordTypeInfo> memOfCongressRecordTypeInfo = memOfCongressSchema.getRecordTypeInfosByName(); 
        memOfCongress.recordTypeId = memOfCongressRecordTypeInfo.get('Senate').getRecordTypeId();
        memOfCongress.State_of_Office__c = 'AL';
        memOfCongress.Region__c = '01';
        memOfCongress.Original_Budget__c = 10000.00;
        memOfCongress.Election_Year__c = '2010';
        memOfCongress.Member_of_Congress_Name__c = contactOne.Id;
        insert memOfCongress;
        
        Schema.DescribeSObjectResult pmoOfficeSchema = Schema.SObjectType.CIS_Offices__c;
        Map<String,Schema.RecordTypeInfo> pmoOfficeRecordTypeInfo = pmoOfficeSchema.getRecordTypeInfosByName();      
        CIS_Offices__c pmoOffice = new CIS_Offices__c();
        pmoOffice.recordTypeId = pmoOfficeRecordTypeInfo.get('Senate').getRecordTypeId();
        pmoOffice.PMO_AO_Number__c = 'TE12';
        pmoOffice.Space_Assigned__c = 'GSA';
        pmoOffice.City__c = 'TEST LOCATION';        
        pmoOffice.Member_ID__c = memOfCongress.Id;
        insert  pmoOffice;

        // Changing assets from one senator to another senetor
        
        CIS_Contact__c contact22 = new CIS_Contact__c();
        contact22.Name = 'TESTLASTNAME22';
        contact22.First_Name__c = 'TESTFIRSTNAME22';
        contact22.Type__c = 'Member of Congress';        
        insert contact22;
                
        CIS_MemberOfCongress__c memOfCongress22 = new CIS_MemberOfCongress__c();
        Schema.DescribeSObjectResult memOfCongressOneSchema = Schema.SObjectType.CIS_MemberOfCongress__c;
        Map<String,Schema.RecordTypeInfo> memOfCongressOneRecordTypeInfo = memOfCongressOneSchema.getRecordTypeInfosByName(); 
        memOfCongress22.recordTypeId = memOfCongressOneRecordTypeInfo.get('Senate').getRecordTypeId();
        memOfCongress22.State_of_Office__c = 'AL';
        memOfCongress22.Region__c = '01';
        memOfCongress22.Original_Budget__c = 20000.00;
        memOfCongress22.Election_Year__c = '2010';
        memOfCongress22.Member_of_Congress_Name__c = contact22.Id;         
        insert memOfCongress22;
        
        CIS_Offices__c pmoOfficeOne = new CIS_Offices__c();  
        Schema.DescribeSObjectResult pmoOfficeOneSchema = Schema.SObjectType.CIS_Offices__c;
        Map<String,Schema.RecordTypeInfo> pmoOfficeOneRecordTypeInfo= pmoOfficeOneSchema.getRecordTypeInfosByName();      
        pmoOfficeOne.recordTypeId = pmoOfficeOneRecordTypeInfo.get('Senate').getRecordTypeId();
        pmoOfficeOne.PMO_AO_Number__c = 'MM13';
        pmoOfficeOne.Space_Assigned__c = 'GSA';
        pmoOfficeOne.City__c = 'TEST LOCATION';
        pmoOfficeOne.Member_ID__c = memOfCongress22.Id;
        insert  pmoOfficeOne;

        pmoOffice = [SELECT Id,Name, PMO_AO_Number__c,Member_ID__c FROM CIS_Offices__c WHERE PMO_AO_Number__c = 'TE12'][0];
        CIS_Assets__c asset = new CIS_Assets__c();
        asset.Name = 'TestTABLE';
        asset.CIS_Office__c = pmoOffice.Id;
        asset.Expense_Type__c = 'D - Furniture';
        asset.Unit_Cost__c = 100;
        asset.Quantity__c = 2;
        Date ordered = Date.newInstance(2010,12,2);
        asset.Date_Ordered__c = ordered;
        Date received = Date.newInstance(2011,12,2);
        asset.Date_Received__c = received;
        insert asset;
        
        //After insert
        memOfCongress = [select Id,Spent_Asset_Budget__c from CIS_MemberOfCongress__c where Id = :memOfCongress.Id][0];
        asset = [SELECT Id,CIS_Office__c,Unit_Cost__c,Total_Cost__c FROM CIS_Assets__c WHERE Id = :asset.Id and Name = 'TestTABLE'][0];
        System.assertEquals(memOfCongress.Spent_Asset_Budget__c,asset.Total_Cost__c);
        
        
        pmoOfficeOne = [SELECT Id,Name, PMO_AO_Number__c,Member_ID__c FROM CIS_Offices__c WHERE PMO_AO_Number__c = 'MM13' and Member_ID__c = :memOfCongress22.Id][0];
        asset = [SELECT Id,CIS_Office__c,Date_Ordered__c,Date_Received__c,Unit_Cost__c,Total_Cost__c FROM CIS_Assets__c WHERE Id = :asset.Id and Name = 'TestTABLE'][0];        
        asset.CIS_Office__c = pmoOfficeOne.Id;
        asset.Unit_Cost__c = 150;
        asset.Expense_Type__c = 'D - Furniture';
        update asset;
        
        asset = [SELECT Id, Total_Cost__c FROM CIS_Assets__c WHERE Id = :asset.Id and Name = 'TestTABLE'][0];
        memOfCongress22 = [select Id,Spent_Asset_Budget__c from CIS_MemberOfCongress__c where Id = :memOfCongress22.Id and Member_of_Congress_Name__c = :contact22.Id][0];        
        //System.assertEquals(memOfCongress22.Spent_Asset_Budget__c,asset.Total_Cost__c);
        

        //After insert - TESTING THE VALUE.
        asset = [SELECT Id, Total_Cost__c FROM CIS_Assets__c WHERE Id = :asset.Id ][0];
        memOfCongress = [select Id,Spent_Asset_Budget__c from CIS_MemberOfCongress__c where Id = :memOfCongress.Id][0];        
        //System.assertEquals(memOfCongress.Spent_Asset_Budget__c,asset.Total_Cost__c);



        //Creating storage OFFICE
        CIS_Offices__c storagePmoOffice = new CIS_Offices__c();  
        //Moving from Office to storage.
        //storagePmoOffice = [SELECT Id,Name, PMO_AO_Number__c,Member_ID__c FROM CIS_Offices__c WHERE PMO_AO_Number__c = '77ZA'];        
        if([SELECT Id,Name, PMO_AO_Number__c,Member_ID__c FROM CIS_Offices__c WHERE PMO_AO_Number__c = '77ZA'].size() > 0)
        {
            storagePmoOffice = [SELECT Id,Name, PMO_AO_Number__c,Member_ID__c FROM CIS_Offices__c WHERE PMO_AO_Number__c = '77ZA'][0];
        }
        else
        {
            storagePmoOffice.recordTypeId = pmoOfficeRecordTypeInfo.get('Senate').getRecordTypeId();
        	storagePmoOffice.PMO_AO_Number__c = '77ZA';
        	storagePmoOffice.City__c = 'TEST LOCATION';
        	storagePmoOffice.Space_Assigned__c = 'GSA';
        	insert  storagePmoOffice;
        }
        
        asset.CIS_Office__c = storagePmoOffice.Id;
        asset.Expense_Type__c = 'D - Furniture';
        update asset;
        
        //Moving from storage to Office.        
        asset.CIS_Office__c = pmoOfficeOne.Id;
        asset.Expense_Type__c = 'D - Furniture';
        update asset;
        


        //Creating storage OFFICE
        CIS_Offices__c execPmoOffice = new CIS_Offices__c();  
        if([SELECT Id,Name, PMO_AO_Number__c,Member_ID__c FROM CIS_Offices__c WHERE PMO_AO_Number__c = 'EXCS'].size() > 0)
        {
            execPmoOffice = [SELECT Id,Name, PMO_AO_Number__c,Member_ID__c FROM CIS_Offices__c WHERE PMO_AO_Number__c = 'EXCS'][0];
        }
        else
        {
            execPmoOffice.recordTypeId = pmoOfficeRecordTypeInfo.get('Senate').getRecordTypeId();
        	execPmoOffice.PMO_AO_Number__c = 'EXCS';
        	execPmoOffice.Space_Assigned__c = 'GSA';
        	insert  execPmoOffice;
        }
        /*
        execPmoOffice.recordTypeId = pmoOfficeRecordTypeInfo.get('Senate').getRecordTypeId();
        execPmoOffice.PMO_AO_Number__c = 'EXCS';
        execPmoOffice.Space_Assigned__c = 'GSA';
        insert  execPmoOffice;
        */
        Date ordered2 = Date.newInstance(1999,11,2);
        asset.Date_Ordered__c = ordered2;
        Date received2 = Date.newInstance(1999,12,2);
        asset.Date_Received__c = received2;
        asset.CIS_Office__c = execPmoOffice.Id;
        asset.Expense_Type__c = 'D - Furniture';
        update asset;
        
        /* NOT A VALID CONDITION
        //Moving excess to storage
        asset.CIS_Office__c = storagePmoOffice.Id;
        asset.Expense_Type__c = 'D - Furniture';
        update asset;
        */
        
        //Moving Storage to office
        asset.CIS_Office__c = pmoOfficeOne.Id;
        asset.Expense_Type__c = 'D - Furniture';
        update asset;
        
        
        //Moving office to exec
        asset.CIS_Office__c = execPmoOffice.Id;
        asset.Expense_Type__c = 'D - Furniture';
        update asset;
        
        //Moving office to exec
        asset.CIS_Office__c = pmoOffice.Id;
        asset.Expense_Type__c = 'D - Furniture';
        update asset;
        
        
        
        Test.stopTest();
 }
 
    static testMethod void handleAssetsDelete() {
        
        CIS_Contact__c contactOne = new CIS_Contact__c();
        contactOne.Name = 'TESTLASTNAME';
        contactOne.First_Name__c = 'TESTFIRSTNAME';
        contactOne.Type__c = 'Member of Congress';
        insert contactOne;
                
        CIS_MemberOfCongress__c memOfCongress = new CIS_MemberOfCongress__c();
        Schema.DescribeSObjectResult memOfCongressSchema = Schema.SObjectType.CIS_MemberOfCongress__c;
        Map<String,Schema.RecordTypeInfo> memOfCongressRecordTypeInfo = memOfCongressSchema.getRecordTypeInfosByName(); 
        memOfCongress.recordTypeId = memOfCongressRecordTypeInfo.get('Senate').getRecordTypeId();
        memOfCongress.State_of_Office__c = 'AL';
        memOfCongress.Region__c = '01';
        memOfCongress.Original_Budget__c = 10000.00;
        memOfCongress.Election_Year__c = '2010';
        memOfCongress.Member_of_Congress_Name__c = contactOne.Id;            
        insert memOfCongress;
        
        Schema.DescribeSObjectResult pmoOfficeSchema = Schema.SObjectType.CIS_Offices__c;
        Map<String,Schema.RecordTypeInfo> pmoOfficeRecordTypeInfo = pmoOfficeSchema.getRecordTypeInfosByName();      
        CIS_Offices__c pmoOffice = new CIS_Offices__c();
        pmoOffice.recordTypeId = pmoOfficeRecordTypeInfo.get('Senate').getRecordTypeId();
        pmoOffice.PMO_AO_Number__c = 'TE12';
        pmoOffice.Space_Assigned__c = 'GSA';
        pmoOffice.Member_ID__c = memOfCongress.Id;
        insert  pmoOffice;
        
      
        pmoOffice = [SELECT Id,Name, PMO_AO_Number__c,Member_ID__c FROM CIS_Offices__c WHERE PMO_AO_Number__c = 'TE12' and Member_ID__c = :memOfCongress.Id][0];

        CIS_Assets__c asset = new CIS_Assets__c();
        
//        Schema.DescribeSObjectResult assetSchema = Schema.SObjectType.sm1e__smEquipment__c;
//        Map<String,Schema.RecordTypeInfo> assetRecordTypeInfo = assetSchema.getRecordTypeInfosByName(); 
//        asset.recordTypeId = assetRecordTypeInfo.get('Furniture').getRecordTypeId();
        asset.Name = 'TE01';
        asset.CIS_Office__c = pmoOffice.Id;
        asset.Unit_Cost__c = 100;
        asset.Quantity__c = 2;
        asset.Expense_Type__c = 'D - Furniture';
        insert asset;
        //After insert
        memOfCongress = [SELECT Id, Spent_Asset_Budget__c FROM CIS_MemberOfCongress__c WHERE Id = :memOfCongress.Id][0];
        asset = [SELECT Id, Total_Cost__c FROM CIS_Assets__c WHERE Id = :asset.Id ][0];
        System.assertEquals(memOfCongress.Spent_Asset_Budget__c,asset.Total_Cost__c);
                
        Decimal oldSpendBudgetValue = memOfCongress.Spent_Asset_Budget__c;
        //After deletion of the ASSET
        delete asset;
        //After insert
        memOfCongress = [SELECT Id, Spent_Asset_Budget__c FROM CIS_MemberOfCongress__c WHERE Id = :memOfCongress.Id][0];
         
        System.assertEquals(memOfCongress.Spent_Asset_Budget__c,(oldSpendBudgetValue - 200));      
    }
 
}