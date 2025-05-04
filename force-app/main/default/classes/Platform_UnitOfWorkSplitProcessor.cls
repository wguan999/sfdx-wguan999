/*
Map<String, Object> myMap2 = new Map<String, Object>();
myMap2.put('name', 'Wei');
myMap2.put('age', 30);
myMap2.put('isAdmin', true);
List<String> ids2 = new List<String>();
ids2.add('id1');
ids2.add('id2');
myMap2.put('data', ids2);
Platform_UnitOfWork subwork = new Platform_UnitOfWork('Platform_UnitOfWorkSampleProcessor', myMap2, 'my test job');

Map<String, Object> myMap = new Map<String, Object>();
List<String> ids = new List<String>();
ids.add('id1');
ids.add('id2');
ids.add('id3');
ids.add('id4');
ids.add('id5');
myMap.put('data', ids);
myMap.put('testkey', 'testvalue');
Platform_UnitOfWork work = new Platform_UnitOfWork('Platform_UnitOfWorkSplitProcessor', myMap, 'my test split job');
work.nextWork = subwork;
List<Platform_UnitOfWork> subworks = new List<Platform_UnitOfWork>();
subworks.add(subwork);
work.subWorks = subWOrks;
Platform_UnitOfWorkUtils.submit(work, 'Queued');
 

*/
public with sharing class Platform_UnitOfWorkSplitProcessor extends Platform_UnitOfWorkAbstractProcessor {
    public override void process() {
        // Simulate some processing logic
        // For example, you might want to perform some operations based on the UOW parameters
        System.debug('executing Platform_UnitOfWorkSampleProcessor for UOW: ' + uow);
        for (Integer j = 0; j < 4; j++) {
            Account act = [Select id from Account limit 1 for update];
            for (Account a : [Select id from Account]) {
                for (Integer i = 0; i < 1000; i++) {
                    
                }
            }
        }
    }
}