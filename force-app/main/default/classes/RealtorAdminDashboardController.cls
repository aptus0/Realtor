public with sharing class RealtorAdminDashboardController {
    public class DashboardSummary {
        @AuraEnabled public Integer properties;
        @AuraEnabled public Integer buyers;
        @AuraEnabled public Integer bookings;
        @AuraEnabled public Integer publicListings;
        @AuraEnabled public List<Property__c> recentProperties;
    }

    @AuraEnabled(cacheable=true)
    public static DashboardSummary getSummary() {
        DashboardSummary summary = new DashboardSummary();
        summary.properties = [SELECT COUNT() FROM Property__c];
        summary.buyers = [SELECT COUNT() FROM Buyer__c];
        summary.bookings = [SELECT COUNT() FROM Property_Buyer__c];
        summary.publicListings = [SELECT COUNT() FROM Property__c WHERE Public_Listing__c = true];
        summary.recentProperties = [
            SELECT Id, Name, Name__c, Status__c, Property_Type__c, Price__c, Start_Date_Time__c
            FROM Property__c
            ORDER BY CreatedDate DESC
            LIMIT 6
        ];
        return summary;
    }
}
