import Link from 'next/link';
import { Home, Mail, Phone, Star } from 'lucide-react';

export default async function RealtorProfile() {
  return (
    <>
      <header className="topbar shell">
        <Link className="brand" href="/">
          <span className="brand-mark"><Home size={18} /></span>
          Realtor Stays
        </Link>
        <nav className="nav" aria-label="Primary"><Link href="/">Explore</Link></nav>
      </header>
      <main className="shell detail">
        <section className="profile-panel">
          <span className="eyebrow"><Star size={16} /> Partner profile</span>
          <h1>Featured Realtor</h1>
          <p className="profile-lede">Luxury homes, land, and commercial leasing with booking activity ready to flow into Salesforce Realtor records.</p>
          <div className="facts">
            <span className="fact"><Mail size={16} /> realtor@example.com</span>
            <span className="fact"><Phone size={16} /> +1 555 0100</span>
          </div>
          <p className="property-meta">Salesforce Realtor records power this profile once the API is extended for public realtor data.</p>
        </section>
      </main>
    </>
  );
}
