import { Controller } from "@hotwired/stimulus";

// Renders a Cloudflare Turnstile widget explicitly, so it works across Turbo
// visits (implicit rendering only scans the page once, on script load).
// The widget adds a hidden `cf-turnstile-response` input to this element.
const SCRIPT_URL = "https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit";
let scriptPromise;

function loadTurnstile() {
  if (window.turnstile) return Promise.resolve(window.turnstile);
  scriptPromise ||= new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = SCRIPT_URL;
    script.async = true;
    script.onload = () => resolve(window.turnstile);
    script.onerror = () => {
      scriptPromise = null;
      reject(new Error("Turnstile failed to load"));
    };
    document.head.appendChild(script);
  });
  return scriptPromise;
}

export default class extends Controller {
  static values = { siteKey: String, action: String };

  async connect() {
    try {
      const turnstile = await loadTurnstile();
      if (!this.element.isConnected || this.widgetId) return;
      this.widgetId = turnstile.render(this.element, {
        sitekey: this.siteKeyValue,
        action: this.actionValue || undefined,
        theme: "auto",
        size: "flexible",
      });
    } catch (error) {
      console.error(error);
      this.element.textContent = "Security check failed to load. Disable content blockers for this site and reload.";
    }
  }

  disconnect() {
    if (this.widgetId && window.turnstile) window.turnstile.remove(this.widgetId);
    this.widgetId = null;
  }
}
