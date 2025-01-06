public with sharing class EncryptedDataDisplayController {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getDecryptedFields(Id recordId, String objectName) {
        List<Map<String, String>> decryptedFieldList = new List<Map<String, String>>();
        
        // Query metadata for fields to be encrypted and masked
        List<Object_Encrypted_Data_Field__mdt> encryptedFieldsConfig = [
            SELECT Encrypted_Data_Field__c, Mask_Char__c, Mask_Type__c, Object_Name__c, Original_Data_Field__c
            FROM Object_Encrypted_Data_Field__mdt
            WHERE Object_Name__c = :objectName
        ];

        // Collect encrypted field API names for querying the actual record data
        List<String> encryptedFieldNames = new List<String>();
        for (Object_Encrypted_Data_Field__mdt config : encryptedFieldsConfig) {
            encryptedFieldNames.add(config.Encrypted_Data_Field__c);
        }

        // Query the actual record data with encrypted fields
        SObject record = Database.query('SELECT ' + 
            String.join(encryptedFieldNames, ',') + 
            ' FROM ' + objectName + ' WHERE Id = :recordId'
        );

        // Process each field defined in metadata
        for (Object_Encrypted_Data_Field__mdt config : encryptedFieldsConfig) {
            String encryptedFieldApi = config.Encrypted_Data_Field__c;
            String originalFieldApi = config.Original_Data_Field__c;
            String maskChar = config.Mask_Char__c;
            String maskType = config.Mask_Type__c;

            // Check if the encrypted field exists on the record and has a value
            if (!record.getSObjectType().getDescribe().fields.getMap().containsKey(encryptedFieldApi) ||
                record.get(encryptedFieldApi) == null) {
                continue; // Skip if field is not visible or value is null
            }

            // Decrypt the value
            String encryptedValue = (String)record.get(encryptedFieldApi);
            String decryptedValue = EncryptionManager.decrypt(encryptedValue);

            String fieldLabel = record.getSObjectType().getDescribe().fields.getMap().get(originalFieldApi).getDescribe().getLabel();

            // Add to the result list
            Map<String, String> fieldData = new Map<String, String>();
            fieldData.put('label', fieldLabel);
            fieldData.put('value', decryptedValue);
            decryptedFieldList.add(fieldData);
        }

        return decryptedFieldList;
    }
}