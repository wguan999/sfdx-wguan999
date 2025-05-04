public virtual class TriggerHandler {
    public virtual void BeforeInsert(List<SObject> newItems){

    }
    public virtual void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {

    }
    public virtual void BeforeDelete(Map<Id, SObject> oldItems){

    }
    public virtual void AfterInsert(Map<Id, SObject> newItems){

    }
    public virtual void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {

    }
    public virtual void AfterDelete(Map<Id, SObject> oldItems) {

    }

    public virtual void AfterUndelete(Map<Id, SObject> oldItems) {

    }

    public Boolean IsDisabled(List<SObject> newItemsList, Map<Id, SObject> newItemsMap, Map<Id, SObject> oldItemsMap){
        SObject so = (newItemsMap != null && newItemsMap.values().size() >= 1) ? newItemsMap.values().get(0) : null;
        so = (oldItemsMap != null && oldItemsMap.values().size() >= 1) ? oldItemsMap.values().get(0) : null;
        so = (so == null) ? newItemsList[0] : so;
        String objName = so.getSObjectType().getDescribe().getName();
        Set<String> ObjectNames = new Set<String>();
        List<String> localObjectNames = new List<String>();
        Disable_Trigger__c userLevelSettings= Disable_Trigger__c.getValues(UserInfo.getUserId());
        Disable_Trigger__c ProfileLevelSettings = Disable_Trigger__c.getValues(UserInfo.getProfileId());

        String values = (userLevelSettings!= null && userLevelSettings.Object__c!= null) ? userLevelSettings.Object__c :
        (ProfileLevelSettings!= null && ProfileLevelSettings.Object__c!= null) ? ProfileLevelSettings.Object__c : 'None';
        ObjectNames.addAll(values.split(','));
        return (ObjectNames.contains('All') || ObjectNames.contains(objName));
    }
}