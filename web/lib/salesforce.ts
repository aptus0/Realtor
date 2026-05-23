export type Property = {
  id: string;
  propertyNumber: string;
  name: string;
  status: string;
  propertyType: string;
  price?: number;
  bedrooms?: number;
  bathrooms?: number;
  areaSqFt?: number;
  imageUrl?: string;
  description?: string;
  startDateTime?: string;
  endDateTime?: string;
  locationVerified?: boolean;
  street?: string;
  city?: string;
  country?: string;
};

const fallbackProperties: Property[] = [
  {
    id: 'demo-1',
    propertyNumber: 'PROP-10001',
    name: 'Glass House Near Downtown',
    status: 'Prepared',
    propertyType: 'Rent',
    price: 4200,
    bedrooms: 3,
    bathrooms: 2.5,
    areaSqFt: 2100,
    imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c',
    description: 'A bright, modern home with open living space, walkable dining, and a private garden.',
    city: 'Austin',
    country: 'USA',
    locationVerified: true
  },
  {
    id: 'demo-2',
    propertyNumber: 'PROP-10002',
    name: 'Quiet Commercial Loft',
    status: 'In Progress',
    propertyType: 'Sell',
    price: 875000,
    bedrooms: 0,
    bathrooms: 2,
    areaSqFt: 3400,
    imageUrl: 'https://images.unsplash.com/photo-1497366754035-f200968a6e72',
    description: 'Flexible office loft with polished concrete, freight access, and room for a growing team.',
    city: 'New York',
    country: 'USA',
    locationVerified: true
  },
  {
    id: 'demo-3',
    propertyNumber: 'PROP-10003',
    name: 'Weekend Lake Cabin',
    status: 'Prepared',
    propertyType: 'Daily Rent',
    price: 325,
    bedrooms: 2,
    bathrooms: 1,
    areaSqFt: 980,
    imageUrl: 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85',
    description: 'A compact daily rental with lake access, warm interiors, and a calm outdoor deck.',
    city: 'Burlington',
    country: 'USA',
    locationVerified: false
  }
];

async function getAccessToken() {
  const loginUrl = process.env.SALESFORCE_LOGIN_URL || 'https://login.salesforce.com';
  const clientId = process.env.SALESFORCE_CLIENT_ID;
  const clientSecret = process.env.SALESFORCE_CLIENT_SECRET;
  const username = process.env.SALESFORCE_USERNAME;
  const password = process.env.SALESFORCE_PASSWORD;
  const token = process.env.SALESFORCE_SECURITY_TOKEN || '';

  if (!clientId || !clientSecret || !username || !password) {
    return null;
  }

  const body = new URLSearchParams({
    grant_type: 'password',
    client_id: clientId,
    client_secret: clientSecret,
    username,
    password: password + token
  });

  const response = await fetch(`${loginUrl}/services/oauth2/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
    cache: 'no-store'
  });

  if (!response.ok) {
    throw new Error('Salesforce authentication failed');
  }

  return response.json() as Promise<{ access_token: string; instance_url: string }>;
}

export async function fetchProperties(): Promise<Property[]> {
  const auth = await getAccessToken();
  if (!auth) {
    return fallbackProperties;
  }

  const response = await fetch(`${auth.instance_url}/services/apexrest/realtor/v1/properties`, {
    headers: { Authorization: `Bearer ${auth.access_token}` },
    cache: 'no-store'
  });

  if (!response.ok) {
    throw new Error('Could not load properties from Salesforce');
  }

  return response.json();
}

export async function fetchProperty(id: string): Promise<Property | undefined> {
  const properties = await fetchProperties();
  return properties.find((property) => property.id === id);
}

export async function createBooking(payload: unknown) {
  const auth = await getAccessToken();
  if (!auth) {
    return { status: 'Demo', bookingId: `demo-${Date.now()}` };
  }

  const response = await fetch(`${auth.instance_url}/services/apexrest/realtor/v1/bookings`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${auth.access_token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(payload)
  });

  if (!response.ok) {
    throw new Error('Booking could not be created');
  }

  return response.json();
}
