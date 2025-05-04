public class EncryptionManager {
    
    static Blob iv = Blob.valueOf('Everfusion Best!');

    // Method to get the latest key and version
    public static Object_Encryption_Key__mdt getKey() {
        Object_Encryption_Key__mdt latestKey = [SELECT MasterLabel, AES_Key__c 
                                                FROM Object_Encryption_Key__mdt 
                                                ORDER BY  MasterLabel DESC
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
        if (plainText == null)
            return null;
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
        if (encryptedBase64Text == null)
            return null;
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

    public static String generateSHA256Hash(String input) {
        Blob inputBlob = Blob.valueOf(input);
        Blob hashBlob = Crypto.generateDigest('SHA-256', inputBlob);
        return EncodingUtil.convertToHex(hashBlob);
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
            SELECT Encrypted_Data_Field__c, Mask_Char__c, Mask_Type__c, Object_Name__c, Original_Data_Field__c, Hashed_Data_Field__c 
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
                String hashedField = config.Hashed_Data_Field__c;

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
                    if (!String.isBlank(hashedField)) {
                        String hashedValue = generateSHA256Hash((String)newValue);
                        newItem.put(hashedField, hashedValue);
                    }
                }
            }
        }
    }

    public static void createNewEncryptionKey() {
        // Query to get the latest version number
        // Get Last_Encryption_Key_Id custom label
        List<Object_Encryption_Key__mdt> latestKeys = [
            SELECT AES_Key__c, Version_Number__c 
            FROM Object_Encryption_Key__mdt 
            ORDER BY MasterLabel DESC
            LIMIT 1
        ];

        
        Integer newVersionNumber = (!latestKeys.isEmpty() && latestKeys[0].Version_Number__c != null) ? Integer.valueOf(latestKeys[0].Version_Number__c) + 1 : 1;
        String newAesKey = generateAESKey();
		String versionLabel = 'Version ' + String.valueOf(newVersionNumber).leftPad(5, '0');
        String developerName = 'Version_' + String.valueOf(newVersionNumber).leftPad(5, '0');        
        
        // Create metadata record
        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        customMetadata.fullName = 'Object_Encryption_Key__mdt.' + developerName;
        customMetadata.label = versionLabel;
        
        Metadata.CustomMetadataValue aesKeyValue = new Metadata.CustomMetadataValue();
        aesKeyValue.field = 'AES_Key__c';
        aesKeyValue.value = newAesKey;

        Metadata.CustomMetadataValue versionValue = new Metadata.CustomMetadataValue();
        versionValue.field = 'Version_Number__c';
        versionValue.value = newVersionNumber;

        customMetadata.values.add(aesKeyValue);
        customMetadata.values.add(versionValue);
        
        // Deploy metadata
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(customMetadata);
        Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, null);

        System.debug('Metadata deployment job ID: ' + jobId);
    }
    
    private static String generateAESKey() {
        // Generate a random 32-character AES key (mock implementation)
        return EncodingUtil.base64Encode(Crypto.generateAesKey(256));
    }

    public class DeploymentCallback implements Metadata.DeployCallback {
        private String developerName;
        
        public DeploymentCallback(String developerName) {
            this.developerName = developerName;
        }
        
        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
            
            if (result != null && result.success) {
                System.debug('Metadata deployment successful. Searching for keyId.');
                List<Object_Encryption_Key__mdt> keyRecords = [
                    SELECT Id 
                    FROM Object_Encryption_Key__mdt 
                    WHERE DeveloperName = :this.developerName
                    LIMIT 1
                ];
                
                if (!keyRecords.isEmpty()) {
                    String keyId = keyRecords[0].Id;
                    System.debug('Found keyId: ' + keyId + '. Updating custom label.');
                    updateLastEncryptionKeyId(keyId);
                } else {
                    System.debug('No matching key found for DeveloperName: ' + this.developerName);
                }
            } else {
                System.debug('Metadata deployment failed: ' + (result != null ? result.errorMessage : 'Unknown error'));
            }
        }
		
    }
    
    @future(callout=true)
    public static void updateLastEncryptionKeyId(String keyId) {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();

        // Define custom label metadata
        MetadataService.CustomLabel customLabel = new MetadataService.CustomLabel();
        customLabel.fullName = 'Last_Encryption_Key_Id';
        customLabel.value = keyId;
        customLabel.language = 'en_US';  // Default language

        // Perform the update
        MetadataService.SaveResult[] results = service.updateMetadata(new MetadataService.Metadata[] { customLabel });

        if (results != null && results[0].success) {
            System.debug('Custom Label updated successfully.');
        } else {
            System.debug('Error updating Custom Label: ' + results[0].errors[0].message);
        }
    }
}