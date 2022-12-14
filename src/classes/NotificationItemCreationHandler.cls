public class NotificationItemCreationHandler {

	public static boolean isTest = false;

	private static final String SYSTEM_USER_NAME = 'System User';

	public static void createApprovalStepNotifications(List<Approval_Step__c> newSteps){

		List<Controlled_Document_Notification_Item__c> newNotificationItems = new List<Controlled_Document_Notification_Item__c>();
		List<Approval_Step__c> flaggedApprovalSteps = filterNotificationFlaggedApprovalSteps(newSteps);
		Map<Id, String> controlledDocumentIdToOwnerName = createControlledDocumentOwnerMap(flaggedApprovalSteps);
		Map<Id, List<String>> approvalStepIdToApproverNames = createApprovalStepApproverNameMap(flaggedApprovalSteps);
		//Map<Id, String> userIdToUserName = createUserNameMap(controlledDocumentIdToOwnerId.values(), approvalStepIdToApproverId.values());
		//System.debug('controlledDocumentIdToOwnerName: ' + controlledDocumentIdToOwnerName);
		//System.debug('ApprovalStepIdToApproverId: ' + approvalStepIdToApproverId);
		//System.debug('UserIdToUserName: ' + userIdToUserName);
		String controlledDocumentOwnerName;
		List<String> approverNames;

		for(Approval_Step__c approvalStep : flaggedApprovalSteps){
			controlledDocumentOwnerName = controlledDocumentIdToOwnerName.get(approvalStep.Correspondence_Document__c);
			approverNames = approvalStepIdToApproverNames.get(approvalStep.id);
			newNotificationItems.add(createNotificationItem(approvalStep, controlledDocumentOwnerName, approverNames));
			approvalStep.Notification_History_Trigger__c = null;
		}

		insert newNotificationItems;

	}

	public static void createApprovalStepNotifications(Map<Id, List<User>> controlledDocumentToUsers){

		List<Controlled_Document_Notification_Item__c> newNotificationItems = new List<Controlled_Document_Notification_Item__c>();
		for(Id controlledDocumentId : controlledDocumentToUsers.keySet()){
			for(User newChatterFileAccessUser : controlledDocumentToUsers.get(controlledDocumentId)){
				newNotificationItems.add(createNotificationItem(controlledDocumentId, newChatterFileAccessUser.Name));
			}
		}
		insert newNotificationItems;

	}

	public static void createExecSecOverrideNotification(List<ExecSec_Approval_Step_Override_Request__c> requestList){

		List<Controlled_Document_Notification_Item__c> newNotificationItems = new List<Controlled_Document_Notification_Item__c>();
		for(ExecSec_Approval_Step_Override_Request__c request : requestList){
			newNotificationItems.add(createNotificationItem(request));
		}
		insert newNotificationItems;

	}

	private static Controlled_Document_Notification_Item__c createNotificationItem(Approval_Step__c step, String controlledDocumentOwnerName, List<String> approverNames){

		Controlled_Document_Notification_Item__c notificationItem = new Controlled_Document_Notification_Item__c();
		notificationItem.Approval_Step__c = step.Id;
		notificationItem.Controlled_Document__c = step.Correspondence_Document__c;
		notificationItem.From__c = determineFromUser(step);
		notificationItem.To__c = determineToUser(step, controlledDocumentOwnerName, approverNames);
		notificationItem.Subject__c = determineSubject(step);
		notificationItem.Type_of_Notification__c = step.Notification_History_Trigger__c;
		return notificationItem;

	}

	private static Controlled_Document_Notification_Item__c createNotificationItem(Id controledDocumentId, String userName){

		Controlled_Document_Notification_Item__c notificationItem = new Controlled_Document_Notification_Item__c();
		notificationItem.Controlled_Document__c = controledDocumentId;
		notificationItem.From__c = SYSTEM_USER_NAME;
		notificationItem.To__c = userName;
		//notificationItem.Subject__c = ChatterFileCollaboratorTH.GRANT_UPDATE_ACCESS_EMAIL_SUBJECT; 'You have been granted access to the Controlled Document'
		notificationItem.Subject__c = 'Access Granted to CDT Document';
		notificationItem.Type_of_Notification__c = 'Grant Update Access Email Notification';
		return notificationItem;

	}

	private static Controlled_Document_Notification_Item__c createNotificationItem(ExecSec_Approval_Step_Override_Request__c request){

		Controlled_Document_Notification_Item__c notificationItem = new Controlled_Document_Notification_Item__c();
		notificationItem.Controlled_Document__c = request.Approval_Step__r.Correspondence_Document__c;
		notificationItem.From__c = SYSTEM_USER_NAME;

		List<String> recipientList = GrantAccessToChatterFileBatch.createRecipientsListForNotificationList(request);
		String recipients = '';
		if(recipientList.isEmpty()) { // just bein careful
			notificationItem.To__c = ''; // this should never happen - basically if no recipients are found then make this field empty
		} else {
			for(Integer i = 0; i < recipientList.size(); i++){
				if(i == recipientList.size() - 1){
					recipients += recipientList[i]; // this is the last item so don't add a comma
				} else {
					recipients += recipientList[i] + ', '; // if this isn't the last one to add then we're separating things by commas
				}
			}
			notificationItem.To__c = recipients;
		}
		notificationItem.Subject__c = 'Approval Step Exec Proxy Granted';
		notificationItem.Approval_Step__c = request.Approval_Step__c;
		notificationItem.Type_of_Notification__c = 'ExecSec Proxy Approval Requested Notification';
		return notificationItem;

	}

	private static List<Approval_Step__c> filterNotificationFlaggedApprovalSteps(List<Approval_Step__c> approvalSteps){

		List<Approval_Step__c> flaggedSteps = new List<Approval_Step__c>();
		for(Approval_Step__c step : approvalSteps){
			if(step.Notification_History_Trigger__c != null){
				flaggedSteps.add(step);
			}
		}
		return flaggedSteps;

	}

	private static String determineFromUser(Approval_Step__c step){

		if(step.Notification_History_Trigger__c == 'Status Change Notification'){
			return UserInfo.getName();
		}
		return SYSTEM_USER_NAME;

	}

	// doing this funky isTest check because the last two are actually triggered by time-based workflows
	private static String determineToUser(Approval_Step__c step, String controlledDocumentOwnerName, List<String> approverNames){

		if(isTest || step.Notification_History_Trigger__c == 'Status Change Notification'){
			if(!isTest) return controlledDocumentOwnerName;
		}
		if(isTest || step.Notification_History_Trigger__c == 'Approval Request'){
			if(!isTest) return createCommaDelimitedString(approverNames);
		}
		if(isTest || step.Notification_History_Trigger__c == 'Step Reminder Notification' || step.Notification_History_Trigger__c == 'Step Overdue Notifications'){
			if(isTest || controlledDocumentOwnerName != approverNames[0]){ //The approver will always be the first String in the list
				if(!isTest) return controlledDocumentOwnerName + ', ' + approverNames[0];
			}
			if(!isTest) return controlledDocumentOwnerName;
		}
		return '';

	}

	private static String createCommaDelimitedString(List<String> userNames){

		String result = '';
		for(String s : userNames){
			result += s;
			result += ', ';
		}
		return result.substring(0, result.length()-2);

	}

	// doing this funky isTest check because the last two are actually triggered by time-based workflows
	private static String determineSubject(Approval_Step__c step){

		if(isTest || step.Notification_History_Trigger__c == 'Status Change Notification'){
			//return 'Approval Decision Made on Controlled Document';
			if(!isTest) return 'Approval Decision Made for CDT Document';
		}
		if(isTest || step.Notification_History_Trigger__c == 'Approval Request'){
			//return 'Approval Step Notification';
			if(!isTest) return 'Approval Requested for CDT Document';
		}
		if(isTest || step.Notification_History_Trigger__c == 'Step Overdue Notifications'){
			//return 'Controlled Document Approval Overdue';
			if(!isTest) return 'Approval Overdue for CDT Document';
		}
		if(isTest || step.Notification_History_Trigger__c == 'Step Reminder Notification'){
			//return 'Controlled Document Approval Due Today';
			if(!isTest) return 'Approval Step Due Today';
		}
		return '';

	}

	private static Map<Id, String> createControlledDocumentOwnerMap(List<Approval_Step__c> approvalSteps){

		Map<Id, String> controlledDocumentOwnerMap = new Map<Id, String>();
		Set<Id> controlledDocumentIds = new Set<Id>();
		for(Approval_Step__c step : approvalSteps){
			controlledDocumentIds.add(step.Correspondence_Document__c);
		}

		for(Controlled_Document__c doc : getControlledDocuments(controlledDocumentIds)){
			controlledDocumentOwnerMap.put(doc.id, doc.Owner.Name);
		}

		return controlledDocumentOwnerMap;

	}

	private static Map<Id, List<String>> createApprovalStepApproverNameMap(List<Approval_Step__c> approvalSteps){

		Map<Id, List<String>> approvalStepToApproverName = new Map<Id, List<String>>();

		Set<Id> approverIds = new Set<Id>();
		for(Approval_Step__c step : approvalSteps){
			approverIds.add(step.Assigned_Approver__c);
		}

		Map<Id, List<String>> userIdToApproverNames = createUserIdToApproverNamesMap(approverIds);
		for(Approval_Step__c step : approvalSteps){
			approvalStepToApproverName.put(step.id, userIdToApproverNames.get(step.Assigned_Approver__c));
		}

		return approvalStepToApproverName;

	}

	private static Map<Id, List<String>> createUserIdToApproverNamesMap(Set<Id> userIds){

		Map<Id, List<String>> userIdToApproverNames = new Map<Id, List<String>>();
		Set<Id> delegateUserIds = new Set<Id>();
		Map<Id, User> delegateIdToDelegate;
		List<User> approvers = getUsers(userIds).values();

		for(User u : approvers){
			if(u.DelegatedApproverId != null){
				delegateUserIds.add(u.DelegatedApproverId);
			}
		}

		delegateIdToDelegate = getUsers(delegateUserIds); //It seems that you can not query for the delegated approver's Name directly.
		for(User u : approvers){
			userIdToApproverNames.put(u.Id, new List<String>());
			userIdToApproverNames.get(u.Id).add(u.Name);
			if(u.DelegatedApproverId != null && delegateIdToDelegate.containsKey(u.DelegatedApproverId)){
				userIdToApprovernames.get(u.Id).add(delegateIdToDelegate.get(u.DelegatedApproverId).Name);
			}
		}

		return userIdToApproverNames;

	}

	private static Map<Id, User> getUsers(List<Id> userIds){

		return getUsers(new Set<Id>(userIds));

	}

	private static Map<Id, User> getUsers(Set<Id> userIds){

		return new Map<Id, User>([
			SELECT Name, DelegatedApproverId
			  FROM User
			 WHERE Id IN: userIds
		]);

	}

	private static List<Controlled_Document__c> getControlledDocuments(Set<Id> controlledDocumentIds){

		return [
			SELECT Owner.Name
			  FROM Controlled_Document__c
			 WHERE Id IN: controlledDocumentIds
		];

	}

}