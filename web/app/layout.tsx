import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Realtor Stays',
  description: 'Modern property discovery and booking platform backed by Salesforce CRM.'
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
