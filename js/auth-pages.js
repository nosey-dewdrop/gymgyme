// auth-pages.js — wires the membership pages (signup / signin / account) to the
// shared supabase client from auth.js. no keys here; sb comes from config.js via
// auth.js. copy stays short and calm, lowercase, no marketing.
import { sb, currentUser, onAuth } from "./auth.js";

const $ = (id) => document.getElementById(id);

// supabase messages -> plain, human english (same voice as auth.js)
function mapErr(m) {
  const s = (m || "").toLowerCase();
  if (s.includes("invalid login")) return "that email and password did not match.";
  if (s.includes("already registered") || s.includes("already been")) return "you already have an account — try sign in.";
  if (s.includes("email") && s.includes("confirm")) return "please confirm your email first (check your inbox).";
  if (s.includes("rate limit") || s.includes("too many")) return "too many tries — give it a minute.";
  if (s.includes("password")) return "password needs at least 6 characters.";
  return "something went wrong: " + m;
}

function setMsg(el, text, bad) {
  if (!el) return;
  el.textContent = text || "";
  el.classList.toggle("bad", !!bad);
}

// backend missing (config not loaded): tell the visitor plainly, don't pretend.
function needBackend(msg) {
  if (sb) return false;
  setMsg(msg, "accounts are unavailable right now — you can still train as a guest.", true);
  return true;
}

// ── signup ──
function wireSignup() {
  const form = $("signupForm");
  if (!form) return;
  const email = $("email"), pass = $("password"), msg = $("authMsg");
  const btn = $("submit");
  onAuth((u) => { if (u) location.replace("account.html"); });
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    if (needBackend(msg)) return;
    const em = email.value.trim(), pw = pass.value;
    if (!em || !pw) { setMsg(msg, "email and password, please.", true); return; }
    if (pw.length < 6) { setMsg(msg, "password needs at least 6 characters.", true); return; }
    btn.disabled = true;
    setMsg(msg, "creating your account...");
    try {
      const { data, error } = await sb.auth.signUp({ email: em, password: pw });
      if (error) throw error;
      if (!data.session) {
        setMsg(msg, "almost there — check your email to confirm, then sign in.");
        btn.disabled = false;
        return;
      }
      // session live (email confirmation off) — onAuth redirects to account.
      setMsg(msg, "you're in.");
    } catch (err) {
      setMsg(msg, mapErr(err && err.message ? err.message : String(err)), true);
      btn.disabled = false;
    }
  });
}

// ── signin ──
function wireSignin() {
  const form = $("signinForm");
  if (!form) return;
  const email = $("email"), pass = $("password"), msg = $("authMsg");
  const btn = $("submit");
  onAuth((u) => { if (u) location.replace("account.html"); });
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    if (needBackend(msg)) return;
    const em = email.value.trim(), pw = pass.value;
    if (!em || !pw) { setMsg(msg, "email and password, please.", true); return; }
    btn.disabled = true;
    setMsg(msg, "signing you in...");
    try {
      const { error } = await sb.auth.signInWithPassword({ email: em, password: pw });
      if (error) throw error;
      // onAuth redirects to account on success.
    } catch (err) {
      setMsg(msg, mapErr(err && err.message ? err.message : String(err)), true);
      btn.disabled = false;
    }
  });
}

// ── account ──
const SESS_KEY = "hl_coach_sessions";   // same key coach.js writes locally

function histRowText(when, mv, reps, sets, avg) {
  const d = new Date(when);
  const day = isNaN(d.getTime()) ? "" : d.toLocaleDateString("en-US", { month: "short", day: "numeric" }).toLowerCase();
  return day + "   ·   " + mv + "   ·   " + reps + " reps" +
    (sets > 0 ? " in " + sets + " sets" : "") +
    (avg != null && avg >= 0 ? "   ·   avg " + avg : "");
}

async function loadAccountHistory(user, holder) {
  let rows = [];
  if (sb && user) {
    const { data, error } = await sb.from("gg_coach_sessions")
      .select("move,reps,sets,avg_score,created_at")
      .order("created_at", { ascending: false }).limit(30);
    if (!error && data) rows = data.map((r) => [r.created_at, r.move, r.reps, r.sets, r.avg_score]);
  }
  if (!rows.length) {
    try {
      const list = JSON.parse(localStorage.getItem(SESS_KEY)) || [];
      rows = list.slice(-30).reverse().map((r) => [r.t || r.date, r.move, r.reps, r.sets, r.avg]);
    } catch (_) {}
  }
  holder.innerHTML = "";
  if (!rows.length) {
    const e = document.createElement("div");
    e.className = "empty";
    e.textContent = "no workouts yet — finish a session and it will appear here.";
    holder.appendChild(e);
    return;
  }
  rows.forEach((r) => {
    const div = document.createElement("div");
    div.className = "row";
    div.textContent = histRowText(r[0], r[1], r[2], r[3], r[4]);
    holder.appendChild(div);
  });
}

function wireAccount() {
  const page = $("accountPage");
  if (!page) return;
  const whoEl = $("acctWho"), histEl = $("acctHist"), msg = $("acctMsg");
  const outBtn = $("signOut"), delDataBtn = $("delData"), delAcctBtn = $("delAcct");
  let ready = false;

  onAuth(async (user) => {
    // no backend at all: cannot have a session — send to signin.
    if (!sb) { location.replace("signin.html"); return; }
    if (!user) {
      if (ready) location.replace("signin.html");   // signed out from here
      else location.replace("signin.html");         // no session on load
      return;
    }
    ready = true;
    page.hidden = false;
    if (whoEl) whoEl.innerHTML = "signed in as <b></b>";
    if (whoEl) whoEl.querySelector("b").textContent = user.email || "you";
    await loadAccountHistory(user, histEl);
  });

  if (outBtn) outBtn.addEventListener("click", async () => {
    outBtn.disabled = true;
    await sb.auth.signOut();
    location.replace("signin.html");
  });

  // delete every synced workout (rows only) — real supabase delete, confirm first.
  if (delDataBtn) delDataBtn.addEventListener("click", async () => {
    const u = currentUser();
    if (!u) return;
    if (!window.confirm("delete every workout synced to your account? this cannot be undone.")) return;
    delDataBtn.disabled = true;
    setMsg(msg, "deleting your synced workouts...");
    const { error } = await sb.from("gg_coach_sessions").delete().eq("user_id", u.id);
    delDataBtn.disabled = false;
    if (error) { setMsg(msg, "could not delete — try again.", true); return; }
    setMsg(msg, "your synced workouts are gone.");
    await loadAccountHistory(u, histEl);
    window.dispatchEvent(new Event("gg-sessions-changed"));
  });

  // delete the whole account — double confirm, security-definer rpc, then sign out.
  if (delAcctBtn) delAcctBtn.addEventListener("click", async () => {
    const u = currentUser();
    if (!u) return;
    if (!window.confirm("delete your WHOLE account and every synced workout? this cannot be undone.")) return;
    if (!window.confirm("last check: your account and its data will be gone for good. delete?")) return;
    delAcctBtn.disabled = true;
    setMsg(msg, "deleting your account...");
    const { error } = await sb.rpc("delete_me");
    if (error) { delAcctBtn.disabled = false; setMsg(msg, "could not delete — try again.", true); return; }
    await sb.auth.signOut();
    location.replace("signin.html");
  });
}

wireSignup();
wireSignin();
wireAccount();
