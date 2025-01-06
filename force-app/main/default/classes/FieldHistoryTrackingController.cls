public with sharing class FieldHistoryTrackingController {
    
    @AuraEnabled(cacheable=true)
    public static List<TrackingHistoryData> getFieldHistoryTrackingData(Id objectId) {
        List<TrackingHistoryData> trackingDataList = new List<TrackingHistoryData>();

        // Direct SOQL query on the Big Object
        Date startDate = Date.today().addYears(-30);
        List<Field_History_Data__b> historyRecords = [
            SELECT Action__c, Change_Event__c, CreatedById, CreatedDate, Date__c, Id, Object_Id__c, 
                   Object_Name__c, SystemModstamp, User_Id__c 
            FROM Field_History_Data__b 
            WHERE Object_Id__c = :objectId and Date__c >= :startDate
        ];

        // Step 2: Collect User IDs and Field IDs grouped by Object Name
        Set<Id> userIds = new Set<Id>();
        Map<String, Set<Id>> objectNameToFieldIdsMap = new Map<String, Set<Id>>();
        for (Field_History_Data__b record : historyRecords) {
            if (record.User_Id__c != null) {
                userIds.add(record.User_Id__c);
            }
        }

        // Step 3: Query User object to get User Names based on collected User IDs
        Map<Id, String> userIdToNameMap = new Map<Id, String>();
        if (!userIds.isEmpty()) {
            for (User user : [SELECT Id, Name FROM User WHERE Id IN :userIds]) {
                userIdToNameMap.put(user.Id, user.Name);
            }
        }
        
        // Process each record in the result list
        for (Field_History_Data__b record : historyRecords) {
            TrackingHistoryData trackingData = new TrackingHistoryData();
            trackingData.Action = record.Action__c;
            trackingData.ChangeEvent = record.Change_Event__c;
            trackingData.CreatedById = record.CreatedById;
            trackingData.CreatedDate = record.CreatedDate;
            trackingData.ChangeDate = record.Date__c; // Renamed from Date to ChangeDate
            trackingData.Id = record.Id;
            trackingData.ObjectId = record.Object_Id__c;
            trackingData.ObjectName = record.Object_Name__c;
            trackingData.SystemModstamp = record.SystemModstamp;
            trackingData.UserId = record.User_Id__c;
            trackingData.UserName = userIdToNameMap.get(record.User_Id__c);
            
            trackingDataList.add(trackingData);

            // Optional: Limit the number of results to avoid governor limits
            if (trackingDataList.size() >= 200) break;
        }

        return trackingDataList;
    }

    // Wrapper class to store the data and send to LWC
    public class TrackingHistoryData {
        @AuraEnabled public String Action;
        @AuraEnabled public String ChangeEvent;
        @AuraEnabled public Id CreatedById;
        @AuraEnabled public DateTime CreatedDate;
        @AuraEnabled public DateTime ChangeDate; // Renamed from Date to ChangeDate
        @AuraEnabled public Id Id;
        @AuraEnabled public Id ObjectId;
        @AuraEnabled public String ObjectName;
        @AuraEnabled public DateTime SystemModstamp;
        @AuraEnabled public String UserId;
        @AuraEnabled public String UserName;
    }
}