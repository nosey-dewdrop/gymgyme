// reset.js — maildeki sıfırlama linki bu sayfaya düşer. linkteki recovery
// token'ı supabase kendisi oturuma çevirir; biz sadece yeni şifreyi kaydederiz.
const el = (id) => document.getElementById(id);
const msg = el("msg"), form = el("form"), pass = el("pass"), save = el("save"), back = el("back");
const show = (t) => { msg.textContent = t; };

const sb = (window.supabase && window.GG_CONFIG)
  ? window.supabase.createClient(window.GG_CONFIG.SUPABASE_URL, window.GG_CONFIG.SUPABASE_ANON_KEY)
  : null;

let ready = false;
function unlock() { ready = true; form.hidden = false; show("pick a new password."); }

if (!sb) {
  show("something went wrong loading the page - go back to the personal trainer and try again.");
} else {
  sb.auth.onAuthStateChange((_e, session) => { if (session && !ready) unlock(); });
  sb.auth.getSession().then(({ data }) => {
    if (data.session) { if (!ready) unlock(); return; }
    // token'ın işlenmesi bir an sürebilir; hâlâ oturum yoksa link geçersiz demektir.
    setTimeout(() => {
      if (!ready) show("this reset link is invalid or expired - request a fresh one from the personal trainer page.");
    }, 1500);
  });

  save.onclick = async () => {
    if (!pass.value || pass.value.length < 6) { show("password needs at least 6 characters."); return; }
    save.disabled = true;
    show("saving...");
    const { error } = await sb.auth.updateUser({ password: pass.value });
    save.disabled = false;
    if (error) { show("could not save: " + error.message); return; }
    form.hidden = true;
    back.hidden = false;
    show("done - your new password works now.");
  };
}
