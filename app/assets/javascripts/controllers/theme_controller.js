import { Controller } from "@hotwired/stimulus";

const THEMES = ["painthoarder", "painthoarder-light"];

export default class extends Controller {
  initialize() {
    this.apply();
  }

  apply() {
    document.documentElement.setAttribute("data-theme", this.theme);
  }

  switch(event) {
    this.theme = event.params.theme;
    this.apply();
  }

  toggle() {
    this.theme = this.theme === THEMES[0] ? THEMES[1] : THEMES[0];
    this.apply();
  }

  get theme() {
    let stored = null;
    try {
      stored = window.localStorage.getItem("theme");
    } catch (e) {}
    return THEMES.includes(stored) ? stored : THEMES[0];
  }

  set theme(value) {
    try {
      window.localStorage.setItem("theme", value);
    } catch (e) {}
  }
}
