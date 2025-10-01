export function addMonths(date: Date, months: number): Date {
  const d = new Date(date);
  const day = d.getDate();
  d.setMonth(d.getMonth() + months);
  // Handle month-end cases (e.g., Jan 31 + 1 month -> Feb end)
  if (d.getDate() < day) {
    d.setDate(0);
  }
  return d;
}

