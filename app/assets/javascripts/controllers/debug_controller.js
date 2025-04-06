import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="debug"
export default class extends Controller {
  static targets = ["frame"]

  connect() {
    console.log("Debug controller connected", this.element)
    document.addEventListener("turbo:frame-load", this.frameFetched)
    document.addEventListener("turbo:frame-render", this.frameRendered)
    document.addEventListener("turbo:before-fetch-request", this.beforeFetch)
    document.addEventListener("turbo:submit-end", this.submitEnd)
  }

  disconnect() {
    document.removeEventListener("turbo:frame-load", this.frameFetched)
    document.removeEventListener("turbo:frame-render", this.frameRendered)
    document.removeEventListener("turbo:before-fetch-request", this.beforeFetch)
    document.removeEventListener("turbo:submit-end", this.submitEnd)
  }

  frameFetched(event) {
    console.log("Frame fetched:", event.target.id, event)
  }

  frameRendered(event) {
    console.log("Frame rendered:", event.target.id, event)
  }

  beforeFetch(event) {
    console.log("Before fetch:", event.detail.url, event)
  }

  submitEnd(event) {
    console.log("Submit end:", event.detail.formSubmission.location.href, event)
  }
}
