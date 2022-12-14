/*
CIS_AssetTrigger.cls
  Class for testing CIS_Assets__c  object
  -------------------------------------------------------------------------------
  Author                 Date        Version  Description
  -------------------------------------------------------------------------------
  Murugaboopathi         06/25/2012  1.0      Creation
*/

 
trigger CIS_AssetTrigger on CIS_Assets__c(after insert,before delete,after update) {
    if(Trigger.isInsert) 
    {
        CIS_SpendBudgetHandler.handleAssetsInsert(Trigger.newMap);
    }    
    else if(Trigger.isDelete)
    {
        CIS_SpendBudgetHandler.handleAssetsDelete(Trigger.oldMap);
    }     
    else if(Trigger.isUpdate && CIS_SpendBudgetHelperClass.firstRun)
    {
        Map<Id,CIS_Assets__c> newInventoryItemMap = new Map<Id,CIS_Assets__c>();
        Map<Id,CIS_Assets__c> oldInventoryItemMap = new Map<Id,CIS_Assets__c>();        
        CIS_SpendBudgetHandler.handleAssetsUpdate(Trigger.newMap,Trigger.oldMap);
        CIS_SpendBudgetHelperClass.firstRun=false;
    }        
}