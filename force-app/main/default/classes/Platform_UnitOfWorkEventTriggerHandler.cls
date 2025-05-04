public class Platform_UnitOfWorkEventTriggerHandler extends TriggerHandler {
    public override void AfterInsert(Map<Id, SObject> newItems) {
        List<Platform_Unit_of_Work_Event__e> events =  (List<Platform_Unit_of_Work_Event__e>) newItems.Values();
        List<Platform_Unit_of_Work__c> uowObjects = new List<Platform_Unit_of_Work__c>();
        System.debug('UnitOfWorkEventTriggerHandler');
        try {
            for (Platform_Unit_of_Work_Event__e event : events) {
                system.debug('event ' + event);
                Platform_Unit_of_Work__c uowObject = new Platform_Unit_of_Work__c();
                uowObject.Id = event.UOW_Id__c;
                uowObject.Payload__c = event.Payload__c;
                uowObject.Creator__c = event.Creator__c;       
                uowObject.UOW_Processor__c = event.UOW_Processor__c;
                uowObject.Description__c = event.Description__c;
                uowObject.UOW_Processor__c = event.UOW_Processor__c;  
                uowObject.Parent__c = event.Parent__c;  
                uowObject.Status__c = event.Status__c;                              
                uowObjects.add(uowObject);
            } 
            upsert uowObjects;
            Map<Id, Platform_Unit_of_Work__c> nextUowObjectsMap = new Map<Id, Platform_Unit_of_Work__c>();
            List<Platform_Unit_of_Work__c> childrenUowObjects = new List<Platform_Unit_of_Work__c>();
            Set<Platform_Unit_of_Work__c> parentObjects = new Set<Platform_Unit_of_Work__c>();
            for (Platform_Unit_of_Work__c uowObject: uowObjects) {
            	Platform_Unit_of_Work_Config__mdt config = [Select Ignore_Eligible__c, Max_Size__c, has_Next__c from Platform_Unit_of_Work_Config__mdt where DeveloperName = :uowObject.UOW_Processor__c limit 1];
                Platform_UnitOfWork uow = (Platform_UnitOfWork) Platform_UnitOfWorkUtils.deserializeUnitOfWork((Map<String, Object>)JSON.deserializeUntyped(uowObject.Payload__c));
                if ((needToSplit(uow, (Integer)config.Max_Size__c) || hasSubWorks(uow)) && (uowObject.Num_of_Children__c == null || uowObject.Num_of_Children__c == 0)) {
                    List<Platform_Unit_of_Work__c> thisChildrenUowObjects = new List<Platform_Unit_of_Work__c>();
                    if (needToSplit(uow, (Integer)config.Max_Size__c)) {
                        thisChildrenUowObjects.addAll(split(uow, uowObject, (Integer)config.Max_Size__c));
                    }
                    if (hasSubWorks(uow)) {
                        thisChildrenUowObjects.addAll(createSubWorks(uow, uowObject));
                        
                    }
                    if (thisChildrenUowObjects.size() > 0) {
                        uowObject.Status__c = 'Processing';
                        parentObjects.add(uowObject);
                        childrenUowObjects.addAll(thisChildrenUowObjects);
                        uowObject.Num_of_Children__c = thisChildrenUowObjects.size();
                    }
                }
                if (uowObject.Next__c == null && uow.nextWork != null) {
                    Platform_Unit_of_Work__c nextUow = new Platform_Unit_of_Work__c(
                        UOW_Processor__c = uow.nextWork.uowProcessor,
                        Payload__c = JSON.serialize(uow.nextWork),
                        Description__c = uow.nextWork.description,
                        Status__c = 'Init',
                        Creator__c = uowObject.Creator__c
                    );
                    nextUowObjectsMap.put(uowObject.Id, nextUow);
                }
            }
            if (parentObjects.size() > 0) {
                update new List<Platform_Unit_of_Work__c>(parentObjects);
                insert childrenUowObjects;
            }
            childrenUowObjects = new List<Platform_Unit_of_Work__c>();
           
            for (Platform_Unit_of_Work__c uowObject: uowObjects) {
                Platform_UnitOfWork uow = (Platform_UnitOfWork) Platform_UnitOfWorkUtils.deserializeUnitOfWork((Map<String, Object>)JSON.deserializeUntyped(uowObject.Payload__c));
                if (uowObject.Next__c == null && uow.nextWork != null) {
                    
                }
            }
            if (parentObjects.size() > 0) {
                update new List<Platform_Unit_of_Work__c>(parentObjects);
                insert childrenUowObjects;
            }
            if (nextUowObjectsMap.size() > 0){
                insert nextUowObjectsMap.values();
                List<Platform_Unit_of_Work__c> updatePreviousUows = new List<Platform_Unit_of_Work__c>();
                for (String pid : nextUowObjectsMap.keySet()) {
                    Platform_Unit_of_Work__c uowObject = new Platform_Unit_of_Work__c();
                    uowObject.Id = pid;
                    uowObject.Next__c = nextUowObjectsMap.get(pid).Id;
                    updatePreviousUows.add(uowObject);
                }
                update updatePreviousUows;
            }
        }
        catch (Exception e) {
            Log.logError(e);
        }
  } 

    public boolean needToSplit(Platform_UnitOfWork uow, Integer maxSize) {
        List<Object> data = (List<Object>) uow.parameters.get('data');
        Integer size = (data == null) ? -1 : data.size();
        maxSize = (maxSize == null || maxSize == -1)? 2147483647 : maxSize;
        System.debug('size ' + size);
        System.debug('maxSize ' + maxSize);
        return maxSize < size;
    }

    public boolean hasSubWorks(Platform_UnitOfWork uow) {
        return uow.subWorks != null && uow.subWorks.size() > 0;
    }
    
    public List<Platform_Unit_of_Work__c> createSubWorks(Platform_UnitOfWork parentUow,  Platform_Unit_of_Work__c uowObject) {
		List<Platform_Unit_of_Work__c> childUows = new List<Platform_Unit_of_Work__c>();        
        for (Platform_UnitOfWork uow : parentUow.subWorks) {
            Platform_Unit_of_Work__c child = new Platform_Unit_of_Work__c(
                UOW_Processor__c = uow.uowProcessor,
                Payload__c = JSON.serialize(uow),
                Description__c = uow.description,
                Status__c = 'Queued',
                Creator__c = uowObject.Creator__c,
                Parent__c = uowObject.Id
            );
            childUows.add(child);
        }
        return childUows;
    }
    
    public List<Platform_Unit_of_Work__c> split(Platform_UnitOfWork uow, Platform_Unit_of_Work__c uowObject, Integer maxSize) {
        List<Object> data = (List<Object>) uow.parameters.get('data');
        Integer numOfChildren = 0;
        List<Object> currentData = new List<Object>();
        List<Platform_Unit_of_Work__c> childUows = new List<Platform_Unit_of_Work__c>();
        for (Integer i = 0; i < data.size(); i++) {
            currentData.add((Object)data[i]);
            if (currentData.size() == maxSize || i == data.size() - 1) {
                Map<String, Object> newParams = new Map<String, Object>();
                newParams.put('data', currentData);
                for (String key : uow.parameters.keySet()) {
                    if (key != 'data') {
                        newParams.put(key, uow.parameters.get(key));
                    }
                }
                Platform_UnitOfWork newUow = new Platform_UnitOfWork(uowObject.UOW_Processor__c, newParams, uowObject.Description__c,uowObject.Id);
                Platform_Unit_of_Work__c child = new Platform_Unit_of_Work__c(
                    UOW_Processor__c = uowObject.UOW_Processor__c,
                    Payload__c = JSON.serialize(newUow),
                    Description__c = uowObject.Description__c,
                    Status__c = 'Queued',
                    Creator__c = uowObject.Creator__c,
                    Parent__c = uowObject.Id
                );
                childUows.add(child);
                currentData.clear();
                numOfChildren++;
            }
        }
        return childUows;
    }    
}