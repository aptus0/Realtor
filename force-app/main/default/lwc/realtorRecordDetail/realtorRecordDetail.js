import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRecordDetail from '@salesforce/apex/RealtorAdminDashboardController.getRecordDetail';

export default class RealtorRecordDetail extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    detail;
    error;

    @wire(getRecordDetail, { recordId: '$recordId' })
    wiredDetail({ data, error }) {
        if (data) {
            this.detail = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.detail = undefined;
        }
    }

    get fields() {
        return (this.detail?.fields || []).map((field) => ({
            ...field,
            displayValue: this.formatValue(field.value, field.type),
            className: field.isLongText ? 'field span-all' : 'field'
        }));
    }

    get hasMapMarkers() {
        return (this.detail?.mapMarkers || []).length > 0;
    }

    get selectedAddress() {
        return this.detail?.mapMarkers?.[0]?.address || '';
    }

    get mapTitle() {
        return `Google Maps - ${this.detail?.title || 'Record location'}`;
    }

    get googleMapsEmbedUrl() {
        return `https://www.google.com/maps?q=${encodeURIComponent(this.selectedAddress)}&output=embed`;
    }

    get googleMapsSearchUrl() {
        return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(this.selectedAddress)}`;
    }

    editRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: this.detail.objectApiName,
                actionName: 'edit'
            }
        });
    }

    openList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.detail.objectApiName,
                actionName: 'list'
            },
            state: {
                filterName: 'Recent'
            }
        });
    }

    formatValue(value, type) {
        if (value === null || value === undefined || value === '') {
            return '-';
        }

        if (type === 'boolean') {
            return value ? 'Yes' : 'No';
        }

        if (type === 'currency') {
            return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(value);
        }

        if (type === 'datetime') {
            return new Intl.DateTimeFormat('en-US', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value));
        }

        return String(value);
    }
}
