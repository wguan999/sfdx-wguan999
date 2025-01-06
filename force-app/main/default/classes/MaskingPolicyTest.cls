@isTest
public class MaskingPolicyTest {
    @isTest
    static void testMaskAllCharacters() {
        String original = '1234567890';
        String result = MaskingPolicy.applyMask(original, MaskingPolicy.MaskType.MASK_ALL, '*');
        System.assertEquals('**********', result, 'All characters should be masked');
    }

    @isTest
    static void testLastFourClear() {
        String original = '1234567890';
        String result = MaskingPolicy.applyMask(original, MaskingPolicy.MaskType.LAST_FOUR_CLEAR, '*');
        System.assertEquals('******7890', result, 'Only the last four characters should be clear');
    }

    @isTest
    static void testCreditCardMask() {
        // Test various formats for Credit Card
        String[] testCases = new String[] { '1234567812345678', '1234-5678-1234-5678', '1234 5678 1234 5678' };
        for (String testCase : testCases) {
            String result = MaskingPolicy.applyMask(testCase, MaskingPolicy.MaskType.CREDIT_CARD, '*');
            System.assertEquals('XXXX-XXXX-XXXX-5678', result, 'Credit card mask should reveal only the last four digits');
        }
    }

    @isTest
    static void testNationalInsuranceMask() {
        // Test various formats for National Insurance
        String[] testCases = new String[] { 'AB123456C', 'AB-12-34-56-C', 'AB 12 34 56 C' };
        for (String testCase : testCases) {
            String result = MaskingPolicy.applyMask(testCase, MaskingPolicy.MaskType.NATIONAL_INSURANCE, '*');
            System.assertEquals('XX-XX-XX-56C', result, 'National Insurance mask should keep the last three characters visible');
        }
    }

    @isTest
    static void testSocialSecurityMask() {
        // Test various formats for Social Security
        String[] testCases = new String[] { '123456789', '123-45-6789', '123 45 6789' };
        for (String testCase : testCases) {
            String result = MaskingPolicy.applyMask(testCase, MaskingPolicy.MaskType.SOCIAL_SECURITY, '*');
            System.assertEquals('XXX-XX-6789', result, 'SSN mask should reveal only the last four digits');
        }
    }

    @isTest
    static void testSocialInsuranceMask() {
        // Test various formats for Social Insurance
        String[] testCases = new String[] { '123456789', '123-456-789', '123 456 789' };
        for (String testCase : testCases) {
            String result = MaskingPolicy.applyMask(testCase, MaskingPolicy.MaskType.SOCIAL_INSURANCE, '*');
            System.assertEquals('XXX-XXX-789', result, 'Social Insurance mask should reveal only the last three digits');
        }
    }

    @isTest
    static void testNoMaskCharacter() {
        String original = '1234567890';
        String result = MaskingPolicy.applyMask(original, MaskingPolicy.MaskType.MASK_ALL, 'None');
        System.assertEquals('', result, 'All characters should be replaced with an empty string when mask character is "None"');
    }

    @isTest
    static void testEmptyStringInput() {
        String original = '';
        String result = MaskingPolicy.applyMask(original, MaskingPolicy.MaskType.MASK_ALL, '*');
        System.assertEquals('', result, 'Empty input should return empty output');
    }

    @isTest
    static void testNullMaskCharacter() {
        String original = '1234567890';
        String result = MaskingPolicy.applyMask(original, MaskingPolicy.MaskType.MASK_ALL, null);
        System.assertEquals('1234567890', result, 'Null mask character should return the original string');
    }

    @isTest
    static void testShortStringLastFourClear() {
        String original = '123';
        String result = MaskingPolicy.applyMask(original, MaskingPolicy.MaskType.LAST_FOUR_CLEAR, '*');
        System.assertEquals('123', result, 'String shorter than four characters should not be masked');
    }
}