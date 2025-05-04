/*
Map<String, Object> myMap = new Map<String, Object>();
myMap.put('name', 'Wei');
myMap.put('age', 30);
myMap.put('isAdmin', true);
List<String> ids = new List<String>();
ids.add('id1');
ids.add('id2');
myMap.put('data', ids);
Platform_UnitOfWork work = new Platform_UnitOfWork('Platform_UnitOfWorkSampleProcessor', myMap, 'my test job');
String jsonString = JSON.serialize(myMap);
Platform_UnitOfWorkUtils.submit(work, 'Queued');
     
*/
public with sharing class Platform_UnitOfWorkSampleProcessor extends Platform_UnitOfWorkAbstractProcessor {
    public override void process() {
        // Simulate some processing logic
        // For example, you might want to perform some operations based on the UOW parameters
        System.debug('executing UnitOfWorkSampleProcessor for UOW: ' + uow);
        //throw new ApplicationException('Sample error for testing');
    }
}