/*-------------------------------------------------------------------------------------------------*
  Controlled Document Trigger.
  Trigger on Approval Step to do the following:
   - Date Overdue Calculation if applicable
   - Date Difference Calculation
 *-------------------------------------------------------------------------------------------------*
  Author           | Date        | Version | Description
 *-------------------------------------------------------------------------------------------------*
  Sathish Durairaj   10/22/2014    1.0       Created
  Stefan Maurer      11/14/2014    2.0       Added ChatterFileCollaborator call/ApprovalStep Delete
  Christian Coleman  5/11/2015     3.0       Added LocationAndStageHistoryHelper and updated setDayFields
  Rajakumar P        9/15/2015     4.0       Case# 19424- ExecSec OverDue field calculation issue
  Rajakumar P        08/31/2016    5.0       Case#27460 - Validation to limit the ability to choose controls for the Administrator's signature.
  Rajakumar P        02/06/2017    6.0       Case# 30805 - fix the production issue
  Rajakumar P        02/16/2017    7.0       Case# 30880 - custom settings to store the agency admin name
  Steve Gray		 09/20/2018	   8.0       Jira SFEEO-1374 - Created helper class for this trigger and moved functionality over to the helper class
 *-------------------------------------------------------------------------------------------------*/

trigger ControlledDocumentTrigger on Controlled_Document__c (before insert, before update, after insert, after update) {

    CDT_Setting__mdt setting = [
            SELECT Allow_Trigger_Execution__c
            FROM CDT_Setting__mdt
            WHERE MasterLabel = 'Enhancement Release'
    ];

	System.debug('CDT Setting: ' + setting.Allow_Trigger_Execution__c);

    if (setting.Allow_Trigger_Execution__c) {
        // BEFORE
        if (Trigger.isBefore) {

            // BEFORE INSERT
            if (trigger.isInsert) {
                ControlledDocumentTriggerHelper.onBeforeInsert(trigger.new, trigger.oldMap);
            }

            // BEFORE UPDATE
            else if (trigger.isUpdate) {
                ControlledDocumentTriggerHelper.onBeforeUpdate(trigger.new, trigger.newMap, trigger.oldMap);
            }
        }

        // AFTER
        else {

            // AFTER INSERT
            if (trigger.isInsert) {
                ControlledDocumentTriggerHelper.onAfterInsert(trigger.new, trigger.oldMap);
            }

            // AFTER UPDATE
            if (trigger.isUpdate) {
                ControlledDocumentTriggerHelper.onAfterUpdate(trigger.new, trigger.oldMap);
            }
        }
    }


}