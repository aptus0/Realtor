import Image from 'next/image';
import Link from 'next/link';
import { Bath, BedDouble, Building2, MapPin, Search, SlidersHorizontal } from 'lucide-react';
import { fetchProperties } from '../lib/salesforce';

function formatPrice(value?: number, type?: string) {
  if (!value) return 'Price on request';
  const suffix = type === 'Daily Rent' ? ' / night' : type === 'Rent' ? ' / month' : '';
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(value) + suffix;
}

export default async function Home() {
  const properties = await fetchProperties();

  return (
    <>
      <header className="topbar shell">
        <Link className="brand" href="/">Realtor Stays</Link>
        <nav className="nav" aria-label="Primary">
          <Link href="/">Explore</Link>
          <Link href="/realtors/featured">Realtors</Link>
          <button className="icon-button" aria-label="Filters"><SlidersHorizontal size={18} /></button>
        </nav>
      </header>

      <main className="shell">
        <section className="hero">
          <div className="hero-copy">
            <h1>Realtor Stays</h1>
            <p>Salesforce-backed property discovery for homes, offices, land, and daily rentals with booking requests routed straight into CRM.</p>
          </div>
          <div
            className="hero-image"
            style={{ backgroundImage: "url('https://images.unsplash.com/photo-1600607687939-ce8a6c25118c')" }}
            aria-label="Modern property exterior"
          />
        </section>

        <form className="filters">
          <input aria-label="Search destination" placeholder="City, country, or listing" />
          <select aria-label="Property type" defaultValue="">
            <option value="">Any type</option>
            <option>Rent</option>
            <option>Sell</option>
            <option>Daily Rent</option>
          </select>
          <input aria-label="Minimum price" placeholder="Min price" />
          <input aria-label="Maximum price" placeholder="Max price" />
          <button className="primary" type="button"><Search size={18} /> Search</button>
        </form>

        <section className="content-grid">
          <div className="cards">
            {properties.map((property) => (
              <Link className="property-card" href={`/properties/${property.id}`} key={property.id}>
                <Image
                  src={property.imageUrl || 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3'}
                  alt={property.name}
                  width={720}
                  height={450}
                />
                <div className="property-body">
                  <strong>{property.name}</strong>
                  <div className="property-meta">
                    <span><MapPin size={14} /> {property.city || 'Location'} {property.country || ''}</span>
                    <span><Building2 size={14} /> {property.propertyType}</span>
                    <span><BedDouble size={14} /> {property.bedrooms ?? 0}</span>
                    <span><Bath size={14} /> {property.bathrooms ?? 0}</span>
                  </div>
                  <div className="price">{formatPrice(property.price, property.propertyType)}</div>
                </div>
              </Link>
            ))}
          </div>

          <aside className="map-panel">
            <strong>Map View</strong>
            <p className="property-meta">Google Maps key bağlanınca burada canlı harita açılır.</p>
            <div className="map-box">
              <MapPin size={44} color="#1f7a58" />
            </div>
          </aside>
        </section>
      </main>
    </>
  );
}
