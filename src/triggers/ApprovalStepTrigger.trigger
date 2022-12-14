/*-------------------------------------------------------------------------------------------------*
  Approval Step Trigger.
  Trigger on Approval Step to do the following:
   - Automated Apex Managed Sharing
   - Automated OOTB Approval Step creation
   - Date Difference Calculation
 *-------------------------------------------------------------------------------------------------*
  Author           | Date        | Version | Description
 *-------------------------------------------------------------------------------------------------*
  Stefan Maurer      09/23/2014    1.0       Created
  Sathish Durairaj   10/03/2014    1.1       Updated the trigger to accommodate all logic
  Raja Kumar P       02/22/2016    1.2       To invoke the due date validation case# 22035
  Raja Kumar P       03/10/2016    1.3       Prevent the recursion for case# 22417 (Unable to initiate more than 5 approval steps at the same time) 
  Raja Kumar P       08/11/2016    1.4       case#27165- Update the date validation to bypass during batch updates of days open calculation.
  Raja Kumar P       03/30/2017    1.5       case# 31205 - Implement the logic of permission sets to validate the CDT users
  Steve Gray		 09/20/2018	   2.0       Jira SFEEO-1374 - Created helper class for this trigger and moved functionality over to the helper class
 *-------------------------------------------------------------------------------------------------*/

trigger ApprovalStepTrigger on Approval_Step__c (after insert, after update, after delete, after undelete, before delete, before insert, before update) {

    CDT_Setting__mdt setting = [
            SELECT Allow_Trigger_Execution__c
            FROM CDT_Setting__mdt
            WHERE MasterLabel = 'Enhancement Release'
    ];

    System.debug('CDT Setting: ' + setting.Allow_Trigger_Execution__c);

    if (setting.Allow_Trigger_Execution__c) {
        if (Trigger.isBefore) {

            // BEFORE INSERT
            if (trigger.isInsert) {
                ApprovalStepTriggerHelper.onBeforeInsert(trigger.new, trigger.oldMap);
            }

            // BEFORE UPDATE
            if (trigger.isUpdate) {
                ApprovalStepTriggerHelper.onBeforeUpdate(trigger.new, trigger.old, trigger.newMap, trigger.oldMap);
            }

        } else {

            // AFTER INSERT
            if (Trigger.isInsert) {
                ApprovalStepTriggerHelper.onAfterInsert(trigger.new, trigger.old, trigger.newMap, trigger.oldMap);
            }

            // AFTER UPDATE
            else if (Trigger.isUpdate) {
                ApprovalStepTriggerHelper.onAfterUpdate(trigger.new, trigger.old, trigger.newMap, trigger.oldMap);
            }

            // AFTER UNDELETE
            else if (Trigger.isUndelete) {
                ApprovalStepTriggerHelper.onAfterUndelete(trigger.new, trigger.oldMap);
            }
        }
    }

}