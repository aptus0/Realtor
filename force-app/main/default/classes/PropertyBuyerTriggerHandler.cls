public with sharing class PropertyBuyerTriggerHandler {
    public static void afterInsert(List<Property_Buyer__c> records) {
        Set<Id> bookingIds = new Set<Id>();
        for (Property_Buyer__c record : records) {
            bookingIds.add(record.Id);
        }

        List<Property_Buyer__c> bookings = [
            SELECT Id, Name, Appointment_Date_Time__c, Buyer__r.Name, Buyer__r.Email__c,
                   Property__r.Name, Property__r.Name__c, Property__r.Start_Date_Time__c,
                   Property__r.Location__r.City__c, Property__r.Location__r.Country__c
            FROM Property_Buyer__c
            WHERE Id IN :bookingIds
        ];

        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        for (Property_Buyer__c booking : bookings) {
            if (String.isBlank(booking.Buyer__r.Email__c)) {
                continue;
            }
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setToAddresses(new List<String>{ booking.Buyer__r.Email__c });
            message.setSubject('Property booking request received: ' + booking.Property__r.Name__c);
            message.setPlainTextBody(
                'Hi ' + booking.Buyer__r.Name + ',\n\n' +
                'Your booking request for ' + booking.Property__r.Name__c + ' has been received.\n' +
                'Property #: ' + booking.Property__r.Name + '\n' +
                'Start: ' + String.valueOf(booking.Property__r.Start_Date_Time__c) + '\n' +
                'Location: ' + booking.Property__r.Location__r.City__c + ', ' + booking.Property__r.Location__r.Country__c + '\n' +
                'Requested appointment: ' + String.valueOf(booking.Appointment_Date_Time__c) + '\n\n' +
                'A realtor will contact you shortly.'
            );
            messages.add(message);
        }

        if (!messages.isEmpty()) {
            try {
                Messaging.sendEmail(messages);
            } catch (Exception ex) {
                RealtorLog.error('PropertyBuyerEmail', 'PropertyBuyerTriggerHandler', ex);
            }
        }
    }
}
