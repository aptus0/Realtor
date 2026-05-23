import { NextResponse } from 'next/server';
import { fetchProperties } from '../../../lib/salesforce';

export async function GET() {
  const properties = await fetchProperties();
  return NextResponse.json(properties);
}
