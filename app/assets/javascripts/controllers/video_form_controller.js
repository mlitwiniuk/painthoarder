import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["urlInput", "preview", "thumbnail", "submitBtn"]

  parseUrl() {
    const url = this.urlInputTarget.value.trim()
    const videoId = this.extractVideoId(url)

    if (videoId) {
      this.thumbnailTarget.src = `https://img.youtube.com/vi/${videoId}/maxresdefault.jpg`
      this.thumbnailTarget.onerror = () => {
        this.thumbnailTarget.src = `https://img.youtube.com/vi/${videoId}/hqdefault.jpg`
      }
      this.previewTarget.classList.remove("hidden")
    } else {
      this.previewTarget.classList.add("hidden")
    }
  }

  extractVideoId(url) {
    if (!url) return null

    const patterns = [
      /(?:youtube\.com\/watch\?v=|youtube\.com\/watch\?.+&v=)([^&\s]+)/,
      /youtu\.be\/([^\?\s]+)/,
      /youtube\.com\/embed\/([^\?\s]+)/,
      /youtube\.com\/shorts\/([^\?\s]+)/,
      /youtube\.com\/v\/([^\?\s]+)/
    ]

    for (const pattern of patterns) {
      const match = url.match(pattern)
      if (match) return match[1]
    }

    return null
  }
}
