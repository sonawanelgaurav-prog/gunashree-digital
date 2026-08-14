'use client';
import {useState} from 'react';
export default function Login(){
 const [phone,setPhone]=useState(''); const [password,setPassword]=useState(''); const [msg,setMsg]=useState('');
 async function login(){const r=await fetch('/api/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({phone,password})}); const d=await r.json(); if(!r.ok){setMsg(d.error||'Login failed');return;} localStorage.setItem('gd_token',d.token); location.href='/';}
 return <main style={{maxWidth:420,margin:'80px auto',padding:24}}><h1>Gunashree Digital</h1><p>Admin Login</p><input placeholder="Mobile" value={phone} onChange={e=>setPhone(e.target.value)} style={{display:'block',width:'100%',margin:'12px 0',padding:12}}/><input placeholder="Password" type="password" value={password} onChange={e=>setPassword(e.target.value)} style={{display:'block',width:'100%',margin:'12px 0',padding:12}}/><button onClick={login} style={{padding:12,width:'100%'}}>Login</button>{msg&&<p>{msg}</p>}</main>
}
