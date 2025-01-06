public class EncryptionKeyMetadataManager {
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
        // Construct the DeveloperName format based on the version label
        String developerName = version.replace(' ', '_');
        
        // Query for the specified version
        Object_Encryption_Key__mdt specificKey = [SELECT MasterLabel, AES_Key__c 
                                                  FROM Object_Encryption_Key__mdt 
                                                  WHERE DeveloperName = :developerName 
                                                  LIMIT 1];
        return specificKey;
    }
}