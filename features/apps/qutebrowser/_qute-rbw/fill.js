// Fills a login form with values from qute-rbw.
//
// qute-rbw runs this through :jseval in qutebrowser's isolated "jseval"
// world. The page's own scripts share the DOM but not this code or its
// variables. __PAYLOAD__ is replaced with base64 of a JSON object:
//   { host, mode, name, username, password, totp }
// where mode is "login", "username", "password" or "totp". The return
// value is shown as a qutebrowser message, so it never includes a secret.
(() => {
  const bytes = Uint8Array.from(atob("__PAYLOAD__"), (c) => c.charCodeAt(0));
  const p = JSON.parse(new TextDecoder().decode(bytes));

  // :cmd-repeat-last could replay this command on another site later.
  // Only fill the site the entry was picked for.
  if (location.hostname !== p.host) {
    return `rbw: not filling, this page is ${location.hostname || "not a website"}, not ${p.host}`;
  }

  const TEXT_TYPES = ["text", "email", "tel", "url", "search", ""];

  const isInput = (el) => el && el.tagName === "INPUT";
  const isPassword = (el) => isInput(el) && el.type === "password";
  const isTextInput = (el) =>
    isInput(el) && TEXT_TYPES.includes((el.getAttribute("type") || "").toLowerCase());
  const isEditable = (el) =>
    el &&
    !el.disabled &&
    !el.readOnly &&
    (isPassword(el) || isTextInput(el) || el.tagName === "TEXTAREA" || el.isContentEditable);

  const isVisible = (el) => {
    if (el.disabled || el.readOnly) return false;
    const r = el.getBoundingClientRect();
    if (r.width === 0 || r.height === 0) return false;
    const s = el.ownerDocument.defaultView.getComputedStyle(el);
    return s.visibility !== "hidden" && s.display !== "none" && s.opacity !== "0";
  };

  // The focused element, looking inside open shadow roots
  const deepActive = (doc) => {
    let el = doc.activeElement;
    while (el && el.shadowRoot && el.shadowRoot.activeElement) {
      el = el.shadowRoot.activeElement;
    }
    return el;
  };

  // Every <input> under root, including those inside open shadow roots
  const allInputs = (root) => {
    const found = [];
    const walk = (node) => {
      for (const el of node.querySelectorAll("*")) {
        if (el.tagName === "INPUT") found.push(el);
        if (el.shadowRoot) walk(el.shadowRoot);
      }
    };
    walk(root);
    return found;
  };

  // Follow focus into same-origin frames. A cross-origin frame can't be
  // reached from here.
  let doc = document;
  let active = deepActive(doc);
  while (active && (active.tagName === "IFRAME" || active.tagName === "FRAME")) {
    let inner = null;
    try {
      inner = active.contentDocument;
    } catch (_) {
      inner = null;
    }
    if (!inner) {
      return "rbw: this login form is in a frame from another site. Use the copy bindings (,y...) instead.";
    }
    doc = inner;
    active = deepActive(doc);
  }
  if (active === doc.body || active === doc.documentElement) active = null;

  // Look for fields in the focused element's form, or in the whole page
  const scope = (active && (active.form || (active.closest && active.closest("form")))) || doc;
  const fields = allInputs(scope).filter(isVisible);
  const before = (a, b) => a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING;

  const findPassword = () => {
    if (isPassword(active)) return active;
    const passwords = fields.filter(isPassword);
    const current = passwords.filter((el) => el.autocomplete !== "new-password");
    const pool = current.length ? current : passwords;
    return (active && pool.find((el) => before(active, el))) || pool[0] || null;
  };

  // The username belongs with the password: the text field before it in
  // the same form. A focused field elsewhere, such as the site's search
  // box, is left alone.
  const findUsername = (passwordField) => {
    const form = (el) => el.form || null;
    const sameForm = (el) => !passwordField || form(el) === form(passwordField);
    if (isTextInput(active) && active !== passwordField && sameForm(active)) return active;
    const pool = passwordField
      ? allInputs(form(passwordField) || doc)
          .filter((el) => isVisible(el) && isTextInput(el) && before(el, passwordField))
      : fields.filter(isTextInput);
    const named =
      pool.find((el) => el.autocomplete === "username") || pool.find((el) => el.type === "email");
    if (named) return named;
    // With a password field, the closest one before it; without, the first
    return (passwordField ? pool[pool.length - 1] : pool[0]) || null;
  };

  const findOneTimeCode = () => {
    if (isEditable(active)) return active;
    return (
      fields.find((el) => el.autocomplete === "one-time-code") ||
      fields.find((el) => isTextInput(el) && /otp|totp|2fa|mfa|code|token/i.test(el.name + " " + el.id)) ||
      null
    );
  };

  // Typed through the editing machinery, as qutebrowser's :insert-text
  // does, so the page sees ordinary input events. A page that blocks that
  // gets its value set directly, plus the events frameworks listen for.
  const fill = (el, value) => {
    el.focus();
    if (el.select) el.select();
    const typed = el.ownerDocument.execCommand("insertText", false, value);
    if (el.isContentEditable || (typed && el.value === value)) return;
    const proto = el.tagName === "TEXTAREA" ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
    Object.getOwnPropertyDescriptor(proto, "value").set.call(el, value);
    el.dispatchEvent(new Event("input", { bubbles: true }));
    el.dispatchEvent(new Event("change", { bubbles: true }));
  };

  const filled = [];

  if (p.mode === "login") {
    const passwordField = findPassword();
    const usernameField = findUsername(passwordField);
    if (!passwordField && !usernameField) {
      return "rbw: found no login field on this page. Click into the username field and try again.";
    }
    if (usernameField && p.username) {
      fill(usernameField, p.username);
      filled.push("username");
    }
    if (passwordField && p.password) {
      fill(passwordField, p.password);
      filled.push("password");
    }
    if (!filled.length) return `rbw: ${p.name} has no username or password to fill`;
    if (!passwordField) {
      return `rbw: filled the username for ${p.name}. Run it again on the password step.`;
    }
    return `rbw: filled ${filled.join(" and ")} for ${p.name}`;
  }

  const target = {
    username: () => (isEditable(active) ? active : findUsername(findPassword())),
    password: () => (isEditable(active) ? active : findPassword()),
    totp: findOneTimeCode,
  }[p.mode]();
  const value = p[p.mode];

  if (!target) return `rbw: found no field for the ${p.mode}. Click into it and try again.`;
  if (!value) return `rbw: ${p.name} has no ${p.mode}`;
  fill(target, value);
  return `rbw: filled the ${p.mode === "totp" ? "TOTP code" : p.mode} for ${p.name}`;
})();
