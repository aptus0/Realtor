List<Location__c> existingLocations = [
    SELECT Id
    FROM Location__c
    WHERE Name = 'Austin Downtown'
    LIMIT 1
];
Location__c loc = existingLocations.isEmpty() ? new Location__c(Name = 'Austin Downtown') : existingLocations[0];

loc.Street__c = '120 Market Street';
loc.City__c = 'Austin';
loc.State__c = 'TX';
loc.Postal_Code__c = '78701';
loc.Country__c = 'USA';
loc.Land_Mark__c = 'Near central station';
loc.Verified__c = true;
upsert loc;

List<Manager__c> existingManagers = [
    SELECT Id
    FROM Manager__c
    WHERE Name = 'Ayla Manager'
    LIMIT 1
];
Manager__c manager = existingManagers.isEmpty() ? new Manager__c(Name = 'Ayla Manager') : existingManagers[0];

manager.Email__c = 'manager@example.com';
manager.Phone__c = '+1 555 0101';
manager.Alternative_Email__c = 'operations@example.com';
manager.Alternative_Phone__c = '+1 555 0199';
manager.Location__c = loc.Id;
upsert manager;

List<Realtor__c> existingRealtors = [
    SELECT Id
    FROM Realtor__c
    WHERE Name = 'Deniz Realtor'
    LIMIT 1
];
Realtor__c realtor = existingRealtors.isEmpty() ? new Realtor__c(Name = 'Deniz Realtor') : existingRealtors[0];

realtor.Email__c = 'realtor@example.com';
realtor.Phone__c = '+1 555 0102';
realtor.Field_of_Duty__c = 'Residential rentals and commercial offices';
realtor.Photo_URL__c = 'https://images.unsplash.com/photo-1494790108377-be9c29b29330';
upsert realtor;

List<Property__c> existingProperties = [
    SELECT Id
    FROM Property__c
    WHERE Name__c = 'Glass House Near Downtown'
    LIMIT 1
];
Property__c property = existingProperties.isEmpty() ? new Property__c() : existingProperties[0];

property.Name__c = 'Glass House Near Downtown';
property.Status__c = 'Prepared';
property.Manager__c = manager.Id;
property.Start_Date_Time__c = System.now().addDays(2);
property.End_Date_Time__c = System.now().addDays(30);
property.Location__c = loc.Id;
property.Prerequisites__c = true;
property.Recurring__c = false;
property.Property_Type__c = 'Rent';
property.Price__c = 4200;
property.Bedrooms__c = 3;
property.Bathrooms__c = 2.5;
property.Area_Sq_Ft__c = 2100;
property.Image_URL__c = 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c';
property.Public_Listing__c = true;
property.Description__c = 'A bright, modern home with open living space, walkable dining, and a private garden.';
upsert property;

List<Buyer__c> existingBuyers = [
    SELECT Id
    FROM Buyer__c
    WHERE Email__c = 'buyer@example.com'
    LIMIT 1
];
Buyer__c buyer = existingBuyers.isEmpty() ? new Buyer__c(Name = 'Mina Buyer') : existingBuyers[0];

buyer.Email__c = 'buyer@example.com';
buyer.Phone__c = '+1 555 0103';
buyer.Company_Name__c = 'Northstar Ventures';
buyer.Location__c = loc.Id;
upsert buyer;

List<Property_Realtor__c> existingAssignments = [
    SELECT Id
    FROM Property_Realtor__c
    WHERE Property__c = :property.Id AND Realtor__c = :realtor.Id
    LIMIT 1
];

if (existingAssignments.isEmpty()) {
    insert new Property_Realtor__c(Property__c = property.Id, Realtor__c = realtor.Id);
}

List<Property_Buyer__c> existingBookings = [
    SELECT Id
    FROM Property_Buyer__c
    WHERE Property__c = :property.Id AND Buyer__c = :buyer.Id
    LIMIT 1
];

if (existingBookings.isEmpty()) {
    insert new Property_Buyer__c(
        Property__c = property.Id,
        Buyer__c = buyer.Id,
        Status__c = 'New',
        Appointment_Date_Time__c = System.now().addDays(4),
        Notes__c = 'Sample booking request created for the Realtor LWC workspace.'
    );
}

List<Error_Log__c> existingLogs = [
    SELECT Id
    FROM Error_Log__c
    WHERE Process_Name__c = 'Sample Booking API'
    LIMIT 1
];

if (existingLogs.isEmpty()) {
    insert new List<Error_Log__c>{
        new Error_Log__c(
            Process_Name__c = 'Sample Booking API',
            Apex_Class_Name__c = 'RealtorPublicApi',
            Log_Date_Time__c = System.now().addMinutes(-45),
            Log_Details__c = 'Demo log: booking payload was accepted and routed to Property_Buyer__c for CRM follow-up.'
        ),
        new Error_Log__c(
            Process_Name__c = 'Property Delete Digest',
            Apex_Class_Name__c = 'PropertyDeletionDigestJob',
            Log_Date_Time__c = System.now().addHours(-3),
            Log_Details__c = 'Demo audit: daily digest scanned deleted property audit records and notified manager contacts.'
        )
    };
}

System.debug('Seeded Realtor sample data across Location, Manager, Realtor, Property, Buyer, Booking, Assignment, and Error Log records.');
