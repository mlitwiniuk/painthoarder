import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["toggle"];

  toggle() {
    // DaisyUI collapse component handles the animation automatically
    // This controller can be used for any additional logic if needed
  }
}
