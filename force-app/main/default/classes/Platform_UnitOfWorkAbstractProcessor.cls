public abstract class Platform_UnitOfWorkAbstractProcessor {

    public Platform_Unit_of_Work__c uowObject;
    public Platform_UnitOfWork uow;
    public Platform_Unit_of_Work_Config__mdt config;
       
    public void setUowObject(Platform_Unit_of_Work__c uowObject) {
        this.uowObject = uowObject;
        config = [Select Ignore_Eligible__c, Max_Size__c, has_Next__c from Platform_Unit_of_Work_Config__mdt where DeveloperName = :uowObject.UOW_Processor__c limit 1];
        uow = (Platform_UnitOfWork) Platform_UnitOfWorkUtils.deserializeUnitOfWork((Map<String, Object>)JSON.deserializeUntyped(uowObject.Payload__c));
    }

    public Platform_Unit_of_Work_Config__mdt getConfig() {
        return config;
    }

    public abstract void process();

    public virtual boolean isEligibleForProcessing() {
        return true;
    }


    public void  execute() {
         
        String status = uowObject.Status__c;
        Log__c errorLog = null;
        Integer numOfChildren = 0;
        try {
            if (uowObject.status__c=='Queued' && uowObject.Num_of_Children__c != null && uowObject.Num_of_Children__c > 0) {
                System.debug('Num_of_Children__c: ' + uowObject.Num_of_Children__c);
                status = 'Processing';
                List<Platform_Unit_of_Work__c> childUows = [SELECT Id, Status__c FROM Platform_Unit_of_Work__c WHERE Parent__c = :uowObject.Id];
                for (Platform_Unit_of_Work__c childUow : childUows) {
                    childUow.Status__c = 'Queued';
                }
                update childUows;
            }
            else {  
                if (uowObject.Num_of_Children__c != null && uowObject.Num_of_Children__c > 0)
                    return;
                //convert uow.Parameters__c to Map<String, Object>
                //boolean hasChildren = false;
                /*
                if (needToSplit()) {
                    numOfChildren = split();
                    hasChildren = true;
                    status = 'Processing';
                }
				
                
                if (hasSubWorks()) {
                    numOfchildren += createSubWorks();
                    hasChildren = true;
                    status = 'Processing';
                }
                */
                //if (!hasChildren) 
                //{
                    if (config.Ignore_Eligible__c || isEligibleForProcessing()) {
                        process();
                        status = 'Success';
                    }
                    else {
                        status = 'Not Eligible';
                    }
                //}
                //createNext();                    
            }
        } catch (Exception e) {
            System.debug('Error processing UOW: ' + uowObject.Id);
            System.debug(e);
            status = 'Error';
            errorLog = Log.logError(e);
        }
        finally {
            Platform_Unit_of_Work__c uowToUpdate = new Platform_Unit_of_Work__c();
            uowToUpdate.Id = uowObject.Id;
            uowToUpdate.Status__c = status;
            if (errorLog != null) {
                uowToUpdate.Error_Log__c = errorLog.Id;
            }
            uowToUpdate.Num_of_Children__c = numOfChildren;
            update uowToUpdate;
        }
    }
/*
    public boolean hasSubWorks() {
        return uow.subWorks != null && uow.subWorks.size() > 0;
    }
    
    public Integer createSubWorks() {
		List<Platform_Unit_of_Work__c> childUows = new List<Platform_Unit_of_Work__c>();        
        for (Platform_UnitOfWork uow : uow.subWorks) {
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
        insert childUows;
        return uow.subWorks.size();
    }
    */
    /*
    public boolean needToSplit() {
        List<Object> data = (List<Object>) uow.parameters.get('data');
        Integer size = (data == null) ? -1 : data.size();
        Integer maxSize = (config.Max_Size__c == null || (Integer)config.Max_Size__c == -1)? 2147483647 : (Integer)config.Max_Size__c;
        System.debug('size ' + size);
        System.debug('maxSize ' + maxSize);
        return maxSize < size;
    }

    public Integer split() {
        List<Object> data = (List<Object>) uow.parameters.get('data');
        Integer maxSize = (Integer)config.Max_Size__c;
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
        insert childUows;
        return numOfChildren;
    }

    public void createNext() {
        if (uow.nextWork != null) {
            Platform_Unit_of_Work__c nextUow = new Platform_Unit_of_Work__c(
                UOW_Processor__c = uowObject.UOW_Processor__c,
                Payload__c = JSON.serialize(uow.nextWork),
                Description__c = uowObject.Description__c,
                Status__c = 'Init',
                Creator__c = uowObject.Creator__c
            );
            insert nextUow;
            Platform_Unit_of_Work__c uowToUpdate = new Platform_Unit_of_Work__c();
            uowToUpdate.Id = uowObject.Id;
            uowToUpdate.Next__c = nextUow.Id;
            update uowObject;
        }
    }
	*/
}