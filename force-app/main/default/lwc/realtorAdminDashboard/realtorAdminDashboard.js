import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getSummary from '@salesforce/apex/RealtorAdminDashboardController.getSummary';

const COLUMNS = [
    { label: 'Property #', fieldName: 'Name' },
    { label: 'Title', fieldName: 'Name__c' },
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Type', fieldName: 'Property_Type__c' },
    { label: 'Price', fieldName: 'Price__c', type: 'currency' },
    { label: 'Start', fieldName: 'Start_Date_Time__c', type: 'date' }
];

const QUICK_LINKS = [
    { label: 'Properties', objectApiName: 'Property__c', iconName: 'standard:household' },
    { label: 'Buyers', objectApiName: 'Buyer__c', iconName: 'standard:people' },
    { label: 'Realtors', objectApiName: 'Realtor__c', iconName: 'standard:employee' },
    { label: 'Bookings', objectApiName: 'Property_Buyer__c', iconName: 'standard:event' },
    { label: 'Assignments', objectApiName: 'Property_Realtor__c', iconName: 'standard:relationship' },
    { label: 'Locations', objectApiName: 'Location__c', iconName: 'standard:location' },
    { label: 'Managers', objectApiName: 'Manager__c', iconName: 'standard:user' },
    { label: 'Error Logs', objectApiName: 'Error_Log__c', iconName: 'standard:record' }
];

export default class RealtorAdminDashboard extends NavigationMixin(LightningElement) {
    columns = COLUMNS;
    quickLinks = QUICK_LINKS;
    summary;
    error;

    @wire(getSummary)
    wiredSummary({ data, error }) {
        if (data) {
            this.summary = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.summary = undefined;
        }
    }

    get rows() {
        return this.summary?.recentProperties || [];
    }

    openObject(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: event.currentTarget.dataset.object,
                actionName: 'list'
            },
            state: {
                filterName: 'Recent'
            }
        });
    }

    createRecord(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: event.currentTarget.dataset.object,
                actionName: 'new'
            }
        });
    }
}
