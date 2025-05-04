public class LogEventTriggerHandler extends TriggerHandler {
    public override void AfterInsert(Map<Id, SObject> newItems) {
        List<Log_Event__e> events =  (List<Log_Event__e>) newItems.Values();
        List<Log__c> logs = new List<Log__c>();
        for (Log_Event__e event : events) {
            Log__c log = new Log__c();
            log.Type_Name__c = event.Type_Name__c;
            log.Message__c = event.Message__c;
            log.Cause__c = event.Cause__c;
            log.Line_Number__c = event.Line_Number__c;
            log.Stack_Trace__c = event.Stack_Trace__c;
            log.Record_Id__c = event.Record_Id__c;
            log.request__c = event.request__c;
            log.response__c = event.response__c;
            log.End_Point__c = event.End_Point__c;
            logs.add(log);
        }
        insert logs;
    } 
}