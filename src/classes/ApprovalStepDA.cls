public with sharing class ApprovalStepDA implements ApprovalStepDAI{
    public List<Approval_Step__c> getAllInitiatedApprovalStepsWithControlledDocumentId(Id docId){
        return[
                SELECT Id,
                    LastModifiedDate,
                    Actual_Approver__c,
                    Approval_Status__c,
                    Approval_Step_Type__c,
                    Assigned_Approver__c,
                    Approver_s_Division_Code__c,
                    Approver_s_Division_Name__c,
                    Approver_s_Location__c,
                    Approver_s_Organization_Acronym__c,
                    Approver_s_Region_Location__c,
                    Office__c,
                    Comments__c,
                    Completed_Date__c,
                    Correspondence_Document__c,
                    Days_Open__c,
                    Marked_for_Deletion__c,
                    Delegate__c,
                    Document_Due_Date__c,
                    Document_Stage__c,
                    Document_Title__c,
                    Correspondence_Type__c,
                    Due_Date__c,
                    Exec_Sec_Proxy_Approval_Requested__c,
                    External_Review_Party__c,
                    Note_about_Approve_w_Comments__c,
                    Notification_History_Trigger__c,
                    Office_Portfolio__c,
                    Originating_Service_Staff_Office__c,
                    Region__c,
                    Role_of_Approver__c,
                    Sequence__c,
                    Start_Date__c,
                    Time_Initiated__c
                FROM Approval_Step__c
                WHERE Correspondence_Document__c = :docId
                    AND Approval_Status__c != 'Not Initiated'
                ORDER BY Time_Initiated__c DESC NULLS LAST
        ];
    }

    public List<Approval_Step__c> getAllInitiatedApprovalStepsWithControlledDocumentIds(List<Id> docIds){
        return[
                SELECT Id,
                        LastModifiedDate,
                        Actual_Approver__c,
                        Approval_Status__c,
                        Approval_Step_Type__c,
                        Assigned_Approver__c,
                        Approver_s_Division_Code__c,
                        Approver_s_Division_Name__c,
                        Approver_s_Location__c,
                        Approver_s_Organization_Acronym__c,
                        Approver_s_Region_Location__c,
                        Office__c,
                        Comments__c,
                        Completed_Date__c,
                        Correspondence_Document__c,
                        Days_Open__c,
                        Marked_for_Deletion__c,
                        Delegate__c,
                        Document_Due_Date__c,
                        Document_Stage__c,
                        Document_Title__c,
                        Correspondence_Type__c,
                        Due_Date__c,
                        Exec_Sec_Proxy_Approval_Requested__c,
                        External_Review_Party__c,
                        Note_about_Approve_w_Comments__c,
                        Notification_History_Trigger__c,
                        Office_Portfolio__c,
                        Originating_Service_Staff_Office__c,
                        Region__c,
                        Role_of_Approver__c,
                        Sequence__c,
                        Start_Date__c,
                        Time_Initiated__c
                FROM Approval_Step__c
                WHERE Correspondence_Document__c IN :docIds
                AND Approval_Status__c != 'Not Initiated'
                AND Approval_Status__c != 'Initiated/Closed'
                ORDER BY Time_Initiated__c DESC NULLS LAST
        ];
    }

    public List<AggregateResult> getMaxInitiatedTimeForDocumentIds(List<Id> docIds){
        return [SELECT Correspondence_Document__c,
                MAX(Time_Initiated__c)maxInitTime
        FROM Approval_Step__c
        WHERE Correspondence_Document__c IN :docIds
        GROUP BY Correspondence_Document__c];
    }

}