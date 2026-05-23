public with sharing class PropertyDeleteTriggerHandler {
    public static void afterDelete(List<Property__c> oldRecords) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        for (Property__c property : oldRecords) {
            logs.add(new Error_Log__c(
                Log_Date_Time__c = System.now(),
                Process_Name__c = 'PropertyDeleteTrigger',
                Apex_Class_Name__c = 'PropertyDeleteTriggerHandler',
                Log_Details__c = property.Name + ' - ' + property.Name__c
            ));
        }
        if (!logs.isEmpty()) {
            insert logs;
        }
    }
}
