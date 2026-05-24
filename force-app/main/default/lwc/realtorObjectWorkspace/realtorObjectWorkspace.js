import { LightningElement, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getWorkspace from '@salesforce/apex/RealtorAdminDashboardController.getWorkspace';
import getRecordDetail from '@salesforce/apex/RealtorAdminDashboardController.getRecordDetail';

const ROW_ACTIONS = [{ label: 'Open', name: 'open' }];

export default class RealtorObjectWorkspace extends NavigationMixin(LightningElement) {
    workspace;
    error;
    pageReference;
    selectedMapValue;
    selectedDetail;

    @wire(CurrentPageReference)
    wiredPageReference(pageReference) {
        this.pageReference = pageReference;
    }

    @wire(getWorkspace, { workspaceKey: '$workspaceKey' })
    wiredWorkspace({ data, error }) {
        if (data) {
            this.workspace = data;
            this.error = undefined;
            this.selectedMapValue = data.mapMarkers?.[0]?.value;
        } else if (error) {
            this.error = error;
            this.workspace = undefined;
            this.selectedMapValue = undefined;
        }
    }

    get workspaceKey() {
        const attributes = this.pageReference?.attributes || {};
        return attributes.apiName || attributes.name || attributes.componentName || 'Realtor_Properties';
    }

    get columns() {
        const dataColumns = (this.workspace?.columns || []).map((column) => ({
            label: column.label,
            fieldName: column.fieldName,
            type: column.type || 'text'
        }));

        return [
            ...dataColumns,
            {
                type: 'action',
                typeAttributes: { rowActions: ROW_ACTIONS }
            }
        ];
    }

    get rowCount() {
        return this.workspace?.rows?.length || 0;
    }

    get hasRows() {
        return this.rowCount > 0;
    }

    get isLogWorkspace() {
        return this.workspace?.key === 'logs';
    }

    get mapMarkers() {
        return this.workspace?.mapMarkers || [];
    }

    get hasMapMarkers() {
        return this.mapMarkers.length > 0;
    }

    get mapTitle() {
        return `${this.workspace?.label || 'Records'} Map`;
    }

    get mapHeading() {
        return this.workspace?.key === 'locations' ? 'See every saved location' : 'See where homes are listed';
    }

    get mapDescription() {
        return this.workspace?.key === 'locations'
            ? 'Location records are plotted from their address fields so operations can verify coverage quickly.'
            : 'Property markers use each listing address through its related Location record.';
    }

    get mapLocations() {
        return this.mapMarkers.map((marker) => ({
            value: marker.value,
            title: marker.title,
            address: this.formatAddress(marker.location)
        }));
    }

    get selectedMapMarker() {
        return this.mapMarkers.find((marker) => marker.value === this.selectedMapValue) || this.mapMarkers[0];
    }

    get selectedMapTitle() {
        return `Google Maps - ${this.selectedMapMarker?.title || this.mapTitle}`;
    }

    get selectedMapAddress() {
        return this.formatAddress(this.selectedMapMarker?.location);
    }

    get googleMapsEmbedUrl() {
        return `https://www.google.com/maps?q=${encodeURIComponent(this.selectedMapAddress)}&output=embed`;
    }

    get googleMapsSearchUrl() {
        return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(this.selectedMapAddress)}`;
    }

    get logCards() {
        return (this.workspace?.rows || []).slice(0, 6).map((row) => ({
            ...row,
            processName: row.processName || 'Unspecified Process',
            apexClassName: row.apexClassName || 'No Apex class',
            logDetails: row.logDetails || 'No details captured.',
            logDateTime: row.logDateTime || ''
        }));
    }

    get tableTitle() {
        return `Recent ${this.workspace?.label || 'Records'}`;
    }

    get selectedFields() {
        return (this.selectedDetail?.fields || []).map((field) => ({
            ...field,
            displayValue: this.formatValue(field.value, field.type),
            className: field.isLongText ? 'preview-field span-all' : 'preview-field'
        }));
    }

    get selectedHasMap() {
        return (this.selectedDetail?.mapMarkers || []).length > 0;
    }

    get selectedAddress() {
        return this.selectedDetail?.mapMarkers?.[0]?.address || '';
    }

    get selectedMapTitle() {
        return `Google Maps - ${this.selectedDetail?.title || 'Selected record'}`;
    }

    get selectedGoogleMapsEmbedUrl() {
        return `https://www.google.com/maps?q=${encodeURIComponent(this.selectedAddress)}&output=embed`;
    }

    get selectedGoogleMapsSearchUrl() {
        return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(this.selectedAddress)}`;
    }

    createRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.workspace.objectApiName,
                actionName: 'new'
            }
        });
    }

    openList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.workspace.objectApiName,
                actionName: 'list'
            },
            state: {
                filterName: 'Recent'
            }
        });
    }

    async handleRowAction(event) {
        if (event.detail.action.name !== 'open') {
            return;
        }

        await this.loadRecordDetail(event.detail.row.id);
    }

    async openRecordFromButton(event) {
        await this.loadRecordDetail(event.currentTarget.dataset.id);
    }

    selectMapMarker(event) {
        this.selectedMapValue = event.currentTarget.dataset.value;
    }

    formatAddress(location = {}) {
        return [
            location.Street,
            location.City,
            location.State,
            location.PostalCode,
            location.Country
        ].filter(Boolean).join(', ');
    }

    async loadRecordDetail(recordId) {
        this.selectedDetail = await getRecordDetail({ recordId });
    }

    closeSelectedDetail() {
        this.selectedDetail = undefined;
    }

    openSelectedRecord() {
        this.openRecord(this.selectedDetail.recordId);
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

    openRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName: this.workspace.objectApiName,
                actionName: 'view'
            }
        });
    }
}
