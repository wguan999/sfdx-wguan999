public with sharing class Platform_UnitOfWorkUtils {
    public static void saveUnitOfWork(Id uowId, String status, Log__c errorLog) {
        saveUnitOfWork(uowId, 0, status, errorLog);
    }

    public static void saveUnitOfWork(Id uowId, Integer numOfChildren, String status, Log__c errorLog) {
        System.debug('status: ' + status);
        Platform_Unit_of_Work__c uow = new Platform_Unit_of_Work__c();
        uow.Id = uowId;
        uow.Status__c = status;
        uow.Num_of_Children__c = numOfChildren;
        uow.Error_Log__c = (errorLog != null) ? errorLog.Id : null;
        try {
            update uow;
        } catch (Exception e) {
            Log.logError(e);
        }
    }

    public static void submit(Platform_UnitOfWork uow, String status) {
        Platform_Unit_of_Work_Event__e  event = new Platform_Unit_of_Work_Event__e(
            Creator__c = UserInfo.getUserId(),
            UOW_Processor__c = uow.uowProcessor,
            Payload__c = JSON.serialize(uow),
            Description__c = uow.description,
            Status__c = status
        );
        Database.SaveResult sr = EventBus.publish(event);
        
    }

    public static void execute(Platform_Unit_of_Work__c uow) {
        try {
            if (uow.UOW_Processor__c.contains('Callout')) {
                    System.enqueueJob(new UnitOfWorkUtilTask(uow.id));
            } else {
                run(uow);
            }
        } catch (Exception e) {
            saveUnitOfWork(uow.id, 'Error', Log.logError(uow.id, e));
        }
    }
    
    public static void run(Platform_Unit_of_Work__c uow) {
        Type t = Type.forName(null, uow.UOW_Processor__c);
        if (t == null) {
            saveUnitOfWork(uow.id, 'Error', Log.logError(uow.id, new Platform_Exception('Invalid class name: ' + uow.UOW_Processor__c)));
            return;
        }
        Platform_UnitOfWorkAbstractProcessor instance = (Platform_UnitOfWorkAbstractProcessor) t.newInstance();
        instance.setUowObject(uow);
        instance.execute();
    }

    public with sharing class UnitOfWorkUtilTask implements System.Queueable, Database.AllowsCallouts{
         String uowId = null;
         public UnitOfWorkUtilTask(String uowId) {
             this.uowId = uowId;
         }
 
         public void execute(System.QueueableContext ctx) {
            String message = null;
            Platform_Unit_of_Work__c uow = [Select Id, Creator__c, Description__c, Error_Log__c,Payload__c, Parent__c,
                            Status__c, UOW_Processor__c, Num_of_Children__c
                            from Platform_Unit_of_Work__c where id = :uowId];
            run(uow);
        }
    }

    public static Platform_UnitOfWork deserializeUnitOfWork(Map<String, Object> jsonMap) {
        // Create the current Platform_UnitOfWork object
        Platform_UnitOfWork obj = new Platform_UnitOfWork(
            (String) jsonMap.get('uowProcessor'),
            (Map<String, Object>) jsonMap.get('parameters'),
            (String) jsonMap.get('description'),
            (String) jsonMap.get('parentId'),
            (String) jsonMap.get('status')
        );
    
        // Handle 'subWorks' recursively
        if (jsonMap.containsKey('subWorks') && jsonMap.get('subWorks') != null) {
            Object subWorksRaw = jsonMap.get('subWorks');
            if (subWorksRaw instanceof List<Object>) {
                List<Object> subWorksList = (List<Object>) subWorksRaw;
                obj.subWorks = new List<Platform_UnitOfWork>();
                for (Object subWorkObj : subWorksList) {
                    if (subWorkObj instanceof Map<String, Object>) {
                        obj.subWorks.add(deserializeUnitOfWork((Map<String, Object>) subWorkObj));
                    } else {
                        System.debug('Unexpected subWorkObj type: ' + subWorkObj);
                    }
                }
            } else {
                System.debug('Unexpected subWorksRaw type: ' + subWorksRaw);
            }
        }
    
        // Handle 'nextWork' recursively
        if (jsonMap.containsKey('nextWork') && jsonMap.get('nextWork') != null) {
            Object nextWorkRaw = jsonMap.get('nextWork');
            if (nextWorkRaw instanceof Map<String, Object>) {
                obj.nextWork = deserializeUnitOfWork((Map<String, Object>) nextWorkRaw);
            } else {
                System.debug('Unexpected nextWorkRaw type: ' + nextWorkRaw);
            }
        }
    
        return obj;
    }

    
}