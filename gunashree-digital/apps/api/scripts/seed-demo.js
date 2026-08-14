const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const templates = [
  {
    title: 'Festival Celebration',
    slug: 'festival-celebration',
    category: 'Festivals',
    width: 1080,
    height: 1350,
    background: '#FFF0E1',
    layers: [
      { id: 'eyebrow', type: 'text', text: 'SPECIAL INVITATION', x: 78, y: 90, width: 880, height: 50, fontSize: 28, color: '#A64B2A' },
      { id: 'title', type: 'text', text: 'Celebrate\\nwith joy', x: 78, y: 220, width: 860, height: 230, fontSize: 92, color: '#17132B' },
      { id: 'name', type: 'text', text: '{{NAME}}', x: 80, y: 1060, width: 700, height: 70, fontSize: 38, color: '#A64B2A' },
    ],
  },
  {
    title: 'Business Promotion',
    slug: 'business-promotion',
    category: 'Business',
    width: 1080,
    height: 1350,
    background: '#E8F3F0',
    layers: [
      { id: 'label', type: 'text', text: 'NOW OPEN', x: 80, y: 80, width: 880, height: 52, fontSize: 32, color: '#1C7262' },
      { id: 'title', type: 'text', text: '{{BUSINESS_NAME}}', x: 80, y: 200, width: 900, height: 190, fontSize: 80, color: '#143C38' },
      { id: 'body', type: 'text', text: 'Quality you can\\nfeel every day.', x: 80, y: 470, width: 700, height: 150, fontSize: 48, color: '#275A53' },
      { id: 'mobile', type: 'text', text: '{{MOBILE}}', x: 80, y: 1130, width: 800, height: 60, fontSize: 36, color: '#143C38' },
    ],
  },
  {
    title: 'Daily Story',
    slug: 'daily-story',
    category: 'Social Media',
    width: 1080,
    height: 1920,
    background: '#17132B',
    layers: [
      { id: 'top', type: 'text', text: 'A LITTLE\\nINSPIRATION', x: 74, y: 120, width: 880, height: 250, fontSize: 84, color: '#FFFFFF' },
      { id: 'quote', type: 'text', text: 'Make today\\nbeautiful.', x: 74, y: 850, width: 900, height: 250, fontSize: 78, color: '#F7C96F' },
      { id: 'handle', type: 'text', text: '@gunashreedigital', x: 74, y: 1790, width: 850, height: 60, fontSize: 28, color: '#D7D2E6' },
    ],
  },
];

async function seed() {
  for (const name of ['Festivals', 'Business', 'Social Media']) {
    await prisma.category.upsert({
      where: { slug: name.toLowerCase().replace(/\s+/g, '-') },
      update: { name },
      create: { name, slug: name.toLowerCase().replace(/\s+/g, '-') },
    });
  }

  for (const item of templates) {
    const category = await prisma.category.findUnique({
      where: { slug: item.category.toLowerCase().replace(/\s+/g, '-') },
    });
    await prisma.template.upsert({
      where: { slug: item.slug },
      update: {
        title: item.title,
        width: item.width,
        height: item.height,
        status: 'PUBLISHED',
        categoryId: category.id,
        schema: {
          version: 1,
          background: item.background,
          fields: ['NAME', 'BUSINESS_NAME', 'MOBILE', 'ADDRESS', 'PHOTO', 'LOGO'],
          layers: item.layers,
        },
      },
      create: {
        title: item.title,
        slug: item.slug,
        width: item.width,
        height: item.height,
        status: 'PUBLISHED',
        categoryId: category.id,
        schema: {
          version: 1,
          background: item.background,
          fields: ['NAME', 'BUSINESS_NAME', 'MOBILE', 'ADDRESS', 'PHOTO', 'LOGO'],
          layers: item.layers,
        },
      },
    });
  }

  console.log(`Seeded ${templates.length} published templates.`);
}

seed()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());