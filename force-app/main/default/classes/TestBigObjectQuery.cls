public with sharing class TestBigObjectQuery {

    public static List<Test__b> queryTestBigObject(DateTime startDate, DateTime endDate, String objectId) {
        List<Test__b> results = [SELECT Change_Event__c, Date_Time__c, Object_Id__c 
                                 FROM Test__b 
                                 WHERE Object_Id__c = :objectId AND Date_Time__c >= :startDate AND Date_Time__c <= :endDate 
                                 ];

		System.debug(results.size());
        return results;
    }
}