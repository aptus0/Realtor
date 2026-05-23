import { redirect } from 'next/navigation';
import { createBooking } from '../../../lib/salesforce';

export async function POST(request: Request) {
  const form = await request.formData();
  const rawAppointment = String(form.get('appointmentDateTime') || '');
  await createBooking({
    propertyId: String(form.get('propertyId') || ''),
    firstName: String(form.get('firstName') || ''),
    lastName: String(form.get('lastName') || ''),
    email: String(form.get('email') || ''),
    phone: String(form.get('phone') || ''),
    appointmentDateTime: rawAppointment ? new Date(rawAppointment).toISOString() : null,
    notes: String(form.get('notes') || '')
  });

  redirect('/');
}
