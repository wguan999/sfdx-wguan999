public class FieldTrackingManager {
    public static void trackFieldChanges(String action, List<SObject> newItem, Map<Id, SObject> oldItem) {
        if (newItem.isEmpty()) return;
    
        // Get the object name from the first record in newItem list
        String objectName = newItem[0].getSObjectType().getDescribe().getName();
    
        // Query the Field_History_Tracking_Config__mdt for the specific object
        List<Field_History_Tracking_Config__mdt> configs = [
            SELECT Tracked_Fields__c 
            FROM Field_History_Tracking_Config__mdt 
            WHERE MasterLabel = :objectName
            LIMIT 1
        ];
    
        if (configs.isEmpty()) {
            return; // Exit if there's no tracking config for this object
        }
    
        // Use the first item in configs as the relevant tracking config
        Field_History_Tracking_Config__mdt config = configs[0];
    
        // Parse the Tracked_Fields__c configuration for the object
        List<String> trackedFields = config.Tracked_Fields__c.split(',');
        Map<String, Integer> fieldLengths = new Map<String, Integer>();
        for (String fieldInfo : trackedFields) {
            List<String> parts = fieldInfo.split(':');
            String fieldName = parts[0];
            Integer maxLength = (parts.size() > 1) ? Integer.valueOf(parts[1]) : null;
            fieldLengths.put(fieldName, maxLength);
        }
    
        List<Field_History_Tracking_Event__e> events = new List<Field_History_Tracking_Event__e>();
        Id currentUserId = UserInfo.getUserId();
        DateTime currentDateTime = DateTime.now();
        
        for (SObject newRecord : newItem) {
            Map<String, Map<String, Object>> changes = new Map<String, Map<String, Object>>();
    
            if (action == 'insert') {
                for (String fieldName : fieldLengths.keySet()) {
                    Object newValue = newRecord.get(fieldName);
                    changes.put(fieldName, new Map<String, Object>{
                        'originalValue' => null,
                        'newValue' => newValue
                    });
                }
            } else if (action == 'delete') {
                SObject oldRecord = oldItem.get(newRecord.Id);
                for (String fieldName : fieldLengths.keySet()) {
                    Object oldValue = oldRecord.get(fieldName);
                    changes.put(fieldName, new Map<String, Object>{
                        'originalValue' => oldValue,
                        'newValue' => null
                    });
                }
            } else if (action == 'update') {
                SObject oldRecord = oldItem.get(newRecord.Id);
                for (String fieldName : fieldLengths.keySet()) {
                    Object oldValue = oldRecord.get(fieldName);
                    Object newValue = newRecord.get(fieldName);
                    if (oldValue != newValue) {
                        changes.put(fieldName, new Map<String, Object>{
                            'originalValue' => oldValue,
                            'newValue' => newValue
                        });
                    }
                }
            }
    
            // Construct the JSON change event
            List<Map<String, Object>> changeList = new List<Map<String, Object>>();
            for (String fieldName : changes.keySet()) {
                Map<String, Object> fieldChange = new Map<String, Object>{
                    'fieldName' => fieldName,
                    'originalValue' => truncateValue(changes.get(fieldName).get('originalValue'), fieldLengths.get(fieldName)),
                    'newValue' => truncateValue(changes.get(fieldName).get('newValue'), fieldLengths.get(fieldName))
                };
                changeList.add(fieldChange);
            }
            
            // Generate a new Field_History_Tracking_Event__e event
            Field_History_Tracking_Event__e event = new Field_History_Tracking_Event__e();
            event.Change_Event__c = JSON.serialize(changeList);
            event.Date__c = currentDateTime;
            event.User_Id__c = currentUserId;
            event.Object_Id__c = newRecord.Id;
            event.Object_Name__c = objectName;
            event.Action__c = action;
            
            events.add(event);
        }
        
        // Bulk insert the events
        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    }
    
    // Helper method to truncate values to the specified length
    private static Object truncateValue(Object value, Integer maxLength) {
        if (value == null || maxLength == null) return value;
        String strValue = String.valueOf(value);
        return strValue.length() > maxLength ? strValue.substring(0, maxLength) : strValue;
    }

}