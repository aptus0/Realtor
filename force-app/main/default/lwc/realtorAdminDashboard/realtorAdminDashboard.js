import { LightningElement, wire } from 'lwc';
import getSummary from '@salesforce/apex/RealtorAdminDashboardController.getSummary';

const COLUMNS = [
    { label: 'Property #', fieldName: 'Name' },
    { label: 'Title', fieldName: 'Name__c' },
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Type', fieldName: 'Property_Type__c' },
    { label: 'Price', fieldName: 'Price__c', type: 'currency' },
    { label: 'Start', fieldName: 'Start_Date_Time__c', type: 'date' }
];

export default class RealtorAdminDashboard extends LightningElement {
    columns = COLUMNS;
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
}
