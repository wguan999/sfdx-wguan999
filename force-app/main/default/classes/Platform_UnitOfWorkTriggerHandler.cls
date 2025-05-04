public  class Platform_UnitOfWorkTriggerHandler extends TriggerHandler {
    static boolean isSycncExcuted = false;
    public override void AfterInsert(Map<Id, SObject> newItems) {
        List<Platform_Unit_of_Work__c> syncUows =  new List<Platform_Unit_of_Work__c>();
        for (SObject item: newItems.values()) {
            Platform_Unit_of_Work__c uow = (Platform_Unit_of_Work__c) item;
            System.debug('status: ' + uow.Status__c);
            if (uow.Status__c == 'Queued' && uow.UOW_Processor__c != null) {
                if (uow.UOW_Processor__c.contains('Callout')) {
                    System.enqueueJob(new Platform_UnitOfWorkUtils.UnitOfWorkUtilTask(uow.id));
                } else {
                    syncUows.add(uow);
                }
            }
        }
        // exuecute the first uow in syncUows, and create uow event for the rest
        if (syncUows.size() > 0) {
            if  (!isSycncExcuted) {
                isSycncExcuted = true;
                Platform_Unit_of_Work__c firstUow = syncUows[0];
                Platform_UnitOfWorkUtils.execute(firstUow);
                syncUows.remove(0);
            } 

            for (Platform_Unit_of_Work__c uow : syncUows) {
                Platform_Unit_of_Work_Event__e event = new Platform_Unit_of_Work_Event__e(
                    UOW_Id__c = uow.Id,
                    Creator__c = uow.Creator__c,
                    UOW_Processor__c = uow.UOW_Processor__c,
                    Payload__c = uow.Payload__c,
                    Parent__c = uow.Parent__c,
                    Status__c = uow.Status__c,
                    Description__c = uow.Description__c
                );
                Database.SaveResult sr = EventBus.publish(event);
            }
        }
        /*
        for (Unit_of_Work__c uow : syncUows) {
            System.enqueueJob(new Platform_UnitOfWorkUtils.UnitOfWorkUtilTask(uow.id));
        }*/


        if (newItems.size() == 1) {
            Platform_Unit_of_Work__c uow = (Platform_Unit_of_Work__c) newItems.values()[0];
            if ((uow.Parent__c != null) && (uow.Status__c == 'Success' || uow.Status__c == 'Error')) {
                // find how many child uows are in 'Success' or 'Error' status and update parent uow status
                //update Num_of_Error__c and Num_of_Success__c fields on parent uow
                Platform_Unit_of_Work__c parent = [SELECT Id, Num_of_Error__c, Num_of_Success__c, Num_of_Children__c FROM Platform_Unit_of_Work__c WHERE Id = :uow.Parent__c for update];
                List<Platform_Unit_of_Work__c> childUows = [SELECT Id, Status__c FROM Platform_Unit_of_Work__c WHERE Parent__c = :uow.Parent__c];
                Integer successCount = 0;
                Integer errorCount = 0;
                for (Platform_Unit_of_Work__c childUow : childUows) {
                    if (childUow.Status__c == 'Success') {
                        successCount++;
                    } else if (childUow.Status__c == 'Error') {
                        errorCount++;
                    }
                }
                parent.Num_of_Error__c = errorCount;
                parent.Num_of_Success__c = successCount;
                parent.Num_of_Children__c = childUows.size();
                if (successCount + errorCount == parent.Num_of_Children__c) {
                    if (errorCount > 0) {
                        parent.Status__c = 'Error';
                    } else {
                        parent.Status__c = 'Success';
                    }
                }
                update parent;
            }
        }
    } 

    public override void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.debug('AfterUpdate:');
        if (newItems.size() == 1 && ((Platform_Unit_of_Work__c)newItems.values()[0]).Status__c == 'Success' 
                && ((Platform_Unit_of_Work__c)newItems.values()[0]).Parent__c == null 
                && ((Platform_Unit_of_Work__c)oldItems.values()[0]).Status__c != 'Success') {
            Platform_Unit_of_Work__c uow = (Platform_Unit_of_Work__c) newItems.values()[0];
            Platform_Unit_of_Work_Config__mdt    config = [Select Ignore_Eligible__c, Max_Size__c, has_Next__c from Platform_Unit_of_Work_Config__mdt where DeveloperName = :uow.UOW_Processor__c limit 1];
            if (config.has_Next__c) {
                if (uow.Next__c != null) {
                    Platform_Unit_of_Work__c nextUow = new Platform_Unit_of_Work__c();
                    nextUow.Id = uow.Next__c;
                    nextUow.Status__c = 'Queued';
                    update nextUow;
                }
                /*
                else {
                    Type t = Type.forName(null, uow.UOW_Processor__c);
                    Platform_UnitOfWorkAbstractProcessor instance = (Platform_UnitOfWorkAbstractProcessor) t.newInstance();
                    instance.setUowObject(uow);
                    instance.createNext();
                }*/
            }
        }
        AfterInsert(newItems);
    }
}