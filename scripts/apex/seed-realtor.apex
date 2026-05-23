Location__c loc = new Location__c(
    Name = 'Austin Downtown',
    Street__c = '120 Market Street',
    City__c = 'Austin',
    State__c = 'TX',
    Postal_Code__c = '78701',
    Country__c = 'USA',
    Land_Mark__c = 'Near central station',
    Verified__c = true
);
insert loc;

Manager__c manager = new Manager__c(
    Name = 'Ayla Manager',
    Email__c = 'manager@example.com',
    Phone__c = '+1 555 0101',
    Location__c = loc.Id
);
insert manager;

Realtor__c realtor = new Realtor__c(
    Name = 'Deniz Realtor',
    Email__c = 'realtor@example.com',
    Phone__c = '+1 555 0102',
    Field_of_Duty__c = 'Residential rentals and commercial offices',
    Photo_URL__c = 'https://images.unsplash.com/photo-1494790108377-be9c29b29330'
);
insert realtor;

Property__c property = new Property__c(
    Name__c = 'Glass House Near Downtown',
    Status__c = 'Prepared',
    Manager__c = manager.Id,
    Start_Date_Time__c = System.now().addDays(2),
    End_Date_Time__c = System.now().addDays(30),
    Location__c = loc.Id,
    Prerequisites__c = true,
    Recurring__c = false,
    Property_Type__c = 'Rent',
    Price__c = 4200,
    Bedrooms__c = 3,
    Bathrooms__c = 2.5,
    Area_Sq_Ft__c = 2100,
    Image_URL__c = 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c',
    Public_Listing__c = true,
    Description__c = 'A bright, modern home with open living space, walkable dining, and a private garden.'
);
insert property;

insert new Property_Realtor__c(Property__c = property.Id, Realtor__c = realtor.Id);

System.debug('Seeded Realtor app sample data. Property Id=' + property.Id);
