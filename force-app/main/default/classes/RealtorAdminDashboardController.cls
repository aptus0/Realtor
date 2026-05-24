public with sharing class RealtorAdminDashboardController {
    public class DashboardSummary {
        @AuraEnabled public Integer properties;
        @AuraEnabled public Integer buyers;
        @AuraEnabled public Integer bookings;
        @AuraEnabled public Integer publicListings;
        @AuraEnabled public List<Property__c> recentProperties;
    }

    public class WorkspaceColumn {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String type;

        public WorkspaceColumn(String label, String fieldName, String type) {
            this.label = label;
            this.fieldName = fieldName;
            this.type = type;
        }
    }

    public class WorkspaceData {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public String subtitle;
        @AuraEnabled public String objectApiName;
        @AuraEnabled public Integer totalCount;
        @AuraEnabled public List<WorkspaceColumn> columns;
        @AuraEnabled public List<Map<String, Object>> rows;
        @AuraEnabled public List<Map<String, Object>> mapMarkers;
    }

    public class RecordDetailData {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String objectApiName;
        @AuraEnabled public String title;
        @AuraEnabled public String subtitle;
        @AuraEnabled public String badge;
        @AuraEnabled public String imageUrl;
        @AuraEnabled public List<Map<String, Object>> fields;
        @AuraEnabled public List<Map<String, Object>> mapMarkers;
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

    @AuraEnabled(cacheable=true)
    public static WorkspaceData getWorkspace(String workspaceKey) {
        String key = normalizeWorkspaceKey(workspaceKey);
        WorkspaceData data = new WorkspaceData();
        data.key = key;
        data.columns = new List<WorkspaceColumn>();
        data.rows = new List<Map<String, Object>>();
        data.mapMarkers = new List<Map<String, Object>>();

        if (key == 'buyers') {
            data.label = 'Buyers';
            data.subtitle = 'Track buyer contacts coming from CRM and public booking requests.';
            data.objectApiName = 'Buyer__c';
            data.totalCount = [SELECT COUNT() FROM Buyer__c];
            data.columns.add(new WorkspaceColumn('Buyer', 'name', 'text'));
            data.columns.add(new WorkspaceColumn('Email', 'email', 'email'));
            data.columns.add(new WorkspaceColumn('Phone', 'phone', 'phone'));
            data.columns.add(new WorkspaceColumn('Company', 'company', 'text'));
            for (Buyer__c record : [
                SELECT Id, Name, Email__c, Phone__c, Company_Name__c, CreatedDate
                FROM Buyer__c
                ORDER BY CreatedDate DESC
                LIMIT 25
            ]) {
                data.rows.add(row(record.Id, record.Name, new Map<String, Object>{
                    'email' => record.Email__c,
                    'phone' => record.Phone__c,
                    'company' => record.Company_Name__c
                }));
            }
        } else if (key == 'realtors') {
            data.label = 'Realtors';
            data.subtitle = 'Manage realtor contacts and their fields of duty.';
            data.objectApiName = 'Realtor__c';
            data.totalCount = [SELECT COUNT() FROM Realtor__c];
            data.columns.add(new WorkspaceColumn('Realtor', 'name', 'text'));
            data.columns.add(new WorkspaceColumn('Email', 'email', 'email'));
            data.columns.add(new WorkspaceColumn('Phone', 'phone', 'phone'));
            data.columns.add(new WorkspaceColumn('Field of Duty', 'fieldOfDuty', 'text'));
            for (Realtor__c record : [
                SELECT Id, Name, Email__c, Phone__c, Field_of_Duty__c, CreatedDate
                FROM Realtor__c
                ORDER BY CreatedDate DESC
                LIMIT 25
            ]) {
                data.rows.add(row(record.Id, record.Name, new Map<String, Object>{
                    'email' => record.Email__c,
                    'phone' => record.Phone__c,
                    'fieldOfDuty' => record.Field_of_Duty__c
                }));
            }
        } else if (key == 'bookings') {
            data.label = 'Bookings';
            data.subtitle = 'Review property visit requests and buyer appointments.';
            data.objectApiName = 'Property_Buyer__c';
            data.totalCount = [SELECT COUNT() FROM Property_Buyer__c];
            data.columns.add(new WorkspaceColumn('Booking', 'name', 'text'));
            data.columns.add(new WorkspaceColumn('Property', 'propertyName', 'text'));
            data.columns.add(new WorkspaceColumn('Buyer', 'buyerName', 'text'));
            data.columns.add(new WorkspaceColumn('Status', 'status', 'text'));
            data.columns.add(new WorkspaceColumn('Appointment', 'appointmentDateTime', 'date'));
            for (Property_Buyer__c record : [
                SELECT Id, Name, Property__r.Name__c, Buyer__r.Name, Status__c, Appointment_Date_Time__c, CreatedDate
                FROM Property_Buyer__c
                ORDER BY CreatedDate DESC
                LIMIT 25
            ]) {
                data.rows.add(row(record.Id, record.Name, new Map<String, Object>{
                    'propertyName' => record.Property__r?.Name__c,
                    'buyerName' => record.Buyer__r?.Name,
                    'status' => record.Status__c,
                    'appointmentDateTime' => record.Appointment_Date_Time__c
                }));
            }
        } else if (key == 'assignments') {
            data.label = 'Assignments';
            data.subtitle = 'Connect realtors to eligible active properties.';
            data.objectApiName = 'Property_Realtor__c';
            data.totalCount = [SELECT COUNT() FROM Property_Realtor__c];
            data.columns.add(new WorkspaceColumn('Assignment', 'name', 'text'));
            data.columns.add(new WorkspaceColumn('Property', 'propertyName', 'text'));
            data.columns.add(new WorkspaceColumn('Realtor', 'realtorName', 'text'));
            for (Property_Realtor__c record : [
                SELECT Id, Name, Property__r.Name__c, Realtor__r.Name, CreatedDate
                FROM Property_Realtor__c
                ORDER BY CreatedDate DESC
                LIMIT 25
            ]) {
                data.rows.add(row(record.Id, record.Name, new Map<String, Object>{
                    'propertyName' => record.Property__r?.Name__c,
                    'realtorName' => record.Realtor__r?.Name
                }));
            }
        } else if (key == 'locations') {
            data.label = 'Locations';
            data.subtitle = 'Maintain address records and verification status.';
            data.objectApiName = 'Location__c';
            data.totalCount = [SELECT COUNT() FROM Location__c];
            data.columns.add(new WorkspaceColumn('Location', 'name', 'text'));
            data.columns.add(new WorkspaceColumn('City', 'city', 'text'));
            data.columns.add(new WorkspaceColumn('State', 'state', 'text'));
            data.columns.add(new WorkspaceColumn('Country', 'country', 'text'));
            data.columns.add(new WorkspaceColumn('Verified', 'verified', 'boolean'));
            for (Location__c record : [
                SELECT Id, Name, Street__c, City__c, State__c, Postal_Code__c, Country__c, Verified__c, CreatedDate
                FROM Location__c
                ORDER BY CreatedDate DESC
                LIMIT 25
            ]) {
                data.rows.add(row(record.Id, record.Name, new Map<String, Object>{
                    'street' => record.Street__c,
                    'city' => record.City__c,
                    'state' => record.State__c,
                    'postalCode' => record.Postal_Code__c,
                    'country' => record.Country__c,
                    'verified' => record.Verified__c
                }));
                addAddressMarker(data, record.Id, record.Name, 'Location record', record.Street__c, record.City__c, record.State__c, record.Postal_Code__c, record.Country__c);
            }
        } else if (key == 'managers') {
            data.label = 'Managers';
            data.subtitle = 'Manage internal manager contacts and ownership context.';
            data.objectApiName = 'Manager__c';
            data.totalCount = [SELECT COUNT() FROM Manager__c];
            data.columns.add(new WorkspaceColumn('Manager', 'name', 'text'));
            data.columns.add(new WorkspaceColumn('Email', 'email', 'email'));
            data.columns.add(new WorkspaceColumn('Phone', 'phone', 'phone'));
            data.columns.add(new WorkspaceColumn('Alternative Email', 'alternativeEmail', 'email'));
            for (Manager__c record : [
                SELECT Id, Name, Email__c, Phone__c, Alternative_Email__c, CreatedDate
                FROM Manager__c
                ORDER BY CreatedDate DESC
                LIMIT 25
            ]) {
                data.rows.add(row(record.Id, record.Name, new Map<String, Object>{
                    'email' => record.Email__c,
                    'phone' => record.Phone__c,
                    'alternativeEmail' => record.Alternative_Email__c
                }));
            }
        } else if (key == 'logs') {
            data.label = 'Error Logs';
            data.subtitle = 'Inspect automation, API, and deletion audit events.';
            data.objectApiName = 'Error_Log__c';
            data.totalCount = [SELECT COUNT() FROM Error_Log__c];
            data.columns.add(new WorkspaceColumn('Log', 'name', 'text'));
            data.columns.add(new WorkspaceColumn('Process', 'processName', 'text'));
            data.columns.add(new WorkspaceColumn('Apex Class', 'apexClassName', 'text'));
            data.columns.add(new WorkspaceColumn('Date', 'logDateTime', 'date'));
            data.columns.add(new WorkspaceColumn('Details', 'logDetails', 'text'));
            for (Error_Log__c record : [
                SELECT Id, Name, Process_Name__c, Apex_Class_Name__c, Log_Date_Time__c, Log_Details__c, CreatedDate
                FROM Error_Log__c
                ORDER BY CreatedDate DESC
                LIMIT 25
            ]) {
                data.rows.add(row(record.Id, record.Name, new Map<String, Object>{
                    'processName' => record.Process_Name__c,
                    'apexClassName' => record.Apex_Class_Name__c,
                    'logDateTime' => record.Log_Date_Time__c,
                    'logDetails' => record.Log_Details__c
                }));
            }
        } else {
            data.key = 'properties';
            data.label = 'Properties';
            data.subtitle = 'Manage public listings, pricing, statuses, and CRM-ready property records.';
            data.objectApiName = 'Property__c';
            data.totalCount = [SELECT COUNT() FROM Property__c];
            data.columns.add(new WorkspaceColumn('Property', 'name', 'text'));
            data.columns.add(new WorkspaceColumn('Location', 'locationName', 'text'));
            data.columns.add(new WorkspaceColumn('Status', 'status', 'text'));
            data.columns.add(new WorkspaceColumn('Type', 'propertyType', 'text'));
            data.columns.add(new WorkspaceColumn('Price', 'price', 'currency'));
            data.columns.add(new WorkspaceColumn('Public', 'publicListing', 'boolean'));
            for (Property__c record : [
                SELECT Id, Name, Name__c, Status__c, Property_Type__c, Price__c, Public_Listing__c,
                    Location__r.Name, Location__r.Street__c, Location__r.City__c, Location__r.State__c,
                    Location__r.Postal_Code__c, Location__r.Country__c, CreatedDate
                FROM Property__c
                ORDER BY CreatedDate DESC
                LIMIT 25
            ]) {
                String propertyName = String.isBlank(record.Name__c) ? record.Name : record.Name__c;
                data.rows.add(row(record.Id, propertyName, new Map<String, Object>{
                    'locationName' => record.Location__r?.Name,
                    'status' => record.Status__c,
                    'propertyType' => record.Property_Type__c,
                    'price' => record.Price__c,
                    'publicListing' => record.Public_Listing__c
                }));
                addAddressMarker(
                    data,
                    record.Id,
                    propertyName,
                    record.Property_Type__c + ' - ' + record.Status__c,
                    record.Location__r?.Street__c,
                    record.Location__r?.City__c,
                    record.Location__r?.State__c,
                    record.Location__r?.Postal_Code__c,
                    record.Location__r?.Country__c
                );
            }
        }

        return data;
    }

    private static String normalizeWorkspaceKey(String workspaceKey) {
        if (String.isBlank(workspaceKey)) {
            return 'properties';
        }

        String key = workspaceKey.toLowerCase().replace('realtor_', '');
        if (key.contains('buyer') && !key.contains('property_buyer')) return 'buyers';
        if (key.contains('realtors') || (key.contains('realtor') && !key.contains('property_realtor'))) return 'realtors';
        if (key.contains('booking') || key.contains('property_buyer')) return 'bookings';
        if (key.contains('assignment') || key.contains('property_realtor')) return 'assignments';
        if (key.contains('location')) return 'locations';
        if (key.contains('manager')) return 'managers';
        if (key.contains('log')) return 'logs';
        return 'properties';
    }

    private static Map<String, Object> row(Id recordId, String name, Map<String, Object> values) {
        Map<String, Object> record = new Map<String, Object>();
        record.put('id', recordId);
        record.put('name', name);
        record.putAll(values);
        return record;
    }

    @AuraEnabled(cacheable=true)
    public static RecordDetailData getRecordDetail(Id recordId) {
        if (recordId == null) {
            throw new AuraHandledException('Record Id is required.');
        }

        Schema.SObjectType sObjectType = recordId.getSObjectType();
        String objectApiName = String.valueOf(sObjectType);
        RecordDetailData detail = new RecordDetailData();
        detail.recordId = recordId;
        detail.objectApiName = objectApiName;
        detail.fields = new List<Map<String, Object>>();
        detail.mapMarkers = new List<Map<String, Object>>();

        if (objectApiName == 'Property__c') {
            Property__c record = [
                SELECT Id, Name, Name__c, Status__c, Property_Type__c, Price__c, Bedrooms__c, Bathrooms__c,
                    Area_Sq_Ft__c, Public_Listing__c, Location_Verified__c, Image_URL__c, Description__c,
                    Start_Date_Time__c, End_Date_Time__c, Manager__r.Name, Location__r.Name,
                    Location__r.Street__c, Location__r.City__c, Location__r.State__c, Location__r.Postal_Code__c, Location__r.Country__c
                FROM Property__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            detail.title = String.isBlank(record.Name__c) ? record.Name : record.Name__c;
            detail.subtitle = record.Location__r?.Name;
            detail.badge = record.Status__c;
            detail.imageUrl = record.Image_URL__c;
            addField(detail, 'Property Type', record.Property_Type__c, 'text');
            addField(detail, 'Price', record.Price__c, 'currency');
            addField(detail, 'Bedrooms', record.Bedrooms__c, 'number');
            addField(detail, 'Bathrooms', record.Bathrooms__c, 'number');
            addField(detail, 'Area', record.Area_Sq_Ft__c, 'number');
            addField(detail, 'Manager', record.Manager__r?.Name, 'text');
            addField(detail, 'Public Listing', record.Public_Listing__c, 'boolean');
            addField(detail, 'Location Verified', record.Location_Verified__c, 'boolean');
            addField(detail, 'Description', record.Description__c, 'longtext');
            addField(detail, 'Start', record.Start_Date_Time__c, 'datetime');
            addField(detail, 'End', record.End_Date_Time__c, 'datetime');
            addDetailMarker(detail, record.Id, detail.title, record.Property_Type__c, record.Location__r?.Street__c, record.Location__r?.City__c, record.Location__r?.State__c, record.Location__r?.Postal_Code__c, record.Location__r?.Country__c);
        } else if (objectApiName == 'Buyer__c') {
            Buyer__c record = [
                SELECT Id, Name, Email__c, Phone__c, Company_Name__c, Location__r.Name,
                    Location__r.Street__c, Location__r.City__c, Location__r.State__c, Location__r.Postal_Code__c, Location__r.Country__c
                FROM Buyer__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            detail.title = record.Name;
            detail.subtitle = record.Company_Name__c;
            detail.badge = 'Buyer';
            addField(detail, 'Email', record.Email__c, 'email');
            addField(detail, 'Phone', record.Phone__c, 'phone');
            addField(detail, 'Company', record.Company_Name__c, 'text');
            addField(detail, 'Location', record.Location__r?.Name, 'text');
            addDetailMarker(detail, record.Id, record.Name, 'Buyer location', record.Location__r?.Street__c, record.Location__r?.City__c, record.Location__r?.State__c, record.Location__r?.Postal_Code__c, record.Location__r?.Country__c);
        } else if (objectApiName == 'Realtor__c') {
            Realtor__c record = [
                SELECT Id, Name, Email__c, Phone__c, Field_of_Duty__c, Photo_URL__c
                FROM Realtor__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            detail.title = record.Name;
            detail.subtitle = record.Field_of_Duty__c;
            detail.badge = 'Realtor';
            detail.imageUrl = record.Photo_URL__c;
            addField(detail, 'Email', record.Email__c, 'email');
            addField(detail, 'Phone', record.Phone__c, 'phone');
            addField(detail, 'Field of Duty', record.Field_of_Duty__c, 'longtext');
        } else if (objectApiName == 'Property_Buyer__c') {
            Property_Buyer__c record = [
                SELECT Id, Name, Status__c, Appointment_Date_Time__c, Notes__c, Property__r.Name__c, Buyer__r.Name
                FROM Property_Buyer__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            detail.title = record.Name;
            detail.subtitle = record.Property__r?.Name__c + ' - ' + record.Buyer__r?.Name;
            detail.badge = record.Status__c;
            addField(detail, 'Property', record.Property__r?.Name__c, 'text');
            addField(detail, 'Buyer', record.Buyer__r?.Name, 'text');
            addField(detail, 'Appointment', record.Appointment_Date_Time__c, 'datetime');
            addField(detail, 'Notes', record.Notes__c, 'longtext');
        } else if (objectApiName == 'Property_Realtor__c') {
            Property_Realtor__c record = [
                SELECT Id, Name, Property__r.Name__c, Realtor__r.Name
                FROM Property_Realtor__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            detail.title = record.Name;
            detail.subtitle = record.Property__r?.Name__c + ' - ' + record.Realtor__r?.Name;
            detail.badge = 'Assignment';
            addField(detail, 'Property', record.Property__r?.Name__c, 'text');
            addField(detail, 'Realtor', record.Realtor__r?.Name, 'text');
        } else if (objectApiName == 'Location__c') {
            Location__c record = [
                SELECT Id, Name, Street__c, City__c, State__c, Postal_Code__c, Country__c, Land_Mark__c, Verified__c
                FROM Location__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            detail.title = record.Name;
            detail.subtitle = joinAddress(record.Street__c, record.City__c, record.State__c, record.Postal_Code__c, record.Country__c);
            detail.badge = record.Verified__c ? 'Verified' : 'Unverified';
            addField(detail, 'Street', record.Street__c, 'text');
            addField(detail, 'City', record.City__c, 'text');
            addField(detail, 'State', record.State__c, 'text');
            addField(detail, 'Postal Code', record.Postal_Code__c, 'text');
            addField(detail, 'Country', record.Country__c, 'text');
            addField(detail, 'Landmark', record.Land_Mark__c, 'text');
            addField(detail, 'Verified', record.Verified__c, 'boolean');
            addDetailMarker(detail, record.Id, record.Name, 'Location', record.Street__c, record.City__c, record.State__c, record.Postal_Code__c, record.Country__c);
        } else if (objectApiName == 'Manager__c') {
            Manager__c record = [
                SELECT Id, Name, Email__c, Phone__c, Alternative_Email__c, Alternative_Phone__c, Location__r.Name
                FROM Manager__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            detail.title = record.Name;
            detail.subtitle = record.Location__r?.Name;
            detail.badge = 'Manager';
            addField(detail, 'Email', record.Email__c, 'email');
            addField(detail, 'Phone', record.Phone__c, 'phone');
            addField(detail, 'Alternative Email', record.Alternative_Email__c, 'email');
            addField(detail, 'Alternative Phone', record.Alternative_Phone__c, 'phone');
            addField(detail, 'Location', record.Location__r?.Name, 'text');
        } else if (objectApiName == 'Error_Log__c') {
            Error_Log__c record = [
                SELECT Id, Name, Process_Name__c, Apex_Class_Name__c, Log_Date_Time__c, Log_Details__c
                FROM Error_Log__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            detail.title = record.Name;
            detail.subtitle = record.Process_Name__c;
            detail.badge = 'Operational Log';
            addField(detail, 'Process', record.Process_Name__c, 'text');
            addField(detail, 'Apex Class', record.Apex_Class_Name__c, 'text');
            addField(detail, 'Log Date/Time', record.Log_Date_Time__c, 'datetime');
            addField(detail, 'Details', record.Log_Details__c, 'longtext');
        } else {
            throw new AuraHandledException('Unsupported record type: ' + objectApiName);
        }

        return detail;
    }

    private static void addAddressMarker(
        WorkspaceData data,
        Id recordId,
        String title,
        String description,
        String street,
        String city,
        String state,
        String postalCode,
        String country
    ) {
        if (String.isBlank(street) && String.isBlank(city) && String.isBlank(country)) {
            return;
        }

        data.mapMarkers.add(new Map<String, Object>{
            'value' => String.valueOf(recordId),
            'title' => title,
            'description' => description,
            'location' => new Map<String, Object>{
                'Street' => street,
                'City' => city,
                'State' => state,
                'PostalCode' => postalCode,
                'Country' => country
            }
        });
    }

    private static void addDetailMarker(
        RecordDetailData detail,
        Id recordId,
        String title,
        String description,
        String street,
        String city,
        String state,
        String postalCode,
        String country
    ) {
        if (String.isBlank(street) && String.isBlank(city) && String.isBlank(country)) {
            return;
        }

        detail.mapMarkers.add(new Map<String, Object>{
            'value' => String.valueOf(recordId),
            'title' => title,
            'description' => description,
            'address' => joinAddress(street, city, state, postalCode, country),
            'location' => new Map<String, Object>{
                'Street' => street,
                'City' => city,
                'State' => state,
                'PostalCode' => postalCode,
                'Country' => country
            }
        });
    }

    private static void addField(RecordDetailData detail, String label, Object value, String type) {
        detail.fields.add(new Map<String, Object>{
            'label' => label,
            'value' => value,
            'type' => type,
            'isLongText' => type == 'longtext'
        });
    }

    private static String joinAddress(String street, String city, String state, String postalCode, String country) {
        List<String> parts = new List<String>();
        for (String part : new List<String>{street, city, state, postalCode, country}) {
            if (!String.isBlank(part)) {
                parts.add(part);
            }
        }
        return String.join(parts, ', ');
    }
}
