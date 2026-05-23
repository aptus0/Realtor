import Link from 'next/link';
import { Mail, Phone, Star } from 'lucide-react';

export default async function RealtorProfile() {
  return (
    <>
      <header className="topbar shell">
        <Link className="brand" href="/">Realtor Stays</Link>
        <nav className="nav" aria-label="Primary"><Link href="/">Explore</Link></nav>
      </header>
      <main className="shell detail">
        <section className="profile-panel">
          <h1>Featured Realtor</h1>
          <p className="property-meta"><Star size={16} /> Luxury homes, land, and commercial leasing</p>
          <div className="facts">
            <span className="fact"><Mail size={16} /> realtor@example.com</span>
            <span className="fact"><Phone size={16} /> +1 555 0100</span>
          </div>
          <p>Salesforce Realtor records power this profile once the API is extended for public realtor data.</p>
        </section>
      </main>
    </>
  );
}
