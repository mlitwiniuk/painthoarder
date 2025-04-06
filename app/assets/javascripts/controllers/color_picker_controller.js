import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "hexInput",
    "redInput",
    "greenInput",
    "blueInput",
    "hexField",
  ];

  connect() {
    this.updateHexField();
  }

  updateRgb() {
    const hex = this.hexInputTarget.value;
    const rgb = this.hexToRgb(hex);

    this.redInputTarget.value = rgb.r;
    this.greenInputTarget.value = rgb.g;
    this.blueInputTarget.value = rgb.b;
    this.updateHexField();
  }

  updateFromRgb() {
    const r = parseInt(this.redInputTarget.value || 0);
    const g = parseInt(this.greenInputTarget.value || 0);
    const b = parseInt(this.blueInputTarget.value || 0);

    const hex = this.rgbToHex(r, g, b);
    this.hexInputTarget.value = hex;
    this.updateHexField();
  }

  updateHexField() {
    this.hexFieldTarget.value = this.hexInputTarget.value;
  }

  hexToRgb(hex) {
    hex = hex.replace("#", "");

    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);

    return { r, g, b };
  }

  rgbToHex(r, g, b) {
    return (
      "#" +
      this.componentToHex(r) +
      this.componentToHex(g) +
      this.componentToHex(b)
    );
  }

  componentToHex(c) {
    const hex = Math.max(0, Math.min(255, c)).toString(16);
    return hex.length == 1 ? "0" + hex : hex;
  }
}
