import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const GOWA_URL = Deno.env.get("GOWA_BASE_URL") ?? "";
const GOWA_TOKEN = Deno.env.get("GOWA_TOKEN") ?? "";
const GOWA_DEVICE = Deno.env.get("GOWA_DEVICE_ID") ?? "";

interface Payload {
  type: "INSERT" | "UPDATE";
  table: "transactions";
  record: {
    id: number;
    kode: string;
    nama_pelanggan: string;
    alamat: string;
    berat: number;
    jenis: string;
    harga: number;
    metode: string;
    status: string;
    tanggal: string;
    toko_id?: number;
  };
}

async function getAdminPhone(supabaseUrl: string, serviceRoleKey: string, tokoId?: number): Promise<string | null> {
  let url = `${supabaseUrl}/rest/v1/toko?select=nomor_admin&nomor_admin=not.is.null&limit=1`;
  if (tokoId) {
    url = `${supabaseUrl}/rest/v1/toko?select=nomor_admin&id=eq.${tokoId}&limit=1`;
  }
  
  const res = await fetch(url, { 
    headers: { apikey: serviceRoleKey, authorization: `Bearer ${serviceRoleKey}` } 
  });
  const rows = await res.json();
  return rows?.[0]?.nomor_admin ?? null;
}

async function sendWA(phone: string, message: string): Promise<boolean> {
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };

  if (GOWA_TOKEN) {
    const token = GOWA_TOKEN.includes(":") ? btoa(GOWA_TOKEN) : GOWA_TOKEN;
    headers["Authorization"] = `Basic ${token}`;
  }
  
  if (GOWA_DEVICE) {
    headers["X-Device-Id"] = GOWA_DEVICE;
  }

  const endpoint = GOWA_URL.endsWith("/") ? `${GOWA_URL}send/message` : `${GOWA_URL}/send/message`;
  const normalizedPhone = phone.replace(/\D/g, "");

  console.log(`[sendWA] Mengirim WA ke ${normalizedPhone} via endpoint: ${endpoint}`);

  try {
    const res = await fetch(endpoint, {
      method: "POST",
      headers,
      body: JSON.stringify({
        phone: normalizedPhone,
        message: message,
      }),
    });
    
    const responseText = await res.text();
    console.log(`[sendWA] Response Status: ${res.status}`);
    console.log(`[sendWA] Response Body: ${responseText}`);
    
    return res.ok;
  } catch (error) {
    console.error(`[sendWA] Fetch Error:`, error);
    return false;
  }
}

serve(async (req: Request) => {
  try {
    const payload: Payload = await req.json();
    console.log(`[Webhook] Menerima payload untuk tabel: ${payload.table}, event: ${payload.type}`);

    if ((payload.type !== "INSERT" && payload.type !== "UPDATE") || payload.table !== "transactions") {
      console.log(`[Webhook] Diabaikan, bukan INSERT/UPDATE di transactions.`);
      return new Response("Ignored", { status: 200 });
    }

    const rec = payload.record;
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const adminPhone = await getAdminPhone(supabaseUrl, serviceRoleKey, rec.toko_id);
    console.log(`[Webhook] Nomor Admin ditemukan: ${adminPhone}`);
    if (!adminPhone) {
      console.log("No admin phone configured");
      return new Response("No admin phone", { status: 200 });
    }

    const tanggal = new Date(rec.tanggal).toLocaleString("id-ID", { timeZone: "Asia/Jakarta" });

    const isCancel = payload.type === "UPDATE" && rec.status === "Batal";
    const message = isCancel
      ? `🚫 *LaundryIN — Pesanan Dibatalkan*

👤 ${rec.nama_pelanggan}
📍 ${rec.alamat}
👕 ${rec.jenis} • ${rec.berat}Kg
💰 Rp ${rec.harga.toLocaleString("id-ID")} (${rec.metode})
🔖 Kode: #${rec.kode ?? rec.id}
⏰ ${tanggal}

_Pesanan telah dibatalkan oleh pelanggan._`
      : `🧺 *LaundryIN — Pesanan Baru*

👤 ${rec.nama_pelanggan}
📍 ${rec.alamat}
👕 ${rec.jenis} • ${rec.berat}Kg
💰 Rp ${rec.harga.toLocaleString("id-ID")} (${rec.metode})
🔖 Kode: #${rec.kode ?? rec.id}
⏰ ${tanggal}

_Segera diproses ya._`;

    const ok = await sendWA(adminPhone, message);

    if (!ok) {
      console.error("GOWA send failed");
      return new Response("GOWA failed", { status: 500 });
    }

    return new Response("OK", { status: 200 });
  } catch (e) {
    console.error(e);
    return new Response("Error", { status: 500 });
  }
});
