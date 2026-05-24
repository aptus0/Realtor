import Image from 'next/image';
import Link from 'next/link';
import { Bath, BedDouble, CalendarDays, CheckCircle2, Home, MapPin, Ruler, Send } from 'lucide-react';
import { fetchProperty } from '../../../lib/salesforce';

export default async function PropertyDetail({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const property = await fetchProperty(id);

  if (!property) {
    return (
      <main className="shell">
        <p>Property not found.</p>
        <Link href="/">Back to listings</Link>
      </main>
    );
  }

  return (
    <>
      <header className="topbar shell">
        <Link className="brand" href="/">
          <span className="brand-mark"><Home size={18} /></span>
          Realtor Stays
        </Link>
        <nav className="nav" aria-label="Primary">
          <Link href="/">Explore</Link>
          <Link href="/realtors/featured">Realtors</Link>
        </nav>
      </header>
      <main className="shell detail">
        <section>
          <div className="detail-media">
            <Image
              className="detail-hero"
              src={property.imageUrl || 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3'}
              alt={property.name}
              width={1100}
              height={680}
              priority
            />
            <span className="status-pill">{property.status}</span>
          </div>
          <span className="eyebrow">{property.propertyType} property</span>
          <h1>{property.name}</h1>
          <div className="property-meta">
            <span><MapPin size={15} /> {property.city || 'Location'}, {property.country || ''}</span>
            <span>{property.propertyNumber}</span>
            {property.locationVerified ? <span><CheckCircle2 size={15} /> Verified address</span> : null}
          </div>
          <div className="facts">
            <span className="fact"><BedDouble size={16} /> {property.bedrooms ?? 0} beds</span>
            <span className="fact"><Bath size={16} /> {property.bathrooms ?? 0} baths</span>
            <span className="fact"><Ruler size={16} /> {property.areaSqFt ?? 0} sq ft</span>
            <span className="fact"><CalendarDays size={16} /> {property.propertyType}</span>
          </div>
          <p>{property.description}</p>
        </section>

        <aside className="booking-panel">
          <span className="eyebrow">Fast request</span>
          <h2>Request a visit</h2>
          <form action="/api/bookings" method="post">
            <input type="hidden" name="propertyId" value={property.id} />
            <input name="firstName" placeholder="First name" required />
            <input name="lastName" placeholder="Last name" required />
            <input name="email" placeholder="Email" type="email" required />
            <input name="phone" placeholder="Phone" required />
            <input name="appointmentDateTime" type="datetime-local" />
            <textarea name="notes" placeholder="Notes" />
            <button className="primary" type="submit">Send booking request <Send size={16} /></button>
          </form>
        </aside>
      </main>
    </>
  );
}
