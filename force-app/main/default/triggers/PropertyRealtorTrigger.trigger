trigger PropertyRealtorTrigger on Property_Realtor__c (before insert, before update) {
    PropertyRealtorTriggerHandler.beforeSave(Trigger.new);
}
