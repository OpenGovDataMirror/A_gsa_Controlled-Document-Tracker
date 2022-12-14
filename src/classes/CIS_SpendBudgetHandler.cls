
public class CIS_SpendBudgetHandler{ 
    public static  void handleAssetsInsert(Map<Id,CIS_Assets__c> newInventoryItemList) 
    {
        Set<Id> pmoOfficeIds = new Set<Id>();
        for (Id  assetId : newInventoryItemList.keySet())  
        {
            CIS_Assets__c asset = (CIS_Assets__c)newInventoryItemList.get(assetId);
            pmoOfficeIds.add(asset.CIS_Office__c);        
        }
        
        List<CIS_Offices__c> pmoOfficeList =  [select Id,Member_ID__c,PMO_AO_Number__c from CIS_Offices__c where Id IN :pmoOfficeIds]; 
       
        Map<Id,CIS_Offices__c> pmoOfficeMap = new Map<Id,CIS_Offices__c>();         
        for(CIS_Offices__c pmoOffice : pmoOfficeList)
        {
            if( !(pmoOffice.PMO_AO_Number__c.equalsIgnoreCase('EXCS')  || pmoOffice.PMO_AO_Number__c.equalsIgnoreCase('66AA')))
                pmoOfficeMap.put(pmoOffice.Id,pmoOffice);
        }
       
        List<CIS_MemberOfCongress__c> memOfCongressList = [select Id,Spent_Asset_Budget__c FROM CIS_MemberOfCongress__c where Id IN (select Member_ID__c from CIS_Offices__c where Id IN :pmoOfficeIds)];        
        Map<Id,CIS_MemberOfCongress__c> memOfCongressMap = new Map<Id,CIS_MemberOfCongress__c>();     
        for(CIS_MemberOfCongress__c memOfCongress : memOfCongressList)
        {
            memOfCongressMap.put(memOfCongress.Id,memOfCongress);
        }    
                
        //List<CIS_MemberOfCongress__c> updateCongress = new List<CIS_MemberOfCongress__c>();
        Map<Id,CIS_MemberOfCongress__c> updateCongressMap = new Map<Id,CIS_MemberOfCongress__c>();        
         
        for(Id assetKey : newInventoryItemList.KeySet())
        {
            CIS_Assets__c asset = newInventoryItemList.get(assetKey);
            if(!(asset.Expense_Type__c.equalsIgnoreCase('A - Expensed')))
            {
                if(pmoOfficeMap.containsKey(asset.CIS_Office__c))
                {
                    CIS_Offices__c pmoOffice = pmoOfficeMap.get(asset.CIS_Office__c);
                    if(memOfCongressMap.containsKey(pmoOffice.Member_ID__c))      
                    {          
                        CIS_MemberOfCongress__c memOfCongress = memOfCongressMap.get(pmoOffice.Member_ID__c);
                        if(memOfCongress.Spent_Asset_Budget__c == null)
                            memOfCongress.Spent_Asset_Budget__c = 0;
                        memOfCongress.Spent_Asset_Budget__c = memOfCongress.Spent_Asset_Budget__c + asset.Total_Cost__c;    
                        //updateCongress.add(memOfCongress);
                        if(updateCongressMap.containsKey(memOfCongress.Id))
                        {
                            updateCongressMap.remove(memOfCongress.Id);
                            updateCongressMap.put(memOfCongress.Id,memOfCongress);
                        }
                        else
                        {
                            updateCongressMap.put(memOfCongress.Id,memOfCongress);                        
                        }                            
                    }
                    else
                    {
                        asset.adderror('PmoOffice has to be associated with a Member of Congress.');
                    }
                }
            }      
        }
        /*
        if(updateCongress != null && updateCongress.size() > 0) 
            update updateCongress;
       */
        if(updateCongressMap != null && updateCongressMap .size() > 0)
        {
                List<CIS_MemberOfCongress__c> finalUpdateCongress = new List<CIS_MemberOfCongress__c>();
                for(Id memberOfCongressId : updateCongressMap.keySet())
                {
                    finalUpdateCongress.add(updateCongressMap.get(memberOfCongressId));
                }
                if(finalUpdateCongress != null && finalUpdateCongress.size() > 0)
                    update finalUpdateCongress;                
        }    
       
     }
    
    public static  void handleAssetsUpdate(Map<Id,CIS_Assets__c> newInventoryItemMap,Map<Id,CIS_Assets__c> oldInventoryItemMap) 
    {
        // New office details
        Set<Id> pmoOfficeIds = new Set<Id>();
        for (Id  assetId : newInventoryItemMap.keySet()) 
        {
            CIS_Assets__c asset = (CIS_Assets__c)newInventoryItemMap.get(assetId);
            pmoOfficeIds.add(asset.CIS_Office__c);        
        }
        
        List<CIS_Offices__c> pmoOfficeList =  [select Id,Member_ID__c,PMO_AO_Number__c from CIS_Offices__c where Id IN :pmoOfficeIds]; 
        Map<Id,CIS_Offices__c> pmoOfficeMap = new Map<Id,CIS_Offices__c>();         
        for(CIS_Offices__c pmoOffice : pmoOfficeList)
        {
            pmoOfficeMap.put(pmoOffice.Id,pmoOffice);
        }

        List<CIS_MemberOfCongress__c> memOfCongressList = [select Id,Spent_Asset_Budget__c FROM CIS_MemberOfCongress__c where Id IN (select Member_ID__c from CIS_Offices__c where Id IN :pmoOfficeIds)];        
        Map<Id,CIS_MemberOfCongress__c> memOfCongressMap = new Map<Id,CIS_MemberOfCongress__c>();     
        for(CIS_MemberOfCongress__c memOfCongress : memOfCongressList)
        {
            memOfCongressMap.put(memOfCongress.Id,memOfCongress);
        }    
        
        //Old office details
        Set<Id> pmoOldOfficeIds = new Set<Id>();
        for (Id  assetId : oldInventoryItemMap.keySet()) 
        {
            CIS_Assets__c asset = (CIS_Assets__c)oldInventoryItemMap.get(assetId);
            pmoOldOfficeIds .add(asset.CIS_Office__c);        
        }

        List<CIS_Offices__c> oldPmoOfficeList =  [select Id,Member_ID__c,PMO_AO_Number__c from CIS_Offices__c where Id IN :pmoOldOfficeIds]; 
        Map<Id,CIS_Offices__c> oldPmoOfficeMap = new Map<Id,CIS_Offices__c>();         
        for(CIS_Offices__c pmoOffice : oldPmoOfficeList)
        {
            oldPmoOfficeMap.put(pmoOffice.Id,pmoOffice);
        }
        
        List<CIS_MemberOfCongress__c> oldMemOfCongressList = [select Id,Spent_Asset_Budget__c FROM CIS_MemberOfCongress__c where Id IN (select Member_ID__c from CIS_Offices__c where Id IN :pmoOldOfficeIds)];        
        Map<Id,CIS_MemberOfCongress__c> oldMemOfCongressMap = new Map<Id,CIS_MemberOfCongress__c>();     
        for(CIS_MemberOfCongress__c memOfCongress : oldMemOfCongressList)
        {
            oldMemOfCongressMap.put(memOfCongress.Id,memOfCongress);
        }    
        
        //List<CIS_MemberOfCongress__c> updateCongress = new List<CIS_MemberOfCongress__c>();
        Map<Id,CIS_MemberOfCongress__c> updateCongressMap = new Map<Id,CIS_MemberOfCongress__c>();        
        
        for(Id assetKey : newInventoryItemMap.KeySet())
        {
            CIS_Assets__c asset = newInventoryItemMap.get(assetKey);
            CIS_Assets__c oldAsset = oldInventoryItemMap.get(assetKey);
            if(!(asset.Expense_Type__c.equalsIgnoreCase('A - Expensed')))
            {
                if(pmoOfficeMap.containsKey(asset.CIS_Office__c))
                {
                    CIS_Offices__c pmoOffice = pmoOfficeMap.get(asset.CIS_Office__c);
                    CIS_Offices__c oldPmoOffice = oldPmoOfficeMap.get(oldAsset.CIS_Office__c);
                    
                    //Checking current PMO_AO_Number__c == 'EXCS' or '66AA'
                    if(pmoOffice.PMO_AO_Number__c.equalsIgnoreCase('EXCS')  || pmoOffice.PMO_AO_Number__c.equalsIgnoreCase('66AA') )
                    {
                        if(!(oldPmoOffice.PMO_AO_Number__c.equalsIgnoreCase('EXCS')  || oldPmoOffice.PMO_AO_Number__c.equalsIgnoreCase('66AA') || oldPmoOffice.PMO_AO_Number__c.equalsIgnoreCase('77ZA') ))
                        {
                            CIS_MemberOfCongress__c memOfCongress = oldMemOfCongressMap.get(oldPmoOffice.Member_ID__c);
                            if(memOfCongress.Spent_Asset_Budget__c == null)
                                memOfCongress.Spent_Asset_Budget__c = 0;
                            memOfCongress.Spent_Asset_Budget__c = memOfCongress.Spent_Asset_Budget__c - oldAsset.Total_Cost__c;    
                            if(updateCongressMap.containsKey(memOfCongress.Id))
                            {
                                updateCongressMap.remove(memOfCongress.Id);
                                updateCongressMap.put(memOfCongress.Id,memOfCongress);
                            }
                            else
                            {
                                updateCongressMap.put(memOfCongress.Id,memOfCongress);                        
                            }                            
                        }
                    }
                    else if(pmoOffice.PMO_AO_Number__c.equalsIgnoreCase('77ZA'))
                    {
                        if(!(oldPmoOffice.PMO_AO_Number__c.equalsIgnoreCase('EXCS')  || oldPmoOffice.PMO_AO_Number__c.equalsIgnoreCase('66AA') || oldPmoOffice.PMO_AO_Number__c.equalsIgnoreCase('77ZA') ))
                        {
                            CIS_MemberOfCongress__c memOfCongress = oldMemOfCongressMap.get(oldPmoOffice.Member_ID__c);
                            if(memOfCongress.Spent_Asset_Budget__c == null)
                                memOfCongress.Spent_Asset_Budget__c = 0;
                            memOfCongress.Spent_Asset_Budget__c = memOfCongress.Spent_Asset_Budget__c - oldAsset.Total_Cost__c;    
                            if(updateCongressMap.containsKey(memOfCongress.Id))
                            {
                                updateCongressMap.remove(memOfCongress.Id);
                                updateCongressMap.put(memOfCongress.Id,memOfCongress);
                            }
                            else
                            {
                                updateCongressMap.put(memOfCongress.Id,memOfCongress);                        
                            }                            
                        }
                    }
                    else if(oldPmoOffice.PMO_AO_Number__c != pmoOffice.PMO_AO_Number__c && memOfCongressMap.get(pmoOffice.Member_ID__c).Id == oldMemOfCongressMap.get(oldPmoOffice.Member_ID__c).Id)
                    {
                        //No action needed
                    }
                    else if(oldPmoOffice.PMO_AO_Number__c != pmoOffice.PMO_AO_Number__c)
                    {
                        //Updating the current Memeber spend budget
                        CIS_MemberOfCongress__c memOfCongress = memOfCongressMap.get(pmoOffice.Member_ID__c);
                        if(memOfCongress.Spent_Asset_Budget__c == null)
                            memOfCongress.Spent_Asset_Budget__c = 0;
                        memOfCongress.Spent_Asset_Budget__c = memOfCongress.Spent_Asset_Budget__c + asset.Total_Cost__c;    
                        if(updateCongressMap.containsKey(memOfCongress.Id))
                        {
                            updateCongressMap.remove(memOfCongress.Id);
                            updateCongressMap.put(memOfCongress.Id,memOfCongress);
                        }
                        else
                        {
                            updateCongressMap.put(memOfCongress.Id,memOfCongress);                        
                        }                            
    
                        //Updating the old Memeber spend budget     
                        if( !(oldPmoOffice.PMO_AO_Number__c.equalsIgnoreCase('EXCS')  || oldPmoOffice.PMO_AO_Number__c.equalsIgnoreCase('66AA') || oldPmoOffice.PMO_AO_Number__c.equalsIgnoreCase('77ZA')))                
                        {
                            CIS_MemberOfCongress__c oldMemOfCongress = oldMemOfCongressMap.get(oldPmoOffice.Member_ID__c);
                            if(oldMemOfCongress.Spent_Asset_Budget__c == null)
                                oldMemOfCongress.Spent_Asset_Budget__c = 0;
                            oldMemOfCongress.Spent_Asset_Budget__c = oldMemOfCongress.Spent_Asset_Budget__c - oldAsset.Total_Cost__c;    
                            //updateCongress.add(oldMemOfCongress);
                            if(updateCongressMap.containsKey(oldMemOfCongress.Id))
                            {
                                updateCongressMap.remove(oldMemOfCongress.Id);
                                updateCongressMap.put(oldMemOfCongress.Id,oldMemOfCongress);
                            }
                            else
                            {
                                updateCongressMap.put(oldMemOfCongress.Id,oldMemOfCongress);                        
                            }                            
                        }
                    }
                    else if(oldPmoOffice.PMO_AO_Number__c == pmoOffice.PMO_AO_Number__c)
                    {
                        //Updating the current Memeber spend budget
                        CIS_MemberOfCongress__c memOfCongress = memOfCongressMap.get(pmoOffice.Member_ID__c);
                        if(memOfCongress.Spent_Asset_Budget__c == null)
                            memOfCongress.Spent_Asset_Budget__c = 0;
                        memOfCongress.Spent_Asset_Budget__c = memOfCongress.Spent_Asset_Budget__c - oldAsset.Total_Cost__c + asset.Total_Cost__c;    
//                        updateCongress.add(memOfCongress);
                        if(updateCongressMap.containsKey(memOfCongress.Id))
                        {
                            updateCongressMap.remove(memOfCongress.Id);
                            updateCongressMap.put(memOfCongress.Id,memOfCongress);
                        }
                        else
                        {
                            updateCongressMap.put(memOfCongress.Id,memOfCongress);                        
                        }                            
                    }
                }
                else
                {
                    asset.adderror('PmoOffice has to be associated with a Member of Congress.');
                }
            }
        }   
        if(updateCongressMap != null && updateCongressMap .size() > 0)
        {
                List<CIS_MemberOfCongress__c> finalUpdateCongress = new List<CIS_MemberOfCongress__c>();
                for(Id memberOfCongressId : updateCongressMap.keySet())
                {
                    finalUpdateCongress.add(updateCongressMap.get(memberOfCongressId));
                }
                if(finalUpdateCongress != null && finalUpdateCongress.size() > 0)
                    update finalUpdateCongress;                
        }    
    }
   
    public static  void handleAssetsDelete(Map<Id,CIS_Assets__c> newInventoryItemList) 
    {
        Set<Id> pmoOfficeIds = new Set<Id>();
        for (Id  assetId : newInventoryItemList.keySet()) 
        {
            CIS_Assets__c asset = (CIS_Assets__c)newInventoryItemList.get(assetId);
            pmoOfficeIds.add(asset.CIS_Office__c);        
        }
        
        List<CIS_Offices__c> pmoOfficeList =  [select Id,Member_ID__c from CIS_Offices__c where Id IN :pmoOfficeIds]; 
       
        Map<Id,CIS_Offices__c> pmoOfficeMap = new Map<Id,CIS_Offices__c>();         
        for(CIS_Offices__c pmoOffice : pmoOfficeList)
        {
            pmoOfficeMap.put(pmoOffice.Id,pmoOffice);
        }

        List<CIS_MemberOfCongress__c> memOfCongressList = [select Id,Spent_Asset_Budget__c FROM CIS_MemberOfCongress__c where Id IN (select Member_ID__c from CIS_Offices__c where Id IN :pmoOfficeIds)];        
        Map<Id,CIS_MemberOfCongress__c> memOfCongressMap = new Map<Id,CIS_MemberOfCongress__c>();     
        for(CIS_MemberOfCongress__c memOfCongress : memOfCongressList)
        {
            memOfCongressMap.put(memOfCongress.Id,memOfCongress);
        }    
        Map<Id,CIS_MemberOfCongress__c> updateCongressMap = new Map<Id,CIS_MemberOfCongress__c>();        
        
        for(Id assetKey : newInventoryItemList.KeySet())
        {
            CIS_Assets__c asset = newInventoryItemList.get(assetKey);
            if(!(asset.Expense_Type__c.equalsIgnoreCase('A - Expensed')))
            {
                if(pmoOfficeMap.containsKey(asset.CIS_Office__c))
                {
                    CIS_Offices__c pmoOffice = pmoOfficeMap.get(asset.CIS_Office__c);
                    if(memOfCongressMap.containsKey(pmoOffice.Member_ID__c))      
                    {          
                        CIS_MemberOfCongress__c memOfCongress = memOfCongressMap.get(pmoOffice.Member_ID__c);
                        if(memOfCongress.Spent_Asset_Budget__c == null)
                            memOfCongress.Spent_Asset_Budget__c = 0;
                        memOfCongress.Spent_Asset_Budget__c = memOfCongress.Spent_Asset_Budget__c - asset.Total_Cost__c;    
                        //updateCongress.add(memOfCongress);
                        if(updateCongressMap.containsKey(memOfCongress.Id))
                        {
                            updateCongressMap.remove(memOfCongress.Id);
                            updateCongressMap.put(memOfCongress.Id,memOfCongress);
                        }
                        else
                        {
                            updateCongressMap.put(memOfCongress.Id,memOfCongress);                        
                        }                            
                    }
                    else
                    {
                        asset.adderror('PmoOffice has to be associated with a Member of Congress.');
                    }
                }
            }      
        }

        if(updateCongressMap != null && updateCongressMap .size() > 0)
        {
                List<CIS_MemberOfCongress__c> finalUpdateCongress = new List<CIS_MemberOfCongress__c>();
                for(Id memberOfCongressId : updateCongressMap.keySet())
                {
                    finalUpdateCongress.add(updateCongressMap.get(memberOfCongressId));
                }
                if(finalUpdateCongress != null && finalUpdateCongress.size() > 0)
                    update finalUpdateCongress;                
        }        
         
    }
}