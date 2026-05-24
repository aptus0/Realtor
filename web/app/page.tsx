import Image from 'next/image';
import Link from 'next/link';
import { ArrowRight, Bath, BedDouble, Building2, CheckCircle2, Home as HomeIcon, MapPin, Search, ShieldCheck, SlidersHorizontal } from 'lucide-react';
import { fetchProperties } from '../lib/salesforce';

function formatPrice(value?: number, type?: string) {
  if (!value) return 'Price on request';
  const suffix = type === 'Daily Rent' ? ' / night' : type === 'Rent' ? ' / month' : '';
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(value) + suffix;
}

export default async function Home() {
  const properties = await fetchProperties();
  const verifiedCount = properties.filter((property) => property.locationVerified).length;

  return (
    <>
      <header className="topbar shell">
        <Link className="brand" href="/">
          <span className="brand-mark"><HomeIcon size={18} /></span>
          Realtor Stays
        </Link>
        <nav className="nav" aria-label="Primary">
          <Link href="/">Explore</Link>
          <Link href="/realtors/featured">Realtors</Link>
          <button className="icon-button" aria-label="Filters"><SlidersHorizontal size={18} /></button>
        </nav>
      </header>

      <main className="shell">
        <section className="hero">
          <div className="hero-copy">
            <span className="eyebrow"><ShieldCheck size={16} /> Salesforce CRM ready</span>
            <h1>Realtor Stays</h1>
            <p>Salesforce-backed property discovery for homes, offices, land, and daily rentals with booking requests routed straight into CRM.</p>
            <div className="hero-actions">
              <a className="primary" href="#listings">Explore listings <ArrowRight size={18} /></a>
              <Link className="secondary" href="/realtors/featured">Meet realtor</Link>
            </div>
            <div className="hero-stats" aria-label="Marketplace highlights">
              <span><strong>{properties.length}</strong> active listings</span>
              <span><strong>{verifiedCount}</strong> verified locations</span>
              <span><strong>24h</strong> CRM response flow</span>
            </div>
          </div>
          <div
            className="hero-image"
            style={{ backgroundImage: "url('https://images.unsplash.com/photo-1600607687939-ce8a6c25118c')" }}
            aria-label="Modern property exterior"
          >
            <div className="hero-card">
              <span>Featured market</span>
              <strong>Austin modern homes</strong>
              <small>Verified visits and booking requests</small>
            </div>
          </div>
        </section>

        <form className="filters" id="listings">
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

        <section className="section-heading">
          <div>
            <span className="eyebrow">Curated properties</span>
            <h2>Find the right place faster</h2>
          </div>
          <p>{properties.length} listings synced from your Salesforce data model.</p>
        </section>

        <section className="content-grid">
          <div className="cards">
            {properties.map((property) => (
              <Link className="property-card" href={`/properties/${property.id}`} key={property.id}>
                <div className="property-media">
                  <Image
                    src={property.imageUrl || 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3'}
                    alt={property.name}
                    width={720}
                    height={450}
                  />
                  <span className="status-pill">{property.status}</span>
                </div>
                <div className="property-body">
                  <div className="property-title">
                    <strong>{property.name}</strong>
                    {property.locationVerified ? <CheckCircle2 size={18} aria-label="Verified address" /> : null}
                  </div>
                  <div className="property-meta">
                    <span><MapPin size={14} /> {property.city || 'Location'} {property.country || ''}</span>
                    <span><Building2 size={14} /> {property.propertyType}</span>
                    <span><BedDouble size={14} /> {property.bedrooms ?? 0}</span>
                    <span><Bath size={14} /> {property.bathrooms ?? 0}</span>
                  </div>
                  <div className="card-footer">
                    <div className="price">{formatPrice(property.price, property.propertyType)}</div>
                    <span className="view-link">View <ArrowRight size={15} /></span>
                  </div>
                </div>
              </Link>
            ))}
          </div>

          <aside className="map-panel">
            <span className="eyebrow">Map preview</span>
            <strong>Explore by neighborhood</strong>
            <p className="property-meta">Google Maps key baglaninca burada canli harita acilir.</p>
            <div className="map-box">
              <span className="map-pin pin-one"><MapPin size={22} /></span>
              <span className="map-pin pin-two"><MapPin size={22} /></span>
              <span className="map-pin pin-three"><MapPin size={22} /></span>
            </div>
          </aside>
        </section>
      </main>
    </>
  );
}
