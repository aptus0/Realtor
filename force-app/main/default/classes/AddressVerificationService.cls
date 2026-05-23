public with sharing class AddressVerificationService {
    public class VerificationResult {
        @AuraEnabled public Boolean verified;
        @AuraEnabled public String message;
    }

    @AuraEnabled
    public static VerificationResult verifyLocation(Id locationId) {
        Location__c location = [
            SELECT Id, Street__c, City__c, State__c, Postal_Code__c, Country__c
            FROM Location__c
            WHERE Id = :locationId
            LIMIT 1
        ];

        VerificationResult result = new VerificationResult();
        if (String.isBlank(location.Street__c) || String.isBlank(location.City__c) || String.isBlank(location.Postal_Code__c)) {
            result.verified = false;
            result.message = 'Street, City, and Postal Code are required.';
            return result;
        }

        // Production hook: replace this optimistic check with a Named Credential callout to SmartyStreets.
        location.Verified__c = true;
        update location;
        result.verified = true;
        result.message = 'Location marked verified. Configure SmartyStreets Named Credential for live validation.';
        return result;
    }
}
