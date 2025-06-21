import { Controller } from "@hotwired/stimulus"

// Stimulus controller to choose a cover image from existing attachments
export default class extends Controller {
  static targets = ["input", "gallery"]

  connect(){
    console.log("Cover picker connected")
  }

  pick(event) {
    const img = event.currentTarget
    const chosenId = img.dataset.id

    // update hidden field
    this.inputTarget.value = chosenId
    console.log("Cover picker picked", chosenId)

    // highlight selection visually
    this.galleryTarget.querySelectorAll("img").forEach(el => {
      el.classList.remove("ring-2", "ring-primary")
    })
    img.classList.add("ring-2", "ring-primary")
  }
}
