trigger PropertyDeleteTrigger on Property__c (after delete) {
    PropertyDeleteTriggerHandler.afterDelete(Trigger.old);
}
