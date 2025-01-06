public class EncryptionManager {
    
    static Blob iv = Blob.valueOf('Everfusion Best!');

    // Method to get the latest key and version
    public static Object_Encryption_Key__mdt getKey() {
        // Query for the latest key by DeveloperName in descending order
        Object_Encryption_Key__mdt latestKey = [SELECT MasterLabel, AES_Key__c 
                                                FROM Object_Encryption_Key__mdt 
                                                ORDER BY DeveloperName DESC 
                                                LIMIT 1];
        return latestKey;
    }

    // Method to get a specific key by version (e.g., "Version 2")
    public static Object_Encryption_Key__mdt getKey(String version) {
        // Query for the specified version
        Object_Encryption_Key__mdt specificKey = [SELECT MasterLabel, AES_Key__c 
                                                  FROM Object_Encryption_Key__mdt 
                                                  WHERE MasterLabel = :version 
                                                  LIMIT 1];
        return specificKey;
    }

    public static String encryptString(String plainText, String base64AESKey) {
        // Decode AES key and IV from base64
        Blob key = EncodingUtil.base64Decode(base64AESKey);
        Blob data = Blob.valueOf(plainText);
        
        System.debug(iv.size());
        // Perform AES encryption
        Blob encryptedData = Crypto.encrypt('AES256', key, iv, data);
        
        // Return encrypted string in base64
        return EncodingUtil.base64Encode(encryptedData);
    }
    
    public static String decryptString(String encryptedBase64Text, String base64AESKey) {
        // Decode the AES key, IV, and encrypted text from base64
        Blob key = EncodingUtil.base64Decode(base64AESKey);
        Blob encryptedData = EncodingUtil.base64Decode(encryptedBase64Text);
        
        // Perform AES decryption
        Blob decryptedData = Crypto.decrypt('AES256', key, iv, encryptedData);
        
        // Convert decrypted Blob back to string
        return decryptedData.toString();
    }    
    
    public static String encrypt(Object_Encryption_Key__mdt key, String plainText) {
        Map<String, Object> jsonMap = new Map<String, Object>();
        jsonMap.put('version', key.MasterLabel);
        jsonMap.put('encrypted', encryptString(plainText, key.AES_Key__c));        
        // Convert Map to JSON string
        return JSON.serialize(jsonMap);
    }
    
    public static String encrypt(String plainText) {
        Object_Encryption_Key__mdt key = getKey();
        Map<String, Object> jsonMap = new Map<String, Object>();
        jsonMap.put('version', key.MasterLabel);
        jsonMap.put('encrypted', encryptString(plainText, key.AES_Key__c));        
        // Convert Map to JSON string
        return JSON.serialize(jsonMap);
    }

    public static String decrypt(String encryptedJson) {
        Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(encryptedJson);
        Object_Encryption_Key__mdt key = getKey((String)jsonMap.get('version'));
        System.debug((String)jsonMap.get('encrypted'));
        return decryptString((String)jsonMap.get('encrypted'), key.AES_Key__c);
    }
    
    public static void applyEncryption(List<SObject> newItems, Map<Id, SObject> oldItems) {
        if (newItems.isEmpty()) {
            return;
        }

        // Determine the object type from the first record in newItems
        String objectName = newItems[0].getSObjectType().getDescribe().getName();

        // Query custom metadata to get encryption and masking configurations for this object
        List<Object_Encrypted_Data_Field__mdt> encryptedFieldsConfig = [
            SELECT Encrypted_Data_Field__c, Mask_Char__c, Mask_Type__c, Object_Name__c, Original_Data_Field__c
            FROM Object_Encrypted_Data_Field__mdt
            WHERE Object_Name__c = :objectName
        ];

        // Iterate over each item in newItems
        for (SObject newItem : newItems) {
            Id recordId = newItem.Id;
            SObject oldItem = oldItems != null && recordId != null ? oldItems.get(recordId) : null;

            // Process each field that needs encryption and masking based on the metadata configuration
            for (Object_Encrypted_Data_Field__mdt config : encryptedFieldsConfig) {
                String originalField = config.Original_Data_Field__c;
                String encryptedField = config.Encrypted_Data_Field__c;

                // Check if field exists on the SObject
                if (!newItem.getSObjectType().getDescribe().fields.getMap().containsKey(originalField) ||
                    !newItem.getSObjectType().getDescribe().fields.getMap().containsKey(encryptedField)) {
                    continue;
                }

                // Get original field value from newItem and compare with oldItem if it's an update
                Object newValue = newItem.get(originalField);
                Object oldValue = oldItem != null ? oldItem.get(originalField) : null;

                // Determine if we should process encryption and masking (new insert or changed value)
                Boolean isInsert = oldItem == null;
                Boolean hasChanged = !isInsert && (newValue != oldValue && (newValue == null || !newValue.equals(oldValue)));

                if (isInsert || hasChanged) {
                    // Encrypt the value and set it in the encrypted field
                    String encryptedValue = EncryptionManager.encrypt((String)newValue);
                    newItem.put(encryptedField, encryptedValue);

                    // Apply masking on the original field value based on mask type and character
                    
                    String maskedValue = MaskingPolicy.applyMask((String)newValue, config.Mask_Type__c, config.Mask_Char__c);    
                    newItem.put(originalField, maskedValue);
                }
            }
        }
    }

}