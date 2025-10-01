import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const plans = [
    { name: 'Premium 1 Month', durationMonths: 1, price: 100_000, currency: 'VND', isActive: true },
    { name: 'Premium 6 Months', durationMonths: 6, price: 550_000, currency: 'VND', isActive: true },
    { name: 'Premium 1 Year', durationMonths: 12, price: 1_000_000, currency: 'VND', isActive: true },
  ];

  for (const p of plans) {
    const existing = await prisma.subscriptionPlan.findFirst({ where: { name: p.name } });
    if (existing) {
      await prisma.subscriptionPlan.update({ where: { id: existing.id }, data: { ...p } });
    } else {
      await prisma.subscriptionPlan.create({ data: { ...p } });
    }
  }
  console.log('Seeded/updated default subscription plans.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

