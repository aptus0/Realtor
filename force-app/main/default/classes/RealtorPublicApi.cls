@RestResource(urlMapping='/realtor/v1/*')
global with sharing class RealtorPublicApi {
    global class PropertyDto {
        public Id id;
        public String propertyNumber;
        public String name;
        public String status;
        public String propertyType;
        public Decimal price;
        public Decimal bedrooms;
        public Decimal bathrooms;
        public Decimal areaSqFt;
        public String imageUrl;
        public String description;
        public Datetime startDateTime;
        public Datetime endDateTime;
        public Boolean locationVerified;
        public String city;
        public String country;
        public String street;
    }

    global class BookingRequest {
        public Id propertyId;
        public String firstName;
        public String lastName;
        public String email;
        public String phone;
        public Datetime appointmentDateTime;
        public String notes;
    }

    global class BookingResponse {
        public Id buyerId;
        public Id bookingId;
        public String status;
    }

    @HttpGet
    global static void getProperties() {
        RestRequest req = RestContext.request;
        String[] parts = req.requestURI.split('/');
        Id requestedId;
        if (!parts.isEmpty()) {
            String lastPart = parts[parts.size() - 1];
            if (lastPart != 'properties' && lastPart != 'v1') {
                requestedId = (Id) lastPart;
            }
        }

        List<Property__c> records = requestedId == null
            ? [
                SELECT Id, Name, Name__c, Status__c, Property_Type__c, Price__c, Bedrooms__c,
                       Bathrooms__c, Area_Sq_Ft__c, Image_URL__c, Description__c,
                       Start_Date_Time__c, End_Date_Time__c, Location_Verified__c,
                       Location__r.Street__c, Location__r.City__c, Location__r.Country__c
                FROM Property__c
                WHERE Public_Listing__c = true
                AND Status__c IN ('Prepared', 'In Progress')
                ORDER BY Start_Date_Time__c ASC
                LIMIT 100
            ]
            : [
                SELECT Id, Name, Name__c, Status__c, Property_Type__c, Price__c, Bedrooms__c,
                       Bathrooms__c, Area_Sq_Ft__c, Image_URL__c, Description__c,
                       Start_Date_Time__c, End_Date_Time__c, Location_Verified__c,
                       Location__r.Street__c, Location__r.City__c, Location__r.Country__c
                FROM Property__c
                WHERE Public_Listing__c = true
                AND Status__c IN ('Prepared', 'In Progress')
                AND Id = :requestedId
                LIMIT 1
            ];

        List<PropertyDto> payload = new List<PropertyDto>();
        for (Property__c record : records) {
            payload.add(toDto(record));
        }
        Object responsePayload;
        if (requestedId == null) {
            responsePayload = payload;
        } else {
            responsePayload = payload.isEmpty() ? null : payload[0];
        }
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responsePayload));
    }

    @HttpPost
    global static void createBooking() {
        RestRequest req = RestContext.request;
        BookingRequest input = (BookingRequest) JSON.deserialize(req.requestBody.toString(), BookingRequest.class);
        if (input == null || input.propertyId == null || String.isBlank(input.firstName) || String.isBlank(input.lastName) || String.isBlank(input.email) || String.isBlank(input.phone)) {
            RestContext.response.statusCode = 400;
            RestContext.response.responseBody = Blob.valueOf('{"error":"propertyId, firstName, lastName, email, and phone are required"}');
            return;
        }

        Savepoint sp = Database.setSavepoint();
        try {
            List<Buyer__c> existing = [
                SELECT Id
                FROM Buyer__c
                WHERE Email__c = :input.email
                AND Phone__c = :input.phone
                LIMIT 1
            ];
            Buyer__c buyer = existing.isEmpty()
                ? new Buyer__c(Name = input.firstName + ' ' + input.lastName, Email__c = input.email, Phone__c = input.phone)
                : existing[0];
            upsert buyer;

            Property_Buyer__c booking = new Property_Buyer__c(
                Property__c = input.propertyId,
                Buyer__c = buyer.Id,
                Appointment_Date_Time__c = input.appointmentDateTime,
                Notes__c = input.notes,
                Status__c = 'New'
            );
            insert booking;

            BookingResponse response = new BookingResponse();
            response.buyerId = buyer.Id;
            response.bookingId = booking.Id;
            response.status = 'New';
            RestContext.response.statusCode = 201;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
        } catch (Exception ex) {
            Database.rollback(sp);
            RealtorLog.error('PublicBookingApi', 'RealtorPublicApi', ex);
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('{"error":"Booking could not be created"}');
        }
    }

    private static PropertyDto toDto(Property__c record) {
        PropertyDto dto = new PropertyDto();
        dto.id = record.Id;
        dto.propertyNumber = record.Name;
        dto.name = record.Name__c;
        dto.status = record.Status__c;
        dto.propertyType = record.Property_Type__c;
        dto.price = record.Price__c;
        dto.bedrooms = record.Bedrooms__c;
        dto.bathrooms = record.Bathrooms__c;
        dto.areaSqFt = record.Area_Sq_Ft__c;
        dto.imageUrl = record.Image_URL__c;
        dto.description = record.Description__c;
        dto.startDateTime = record.Start_Date_Time__c;
        dto.endDateTime = record.End_Date_Time__c;
        dto.locationVerified = record.Location_Verified__c;
        dto.street = record.Location__r == null ? null : record.Location__r.Street__c;
        dto.city = record.Location__r == null ? null : record.Location__r.City__c;
        dto.country = record.Location__r == null ? null : record.Location__r.Country__c;
        return dto;
    }
}
