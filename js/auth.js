// auth.js — ortak damlahelloworld hesabı. email + şifre, Supabase.
// Kendi küçük barını #authbar'a çizer, giriş durumunu onAuth ile dışa verir.
// Koç giriş yapmadan da çalışır (seans localStorage'a düşer); giriş yapınca
// seanslar hesaba senkron olur.

// backend opsiyonel: supabase client ya da config yüklenmediyse koç YINE çalışır
// (cihazda, girişsiz). Bar gizlenir, senkron pasif kalır — çekirdek ürün ölmez.
const hasBackend = !!(window.supabase && window.GG_CONFIG && window.GG_CONFIG.SUPABASE_URL);
export const sb = hasBackend
  ? window.supabase.createClient(window.GG_CONFIG.SUPABASE_URL, window.GG_CONFIG.SUPABASE_ANON_KEY)
  : null;

let user = null;
const listeners = new Set();
export function currentUser() { return user; }
export function onAuth(cb) { listeners.add(cb); cb(user); return () => listeners.delete(cb); }
function emit() { listeners.forEach((cb) => cb(user)); }

const bar = document.getElementById("authbar");
const $ = (id) => document.getElementById(id);

function setUser(u) { user = u || null; emit(); render(); }

function render() {
  if (!bar) return;
  bar.innerHTML = "";
  if (user) {
    const who = document.createElement("span");
    who.className = "auth-who";
    who.textContent = "signed in as " + (user.email || "you") + " — your workouts sync to your account.";
    const out = document.createElement("button");
    out.className = "auth-link";
    out.textContent = "sign out";
    out.onclick = async () => { await sb.auth.signOut(); };
    const del = document.createElement("button");
    del.className = "auth-link";
    del.textContent = "delete my synced workouts";
    del.onclick = async () => {
      if (!window.confirm("delete every workout synced to your account? this cannot be undone.")) return;
      del.disabled = true;
      const { error } = await sb.from("gg_coach_sessions").delete().eq("user_id", user.id);
      del.disabled = false;
      del.textContent = error ? "could not delete - try again" : "deleted.";
      if (!error) window.dispatchEvent(new Event("gg-sessions-changed"));
    };
    bar.append(who, out, del);
    return;
  }
  bar.appendChild(mkLoggedOut());
}

function mkLoggedOut() {
  const wrap = document.createElement("div");
  wrap.className = "auth-form";
  const lead = document.createElement("p");
  lead.className = "auth-lead";
  lead.textContent = "train with an account so your workouts follow you across devices.";
  const email = mkInput("email", "email", "you@example.com");
  const pass = mkInput("password", "password", "at least 6 characters");
  const signIn = mkBtn("sign in");
  const signUp = mkBtn("create account");
  const msg = document.createElement("p");
  msg.className = "auth-msg";
  msg.id = "authMsg";
  const priv = document.createElement("p");
  priv.className = "auth-priv";
  priv.innerHTML = "we store only your workout numbers — reps, scores, dates — tied to your account. never your camera or video. " +
    '<a href="gizlilik.html">how we handle your data</a>.';

  const forgot = document.createElement("button");
  forgot.className = "auth-link";
  forgot.textContent = "forgot your password?";

  signIn.onclick = () => doAuth("in", email.value, pass.value, msg);
  signUp.onclick = () => doAuth("up", email.value, pass.value, msg);
  forgot.onclick = () => doReset(email.value, msg);

  wrap.append(lead, email, pass, signIn, signUp, forgot, msg, priv);
  return wrap;
}

// şifre sıfırlama: maildeki link reset-password.html'e düşer, orada yeni şifre.
async function doReset(email, msg) {
  if (!email) { msg.textContent = "type your email above, then hit forgot again."; return; }
  msg.textContent = "sending a reset link...";
  try {
    const { error } = await sb.auth.resetPasswordForEmail(email, {
      redirectTo: new URL("reset-password.html", location.href).href
    });
    if (error) throw error;
    msg.textContent = "reset link sent - check your inbox.";
  } catch (e) {
    msg.textContent = mapErr(e && e.message ? e.message : String(e));
  }
}

function mkInput(type, name, ph) {
  const i = document.createElement("input");
  i.type = type; i.placeholder = ph; i.className = "auth-in";
  i.autocomplete = type === "email" ? "email" : "current-password";
  i.setAttribute("aria-label", name);
  return i;
}
function mkBtn(label) {
  const b = document.createElement("button");
  b.className = "auth-btn"; b.textContent = label;
  return b;
}

async function doAuth(mode, email, password, msg) {
  msg.textContent = "";
  if (!email || !password) { msg.textContent = "email and password, please."; return; }
  if (password.length < 6) { msg.textContent = "password needs at least 6 characters."; return; }
  msg.textContent = mode === "up" ? "creating your account..." : "signing you in...";
  try {
    if (mode === "up") {
      const { data, error } = await sb.auth.signUp({ email, password });
      if (error) throw error;
      if (!data.session) { msg.textContent = "almost there — check your email to confirm, then sign in."; return; }
      msg.textContent = "";
    } else {
      const { error } = await sb.auth.signInWithPassword({ email, password });
      if (error) throw error;
      msg.textContent = "";
    }
  } catch (e) {
    msg.textContent = mapErr(e && e.message ? e.message : String(e));
  }
}

// Supabase mesajlarını sıcak, insanca dile çevir.
function mapErr(m) {
  const s = m.toLowerCase();
  if (s.includes("invalid login")) return "that email and password did not match.";
  if (s.includes("already registered") || s.includes("already been")) return "you already have an account — try sign in.";
  if (s.includes("email") && s.includes("confirm")) return "please confirm your email first (check your inbox).";
  if (s.includes("rate limit") || s.includes("too many")) return "too many tries — give it a minute.";
  return "something went wrong: " + m;
}

if (sb) {
  sb.auth.getSession().then(({ data }) => setUser(data.session ? data.session.user : null));
  sb.auth.onAuthStateChange((_e, session) => setUser(session ? session.user : null));
} else if (bar) {
  bar.hidden = true;   // backend yok: giriş barını hiç gösterme
}
