
@isTest
private class TestExceptionUtility {
	@isTest static void testParseValidationErrorMessage() {
		String errorString = 'This is an error message ' + ExceptionUtility.VALIDATION_EXCEPTION_IDENTIFIER + ' Missing field Name required. ' + ExceptionUtility.ERROR_MESSAGE_POSTFIX;

		Test.startTest();
		errorString = ExceptionUtility.parseErrorMessage(errorString);
		Test.stopTest();

		System.assertEquals('Missing field Name required.', errorString, 'Failed to extract desired Text.');
	}

	@isTest static void testParseChatterFileShareErrorMessage() {
		String errorString = 'This is an error message ' + ExceptionUtility.CHATTER_FILE_SHARE_EXCPETION_IDENTIFIER + ' Missing field Name required. ' + ExceptionUtility.CUSTOM_EXCEPTION_POSTIX;

		Test.startTest();
		errorString = ExceptionUtility.parseErrorMessage(errorString);
		Test.stopTest();

		System.assertEquals('Missing field Name required.', errorString, 'Failed to extract desired Text.');
	}

	@isTest static void testOtherErrorMessage() {
		String originalErrorString = 'This is an error message';
		String newErrorString;

		Test.startTest();
		newErrorString = ExceptionUtility.parseErrorMessage(originalErrorString);
		Test.stopTest();

		System.assertEquals(originalErrorString, newErrorString, 'Without matching to any known exceptions, ExceptionUtility should have returned the original errorMessage.');
	}
}