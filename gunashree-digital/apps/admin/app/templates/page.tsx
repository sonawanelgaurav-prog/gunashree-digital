'use client';

import { useEffect, useState } from 'react';

const API = process.env.NEXT_PUBLIC_API_URL || '';
const EDITABLE_FIELDS = ['NAME', 'BUSINESS_NAME', 'MOBILE', 'ADDRESS', 'PHOTO', 'LOGO'];

type TemplateRow = {
  id: string;
  title: string;
  slug: string;
  status: string;
  width: number;
  height: number;
  category?: { name?: string } | null;
  schema?: { fields?: string[] };
  updatedAt: string;
};

type Category = { id: string; name: string };

export default function Templates() {
  const [rows, setRows] = useState<TemplateRow[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [title, setTitle] = useState('');
  const [slug, setSlug] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [width, setWidth] = useState('1080');
  const [height, setHeight] = useState('1350');
  const [fields, setFields] = useState<string[]>(EDITABLE_FIELDS);
  const [newCategory, setNewCategory] = useState('');
  const [message, setMessage] = useState('');

  const authHeaders = () => ({
    'Content-Type': 'application/json',
    Authorization: `Bearer ${localStorage.getItem('gd_token') || ''}`,
  });

  const load = async () => {
    const [templateResponse, categoryResponse] = await Promise.all([
      fetch(`${API}/api/templates?status=ALL`),
      fetch(`${API}/api/categories`),
    ]);
    if (templateResponse.ok) setRows(await templateResponse.json());
    if (categoryResponse.ok) setCategories(await categoryResponse.json());
  };

  useEffect(() => {
    void load();
  }, []);

  const add = async () => {
    if (!title.trim() || !slug.trim()) {
      setMessage('Add a title and a URL slug first.');
      return;
    }
    const response = await fetch(`${API}/api/templates`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({
        title: title.trim(),
        slug: slug.trim(),
        categoryId: categoryId || null,
        width: Number(width),
        height: Number(height),
        fields,
        status: 'DRAFT',
        schema: {
          version: 1,
          background: '#FFF8F1',
          fields,
          layers: [
            { id: 'name', type: 'text', text: '{{NAME}}', x: 80, y: 80, width: 880, height: 90, fontSize: 56, color: '#17132B' },
            { id: 'photo', type: 'image', src: '', x: 80, y: 240, width: 500, height: 500 },
          ],
        },
      }),
    });
    if (!response.ok) {
      setMessage('Unable to create template. Check your admin login.');
      return;
    }
    setTitle('');
    setSlug('');
    setMessage('Draft template created.');
    await load();
  };

  const togglePublish = async (row: TemplateRow) => {
    const nextStatus = row.status === 'PUBLISHED' ? 'DRAFT' : 'PUBLISHED';
    await fetch(`${API}/api/templates/${row.id}`, {
      method: 'PATCH',
      headers: authHeaders(),
      body: JSON.stringify({ status: nextStatus }),
    });
    await load();
  };

  const createCategory = async () => {
    if (!newCategory.trim()) return;
    await fetch(`${API}/api/categories`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({ name: newCategory.trim() }),
    });
    setNewCategory('');
    await load();
  };

  return (
    <>
      <div className="top">
        <div>
          <h1>Templates</h1>
          <p>Build, publish, and manage the designs available in the mobile app.</p>
        </div>
      </div>
      <div className="grid" style={{ alignItems: 'start' }}>
        <div className="card form">
          <h2>Create a template</h2>
          <input placeholder="Template title" value={title} onChange={(event) => setTitle(event.target.value)} />
          <input placeholder="URL slug" value={slug} onChange={(event) => setSlug(event.target.value)} />
          <div className="row">
            <select value={categoryId} onChange={(event) => setCategoryId(event.target.value)}>
              <option value="">No category</option>
              {categories.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
            </select>
            <select value={`${width}x${height}`} onChange={(event) => {
              const [nextWidth, nextHeight] = event.target.value.split('x');
              setWidth(nextWidth);
              setHeight(nextHeight);
            }}>
              <option value="1080x1080">Square · 1:1</option>
              <option value="1080x1350">Portrait · 4:5</option>
              <option value="1080x1920">Story · 9:16</option>
            </select>
          </div>
          <div>
            <strong>Editable fields</strong>
            <div className="row" style={{ flexWrap: 'wrap', marginTop: 8 }}>
              {EDITABLE_FIELDS.map((field) => (
                <label key={field} style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                  <input type="checkbox" checked={fields.includes(field)} onChange={() => setFields((current) => current.includes(field) ? current.filter((item) => item !== field) : [...current, field])} />
                  {field}
                </label>
              ))}
            </div>
          </div>
          <button className="btn" onClick={add}>Create draft</button>
          {message && <small>{message}</small>}
        </div>
        <div className="card form">
          <h2>Categories</h2>
          <p>Organize published templates so creators can find them quickly.</p>
          <input placeholder="New category name" value={newCategory} onChange={(event) => setNewCategory(event.target.value)} />
          <button className="btn secondary" onClick={createCategory}>Add category</button>
          <div className="row" style={{ flexWrap: 'wrap' }}>
            {categories.map((category) => <span key={category.id} className="pill">{category.name}</span>)}
          </div>
        </div>
      </div>
      <div className="card" style={{ marginTop: 16 }}>
        <table className="table">
          <thead><tr><th>Title</th><th>Category</th><th>Status</th><th>Size</th><th>Fields</th><th>Updated</th><th /></tr></thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.id}>
                <td><strong>{row.title}</strong><br /><small>{row.slug}</small></td>
                <td>{row.category?.name || 'Uncategorized'}</td>
                <td><span className={`pill ${row.status === 'PUBLISHED' ? 'published' : ''}`}>{row.status}</span></td>
                <td>{row.width}×{row.height}</td>
                <td>{row.schema?.fields?.length || 0}</td>
                <td>{new Date(row.updatedAt).toLocaleDateString()}</td>
                <td><button className="btn secondary" onClick={() => togglePublish(row)}>{row.status === 'PUBLISHED' ? 'Unpublish' : 'Publish'}</button></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}