import { Controller } from "@hotwired/stimulus"

/**
 * A simple and reliable image slider controller
 */
export default class extends Controller {
  static targets = ["slide", "indicator", "slidesContainer"]
  
  connect() {
    console.log("Simple slider connected")
    
    // Initialize
    this.currentIndex = 0
    this.slideCount = this.slideTargets.length
    
    if (this.slideCount === 0) {
      console.error("No slides found")
      return
    }
    
    console.log(`Found ${this.slideCount} slides`)
    
    // Set up auto-rotation
    this.startAutoRotation()
  }
  
  disconnect() {
    this.stopAutoRotation()
  }
  
  startAutoRotation() {
    this.autoRotateTimer = setInterval(() => {
      this.next()
    }, 5000)
  }
  
  stopAutoRotation() {
    if (this.autoRotateTimer) {
      clearInterval(this.autoRotateTimer)
      this.autoRotateTimer = null
    }
  }
  
  next() {
    const nextIndex = (this.currentIndex + 1) % this.slideCount
    this.showSlide(nextIndex)
  }
  
  previous() {
    const prevIndex = (this.currentIndex - 1 + this.slideCount) % this.slideCount
    this.showSlide(prevIndex)
  }
  
  goToSlide(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10)
    this.showSlide(index)
    
    // Reset the timer
    this.stopAutoRotation()
    this.startAutoRotation()
  }
  
  showSlide(index) {
    // Hide all slides
    this.slideTargets.forEach((slide, i) => {
      if (i === index) {
        slide.classList.remove('hidden')
      } else {
        slide.classList.add('hidden')
      }
    })
    
    // Update indicators
    this.indicatorTargets.forEach((indicator, i) => {
      if (i === index) {
        indicator.classList.add('bg-white/70')
        indicator.classList.remove('bg-white/40')
      } else {
        indicator.classList.remove('bg-white/70')
        indicator.classList.add('bg-white/40')
      }
    })
    
    // Update current index
    this.currentIndex = index
  }
}
