trigger PropertyBuyerTrigger on Property_Buyer__c (after insert) {
    PropertyBuyerTriggerHandler.afterInsert(Trigger.new);
}
