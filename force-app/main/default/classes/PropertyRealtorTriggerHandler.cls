public with sharing class PropertyRealtorTriggerHandler {
    public static void beforeSave(List<Property_Realtor__c> records) {
        Set<Id> propertyIds = new Set<Id>();
        for (Property_Realtor__c record : records) {
            if (record.Property__c != null) {
                propertyIds.add(record.Property__c);
            }
        }
        if (propertyIds.isEmpty()) {
            return;
        }

        Map<Id, Property__c> properties = new Map<Id, Property__c>([
            SELECT Id, End_Date_Time__c, Prerequisites__c
            FROM Property__c
            WHERE Id IN :propertyIds
        ]);

        for (Property_Realtor__c record : records) {
            Property__c property = properties.get(record.Property__c);
            if (property == null) {
                continue;
            }
            if (!property.Prerequisites__c || (property.End_Date_Time__c != null && property.End_Date_Time__c <= System.now())) {
                record.addError('Realtor can only be associated with properties whose prerequisites are checked and end date is in the future.');
            }
        }
    }
}
