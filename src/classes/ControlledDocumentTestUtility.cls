
 public class ControlledDocumentTestUtility {
	public static void createRequiredChatterGroups(){
		List<CollaborationGroup> newGroups = new List<CollaborationGroup>();
		if([SELECT id FROM CollaborationGroup WHERE Name = 'Chatter Support and Training'].size() == 0){
			newGroups.add(new CollaborationGroup(Name = 'Chatter Support and Training', CollaborationType='Public', OwnerId = UserInfo.getUserId()));
		}
		if([SELECT id FROM CollaborationGroup WHERE Name = 'Central'].size() == 0){
			newGroups.add(new CollaborationGroup(Name = 'Central', CollaborationType='Public', OwnerId = UserInfo.getUserId()));
		}

		insert newGroups;
	}

	public static Controlled_Document__c createTestControlDoc(){
		return new Controlled_Document__c();
	}

	public static Approval_Step__c createApprovalStep(Id ControlDocId, String sequenceNum, Id approverUserid){
		Approval_Step__c testStep = new Approval_Step__c(Correspondence_Document__c = ControlDocId,
		                                                 Sequence__c = sequenceNum,
		                                                 Assigned_Approver__c = approverUserId);
		return setApprovalStepRequiredFields(testStep);
	}

	public static Approval_Step__c setApprovalStepRequiredFields(Approval_Step__c approvalStep){
		approvalStep.Office__c = 'A - Office of the Administrator';
		approvalStep.Due_Date__c = System.today().addDays(7);
		approvalStep.Role_of_Approver__c = 'Approver';
		return approvalStep;
	}

	public static Approval_Step__c setApprovalStepRequiredFields(Approval_Step__c approvalStep, String sequenceNum, Id approverUserId){
		approvalStep.Sequence__c = sequenceNum;
		approvalStep.Assigned_Approver__c = approverUserId;
		approvalStep.Office__c = 'A - Office of the Administrator';
		approvalStep.Due_Date__c = System.today().addDays(7);
		approvalStep.Role_of_Approver__c = 'Approver';
		return approvalStep;
	}

	public static void initiateApprovalStep(Id approvalStepId){
		system.debug('InitiateApprovalStep UserName----------------'+UserInfo.getUserName());
		Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
		submitRequest.setObjectId(approvalStepId);
		submitRequest.setSubmitterId(UserInfo.getUserId());
		Approval.process(submitRequest);
	}

	public static void recallApprovalStep(Id approvalStep){
		Approval.ProcessWorkItemRequest recallRequest = new Approval.ProcessWorkItemRequest();
		recallRequest.setWorkItemId(getProcessWorkItem(approvalStep).get(0).Id);
		recallRequest.setAction('Removed');
		Approval.process(recallRequest);
	}

	public static void approveApprovalStep(Id approvalStep){
		Approval.ProcessWorkItemRequest recallRequest = new Approval.ProcessWorkItemRequest();
		recallRequest.setWorkItemId(getProcessWorkItem(approvalStep).get(0).Id);
		recallRequest.setAction('Approve');
		Approval.process(recallRequest);
	}

	public static FeedItem createFeedItem(Id controlDocumentId){
		return new FeedItem(ParentId = controlDocumentId,
		                    Type = 'ContentPost',
		                    ContentFileName = 'Test',
		                    ContentData = Blob.valueOf('1'));
	}

	public static void insertCollaborationTriggerControl(Boolean status){
		if(Collaboration_Trigger_Control__c.getall().values().size() == 0){
			insert new Collaboration_Trigger_Control__c(Name = 'TestControl',
				                                        Disable_Collaboration_Triggers__c = status);
		}
		else{
			Collaboration_Trigger_Control__c control = Collaboration_Trigger_Control__c.getall().values().get(0);
			control.Disable_Collaboration_Triggers__c = status;
			update control;
		}
	}

	public static Approval_Step__c getApprovalStep(Id approvalStepId){
		return [SELECT Correspondence_Document__c, Sequence__c, Assigned_Approver__c, 
		               Office__c, Due_Date__c, Role_of_Approver__c, LastModifiedById
		        FROM   Approval_Step__c
		        WHERE  id =: approvalStepId];
	}

	public static Controlled_Document__c getControlledDocument(Id controlledDocumentId){
		return [SELECT LastModifiedById
		        FROM   Controlled_Document__c
		        WHERE  Id =: controlledDocumentId];
	}

	public static List<ProcessInstanceWorkItem> getProcessWorkItem(Id approvalStepId){
		return [SELECT ProcessInstance.TargetObjectId
		        FROM ProcessInstanceWorkItem 
		        WHERE ProcessInstance.Status = 'Pending' AND 
		              ProcessInstance.TargetObjectId =: approvalStepId];
	}

	public static List<User> getStandardUsers(Integer lim){
		return [SELECT id 
		        FROM   User 
		        WHERE  ProfileId =: getProfileByName('Standard Platform User').Id AND 
		               isActive = true AND
		               UserType = 'Standard'
		        LIMIT: lim];
	}

	public static List<User> getStandardUsersWithDelegatedApprovers(Integer lim){
		return [SELECT Id
				FROM User
				WHERE ProfileId =: getProfileByName('Standard Platform User').Id AND 
		               isActive = true AND
		               UserType = 'Standard'
		               AND DelegatedApproverId != null
		        LIMIT: lim];
	}

	public static User getDelegateOfUser(Id userId){
		return [SELECT Id
				FROM User
				WHERE Id = :userId
				LIMIT 1];
	}

	public static ContentVersion getContentVersion(Id contentVersionId){
		return [SELECT ContentDocumentId 
		        FROM   ContentVersion 
		        WHERE  id =: contentVersionId];
	}

	public static List<ContentDocumentLink> getLinkForUserDocument(Id userId, Id contentDocId){
		return [SELECT Id, ShareType
		        FROM   ContentDocumentLink
		        WHERE  LinkedEntityId =: userId AND 
		               ContentDocumentId =: contentDocId];
	}

	public static FeedItem getFeedItem(Id feedItemId){
		return [SELECT Id, RelatedRecordId
		        FROM   FeedItem
		        WHERE  Id =: feedItemId];
	}

	public static Profile getProfileByName(String profileName){
		return [SELECT id
		        FROM   Profile
		        WHERE  Name =: profileName];
	}

}