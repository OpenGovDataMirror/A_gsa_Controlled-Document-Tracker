
public class ControlledDocumentConstants {

	public static final String NOT_INITIATED_STATUS_STRING = 'Not Initiated';
	public static final String INITIATED_STATUS_STRING = 'Initiated';
	public static final String INITIATED_REOPENED_STATUS_STRING = 'Initiated/Reopened';
	public static final String EXTERNAL_REVIEW_ROLE_NAME = 'External Review';
	public static final String APPROVED_STATUS_STRING = 'Approved';
	public static final String HOLD_STATUS_STRING = 'Hold';
	public static final String PRE_OMB_STATUS_STRING = 'Pre-OMB';
	public static final String APPROVED_WITH_COMMENTS_STATUS_STRING = 'Approved w Comments';
	public static final String AWAITING_CLOSURE_STATUS_STRING = 'Awaiting Closure';
	public static final String AWAITING_SIGNATURE_STATUS_STRING = 'Awaiting Signature';
	public static final String CLOSED_STATUS_STRING = 'Closed';
	public static final String REJECTED_STATUS_STRING = 'Rejected';
	public static final String EXTERNAL_REVIEW_AUTOFILL_VALUE = 'OMB';
	public static final String CHATTER_FILE_SHARE_ERROR_MESSAGE = 'You cannot perform this action because you do not have proper permission to the related Chatter files. Press "Grant Access to Chatter Files" first.';
	public static final String OVERRIDE_EMAIL_SUBJECT = 'ExecSec Proxy request APPROVED for ';

	public static final String STAGE_AWAITING_CLOSURE = 'Awaiting Closure';
	public static final String STAGE_AWAITING_SIGNATURE = 'Awaiting Signature';
	public static final String STAGE_CLOSED = 'Closed';
	public static final String STAGE_CONCURRENCE = 'Concurrence';
	public static final String STAGE_DIRECTIVES_CLEARANCE = 'Directives Clearance';
	public static final String STAGE_DRAFTING = 'Drafting';
	public static final String STAGE_EXTERNAL_REVIEW = 'External Review';
	public static final String STAGE_HOLD = 'Hold';
	public static final String STAGE_INITIATED = 'Initiated';
	public static final String STAGE_PROGRAM_REVIEW = 'Program Review';
	public static final String STAGE_REVISE = 'Revise';

	public static final String LOCATION_SIMULTANEOUS_AGENCY_CLEARANCE = 'Simultaneous Agency Clearance';

	public static final String TYPE_ORDER = 'Order';
	public static final String TYPE_DIRECTIVE = 'Directive';
	public static final String TYPE_INSTRUCTIONAL_LETTER = 'Instructional Letter';

	//Jira SFEEO-1387, removed Office__c from map
	public static final Map<String,String> REQUIRED_FIELD_API_TO_LABEL_MAP = new Map<String,String>{'Sequence__c'=>'Sequence', 'Assigned_Approver__c'=>'Assigned Approver', 'Role_of_Approver__c'=>'Role of Approver', 'Due_Date__c'=>'Due Date'};


	//Approval Step Constants
	public static final String APPROVER = 'Approver';
	public static final String AUDIT_ANALYST = 'Audit Analysis';
	public static final String CLOSE_OUT = 'Close-Out';
	public static final String DRAFTER = 'Drafter';
	public static final String EDITOR = 'Editor';
	public static final String EXECSEC_REVIEWER = 'Exec Sec Reviewer';
	public static final String EXTERNAL_REVIEW = 'External Review';
	public static final String FYI = 'FYI';
	public static final String OFFICE_POC = 'Office POC';
	public static final String SIGNATORY = 'Signatory';
	public static final String APPROVER_SME = 'Approver (SME)';

	public static final List<String> EXECSEC_USER_PERMISSION_SET_NAMES = new List<String>{
			'Controlled_Document_Tracker_OAS_Admin_User_CRED',
			'Controlled_Document_Tracker_OAS_User_CRE'
	};



}