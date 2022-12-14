
 public class ExceptionUtility {
	public static final String VALIDATION_EXCEPTION_IDENTIFIER = 'FIELD_CUSTOM_VALIDATION_EXCEPTION, ';
	public static final String CHATTER_FILE_SHARE_EXCPETION_IDENTIFIER = 'ChatterFileShareException: ';
	public static final String ERROR_MESSAGE_POSTFIX = ': []'; //This may or may not be consistent for all error messages. You have been warned.
	public static final String CUSTOM_EXCEPTION_POSTIX = 'Class.';
	public static String parseErrorMessage(String errorMessage){
		if(errorMessage.contains(VALIDATION_EXCEPTION_IDENTIFIER)){
			return parseValidationErrorMessage(errorMessage);
		}
		if(errorMessage.contains(CHATTER_FILE_SHARE_EXCPETION_IDENTIFIER)){
			return parseChatterFileShareErrorMessage(errorMessage);
		}
		return errorMessage;
	}

	private static String parseValidationErrorMessage(String errorMessage){
		Integer startLocation = errorMessage.indexOf(VALIDATION_EXCEPTION_IDENTIFIER) + VALIDATION_EXCEPTION_IDENTIFIER.length();
		Integer endLocation = errorMessage.length() - ERROR_MESSAGE_POSTFIX.length();
		return errorMessage.subString(startLocation, endLocation).trim();
	}

	private static String parseChatterFileShareErrorMessage(String errorMessage){
		Integer startLocation = errorMessage.indexOf(CHATTER_FILE_SHARE_EXCPETION_IDENTIFIER) + CHATTER_FILE_SHARE_EXCPETION_IDENTIFIER.length();
		Integer endLocation = errorMessage.indexOf(CUSTOM_EXCEPTION_POSTIX);
		return errorMessage.subString(startLocation, endLocation).trim();
	}
}