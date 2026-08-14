const {PrismaClient}=require('@prisma/client'); const bcrypt=require('bcryptjs');
const prisma=new PrismaClient();
(async()=>{const phone=process.env.ADMIN_PHONE||'9999999999'; const password=process.env.ADMIN_PASSWORD||'Gunashree@123'; const hash=await bcrypt.hash(password,10); const u=await prisma.user.upsert({where:{phone},update:{role:'ADMIN',passwordHash:hash,name:'Gunashree Digital Admin'},create:{phone,passwordHash:hash,name:'Gunashree Digital Admin',role:'ADMIN'}}); console.log(`Admin ready: ${u.phone}`); await prisma.$disconnect();})().catch(e=>{console.error(e);process.exit(1)});
