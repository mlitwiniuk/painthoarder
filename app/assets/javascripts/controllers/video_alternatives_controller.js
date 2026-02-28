import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["brandSelect"]
  static values = { videoPath: String }

  selectBrand() {
    const brandSlug = this.brandSelectTarget.value

    if (brandSlug) {
      Turbo.visit(`${this.videoPathValue}/alternatives/${brandSlug}`)
    } else {
      Turbo.visit(this.videoPathValue)
    }
  }
}
