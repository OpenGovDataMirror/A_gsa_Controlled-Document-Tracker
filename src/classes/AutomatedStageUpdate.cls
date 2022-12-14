public with sharing class AutomatedStageUpdate {

    private static ApprovalStepDAI appStepDA = new ApprovalStepDA();


    public static void updateControlledDocumentStage(Controlled_Document__c newControlledDocument, Approval_Step__c latestStep){
        String inboundStage = newControlledDocument.Stage__c;
        
        
        if(inboundStage != ControlledDocumentConstants.STAGE_HOLD || (inboundStage == ControlledDocumentConstants.STAGE_HOLD && latestStep.Approval_Status__c != 'Initiated/Closed')){
            String stage = getStageToUpdate(latestStep, newControlledDocument);
            newControlledDocument.Stage__c = stage;
        }
        
        if (inboundStage != newControlledDocument.Stage__c){
            newControlledDocument.Current_Stage_Start_Date_New__c = System.now().date();
            newControlledDocument.Days_On_Current_Stage_New__c = 0;
        }
    }

    public static void setMockDA(ApprovalStepDAMock dataAccessor){
        //use in test
        appStepDA = dataAccessor;
    }


    private static String getStageToUpdate(Approval_Step__c approvalStep, Controlled_Document__c document){
        String stageString = '';
        if(roleIsOfficePocOrDrafter(approvalStep.Role_of_Approver__c)){
            if (documentStageWasNotAutomatedAwayFromDrafting(approvalStep)){
                stageString = ControlledDocumentConstants.STAGE_DRAFTING;
            }else{
                stageString = ControlledDocumentConstants.STAGE_REVISE;
            }
        }else{
            if (docTypeIsDirectiveOrOrderOrInstructionalLetter(document.Correspondence_Type__c)){
                if (approvalStep.Role_of_Approver__c == ControlledDocumentConstants.EDITOR){
                    stageString = ControlledDocumentConstants.STAGE_CONCURRENCE;
                }else{
                    if(wasDocumentPreviouslyInReviseStage(document)){
                        stageString = ControlledDocumentConstants.STAGE_DIRECTIVES_CLEARANCE;
                    }else if (document.Stage__c == ControlledDocumentConstants.STAGE_DIRECTIVES_CLEARANCE) { //for ticket# RITM0636351 - BEGIN
                    	stageString = ControlledDocumentConstants.STAGE_DIRECTIVES_CLEARANCE;
                    } //for ticket# RITM0636351 - END
                    else{
                        stageString = ControlledDocumentConstants.STAGE_PROGRAM_REVIEW;
                    }
                }
            }else{
                if(roleIsApproverOrEditorOrReviewer(approvalStep.Role_of_Approver__c)){
                    stageString = ControlledDocumentConstants.STAGE_CONCURRENCE;
                }else{
                    System.debug('--- There is no stage for this approver role ---');
                    stageString = document.Stage__c;
                }
            }
        }
        return stageString;
    }


    private static Boolean roleIsOfficePocOrDrafter(String roleOfApprover){
        return (roleOfApprover == ControlledDocumentConstants.OFFICE_POC ||
                roleOfApprover == ControlledDocumentConstants.DRAFTER);
    }

    private static Boolean roleIsApproverOrEditorOrReviewer(String roleOfApprover){
        return (roleOfApprover == ControlledDocumentConstants.APPROVER ||
                roleOfApprover == ControlledDocumentConstants.APPROVER_SME ||
                roleOfApprover == ControlledDocumentConstants.EDITOR ||
                roleOfApprover == ControlledDocumentConstants.EXECSEC_REVIEWER);
    }

    private static Boolean docTypeIsDirectiveOrOrderOrInstructionalLetter(String docType){
        return (docType == ControlledDocumentConstants.TYPE_DIRECTIVE ||
                docType == ControlledDocumentConstants.TYPE_ORDER ||
                docType == ControlledDocumentConstants.TYPE_INSTRUCTIONAL_LETTER);
    }

    private static Boolean documentStageWasNotAutomatedAwayFromDrafting(Approval_Step__c approvalStep){
        List<Approval_Step__c> stepHistory = appStepDA.getAllInitiatedApprovalStepsWithControlledDocumentId(approvalStep.Correspondence_Document__c);
        for (Approval_Step__c step : stepHistory){
            if (!roleIsOfficePocOrDrafter(step.Role_of_Approver__c)){
                return false;
            }
        }
        return true;
    }

    private static Boolean wasDocumentPreviouslyInReviseStage(Controlled_Document__c document){
        //return document.Stage__c == ControlledDocumentConstants.STAGE_REVISE; // Commented for ticket # RITM0636351
        //for ticket# RITM0636351 - BEGIN
        if(document.Stage__c == ControlledDocumentConstants.STAGE_REVISE) {
            return true;
        } else {
            List<Location_and_Stage_History__c> reviseHistoryList = new List<Location_and_Stage_History__c>();
            reviseHistoryList = [SELECT Id, Stage__c, Controlled_Document__c FROM Location_and_Stage_History__c 
                                 WHERE Controlled_Document__c = :document.Id AND Stage__c = :ControlledDocumentConstants.STAGE_REVISE ];
            return ( (reviseHistoryList != null && !reviseHistoryList.isEmpty()) ? true : false);
        }    
        //for ticket# RITM0636351 - END
    }

}