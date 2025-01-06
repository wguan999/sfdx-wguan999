public class MaskingPolicy {
    public enum MaskType {
        MASK_ALL,
        LAST_FOUR_CLEAR,
        CREDIT_CARD,
        NATIONAL_INSURANCE,
        SOCIAL_SECURITY,
        SOCIAL_INSURANCE
    }

    public static MaskType getMaskTypeFromString(String maskTypeStr) {
        switch on maskTypeStr {
            when 'Mask All Characters' {
                return MaskType.MASK_ALL;
            }
            when 'Last Four Characters Clear' {
                return MaskType.LAST_FOUR_CLEAR;
            }
            when 'Credit Card Number' {
                return MaskType.CREDIT_CARD;
            }
            when 'National Insurance Number' {
                return MaskType.NATIONAL_INSURANCE;
            }
            when 'Social Security Number' {
                return MaskType.SOCIAL_SECURITY;
            }
            when 'Social Insurance Number' {
                return MaskType.SOCIAL_INSURANCE;
            }
            when else {
                throw new IllegalArgumentException('Unknown mask type: ' + maskTypeStr);
            }
        }
    }

    public static String applyMask(String originalString, String maskType, String maskChar) {
        return applyMask(originalString, getMaskTypeFromString(maskType), maskChar);
    }

    public static String applyMask(String originalString, MaskType maskType, String maskChar) {
        if (String.isEmpty(originalString) || maskChar == null) {
            return originalString;
        }

        // Define the default mask character if "None" is selected
        maskChar = (maskChar == 'None') ? '' : maskChar;

        // Apply mask based on the mask type
        switch on maskType {
            when MASK_ALL {
                return maskChar.repeat(originalString.length());
            }
            when LAST_FOUR_CLEAR {
                if (originalString.length() <= 4) {
                    return originalString; // No masking needed
                }
                String maskedSection = maskChar.repeat(originalString.length() - 4);
                return maskedSection + originalString.substring(originalString.length() - 4);
            }
            when CREDIT_CARD {
                return maskCreditCard(originalString, maskChar);
            }
            when NATIONAL_INSURANCE {
                return maskNationalInsurance(originalString, maskChar);
            }
            when SOCIAL_SECURITY {
                return maskSocialSecurity(originalString, maskChar);
            }
            when SOCIAL_INSURANCE {
                return maskSocialInsurance(originalString, maskChar);
            }
            when else {
                return originalString; // Return original string if mask type is not recognized
            }
        }
    }

    private static String maskCreditCard(String creditCardNumber, String maskChar) {
        String normalizedCC = creditCardNumber.replaceAll('[^0-9]', '');
        if (normalizedCC.length() < 12) {
            return creditCardNumber; // Return original if format is invalid
        }
        return maskChar.repeat(4) + '-' + maskChar.repeat(4) + '-' + maskChar.repeat(4) + '-' + normalizedCC.substring(normalizedCC.length() - 4);
    }

    private static String maskNationalInsurance(String niNumber, String maskChar) {
        String normalizedNI = niNumber.replaceAll('[^A-Za-z0-9]', '');
        if (normalizedNI.length() != 9) {
            return niNumber; // Return original if format is invalid
        }
        return maskChar.repeat(2) + '-' + maskChar.repeat(2) + '-' + maskChar.repeat(2) + '-' + normalizedNI.substring(6);
    }

    private static String maskSocialSecurity(String ssn, String maskChar) {
        String normalizedSSN = ssn.replaceAll('[^0-9]', '');
        if (normalizedSSN.length() != 9) {
            return ssn; // Return original if format is invalid
        }
        return maskChar.repeat(3) + '-' + maskChar.repeat(2) + '-' + normalizedSSN.substring(5);
    }

    private static String maskSocialInsurance(String sin, String maskChar) {
        String normalizedSIN = sin.replaceAll('[^0-9]', '');
        if (normalizedSIN.length() != 9) {
            return sin; // Return original if format is invalid
        }
        return maskChar.repeat(3) + '-' + maskChar.repeat(3) + '-' + normalizedSIN.substring(6);
    }

}