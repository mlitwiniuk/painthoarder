import { Controller } from "@hotwired/stimulus"
import * as d3 from "d3"

// Color wheel controller for visualizing paints on a color wheel
export default class extends Controller {
  static targets = ["wheel", "tooltip"]
  static values = {
    paints: Array
  }

  connect() {
    if (this.paintsValue.length === 0) return
    
    this.setupColorWheel()
  }

  setupColorWheel() {
    const container = this.wheelTarget
    const containerRect = container.getBoundingClientRect()
    const width = containerRect.width
    const height = containerRect.height
    const radius = Math.min(width, height) / 2 - 50 // Leave some margin
    const centerX = width / 2
    const centerY = height / 2

    // Create SVG
    const svg = d3.select(container)
      .append("svg")
      .attr("width", width)
      .attr("height", height)



    // Draw color wheel background
    this.drawColorWheelBackground(svg, centerX, centerY, radius)

    // Plot paints on the wheel
    this.plotPaints(svg, centerX, centerY, radius)
  }

  drawColorWheelBackground(svg, centerX, centerY, radius) {
    // Create a filled color wheel with pie segments
    const numSlices = 360
    const sliceAngle = 2 * Math.PI / numSlices
    
    // Generate pie slices to fill the wheel with color
    for (let i = 0; i < numSlices; i++) {
      const angle = i * sliceAngle
      const nextAngle = (i + 1) * sliceAngle
      const hue = i
      
      // Create a path for each slice
      const x1 = centerX + radius * Math.cos(angle)
      const y1 = centerY + radius * Math.sin(angle)
      const x2 = centerX + radius * Math.cos(nextAngle)
      const y2 = centerY + radius * Math.sin(nextAngle)
      
      // Define the arc path
      const path = [
        `M ${centerX} ${centerY}`,                       // Move to center
        `L ${x1} ${y1}`,                                 // Line to first point on circumference
        `A ${radius} ${radius} 0 0 1 ${x2} ${y2}`,      // Arc to next point
        'Z'                                              // Close path
      ].join(' ')
      
      // Add the colored slice
      svg.append("path")
        .attr("d", path)
        .attr("fill", `hsl(${hue}, 100%, 50%)`)
        .attr("opacity", 0.7)
    }

    // Add color wheel circles for guidance
    const guidanceRadii = [0.2, 0.4, 0.6, 0.8]
    guidanceRadii.forEach(factor => {
      svg.append("circle")
        .attr("cx", centerX)
        .attr("cy", centerY)
        .attr("r", radius * factor)
        .attr("fill", "none")
        .attr("stroke", "#ddd")
        .attr("stroke-width", 1)
        .attr("opacity", 0.5)
    })
  }

  plotPaints(svg, centerX, centerY, radius) {
    const tooltip = this.tooltipTarget
    const paints = this.paintsValue

    // Convert RGB from hex to HSL for plotting on the wheel
    const paintData = paints.map(paint => {
      const rgb = this.hexToRgb(paint.color)
      const hsl = this.rgbToHsl(rgb.r, rgb.g, rgb.b)
      
      // Calculate position on the wheel based on hue and saturation
      const angle = hsl.h * 2 * Math.PI / 360
      const distance = hsl.s * radius
      
      const x = centerX + distance * Math.cos(angle)
      const y = centerY + distance * Math.sin(angle)
      
      return {
        ...paint,
        x,
        y,
        hsl
      }
    })

    // Create paint dots on the wheel
    const dots = svg.selectAll(".paint-dot")
      .data(paintData)
      .enter()
      .append("circle")
      .attr("class", "paint-dot")
      .attr("cx", d => d.x)
      .attr("cy", d => d.y)
      .attr("r", 8)
      .attr("fill", d => d.color)
      .attr("stroke", d => {
        // Darker stroke for better visibility
        const rgb = this.hexToRgb(d.color)
        return `rgb(${Math.max(0, rgb.r - 50)}, ${Math.max(0, rgb.g - 50)}, ${Math.max(0, rgb.b - 50)})`
      })
      .attr("stroke-width", 1)
      .attr("opacity", 1)
      .style("cursor", "pointer")
      .attr("data-status", d => d.status)
      .style("filter", d => {
        if (d.status === "wishlist") return "drop-shadow(0 0 3px rgba(255, 165, 0, 0.5))"
        if (d.status === "avoid") return "drop-shadow(0 0 3px rgba(255, 0, 0, 0.5))"
        return "drop-shadow(0 0 2px rgba(0, 0, 0, 0.3))"
      })

    // Add interactivity
    dots.on("mouseover", (event, d) => {
      // Enlarge dot on hover
      d3.select(event.target)
        .transition()
        .duration(200)
        .attr("r", 12)
        .attr("opacity", 1)
      
      // Show tooltip
      tooltip.innerHTML = `
        <div class="font-semibold">${d.name}</div>
        <div class="text-sm text-gray-600">${d.brand} - ${d.product_line}</div>
        <div class="mt-2 flex items-center">
          <div class="w-6 h-6 rounded-full mr-2" style="background-color: ${d.color}"></div>
          <div class="text-sm">${d.color}</div>
        </div>
        <div class="mt-2">
          <span class="inline-flex px-2 py-1 text-xs font-semibold rounded-full ${this.getStatusClass(d.status)}">
            ${d.status.charAt(0).toUpperCase() + d.status.slice(1)}
          </span>
        </div>
        <div class="mt-2">
          <a href="${d.path}" class="text-sm text-blue-600 hover:underline">View details</a>
        </div>
      `
      tooltip.style.display = "block"
      // Show the tooltip first (but invisible) so we can measure it
      tooltip.style.display = "block"
      tooltip.style.visibility = "hidden"
      
      // Need to wait a moment for the tooltip to render before measuring
      setTimeout(() => {
        const tooltipRect = tooltip.getBoundingClientRect()
        
        // Calculate position to place tooltip directly above cursor
        let leftPos = event.pageX - (tooltipRect.width / 2)
        let topPos = event.pageY - tooltipRect.height - 15 // Position above with a 15px gap
        
        // Adjust if tooltip would go off-screen
        if (leftPos < 10) leftPos = 10
        if (leftPos + tooltipRect.width > window.innerWidth - 10) 
          leftPos = window.innerWidth - tooltipRect.width - 10
        if (topPos < 10) 
          topPos = event.pageY + 15 // Show below cursor if not enough space above
        
        // Apply the position and make visible
        tooltip.style.left = `${leftPos}px`
        tooltip.style.top = `${topPos}px`
        tooltip.style.visibility = "visible"
      }, 0)
    })
    
    dots.on("mouseout", (event) => {
      d3.select(event.target)
        .transition()
        .duration(200)
        .attr("r", 8)
        .attr("opacity", 1)
      
      tooltip.style.display = "none"
    })

    dots.on("click", (_, d) => {
      // Navigate to paint details page
      window.location.href = d.path
    })

  }


  hexToRgb(hex) {
    // Remove # if present
    hex = hex.replace(/^#/, '')
    
    // Parse hex
    const r = parseInt(hex.substring(0, 2), 16)
    const g = parseInt(hex.substring(2, 4), 16)
    const b = parseInt(hex.substring(4, 6), 16)
    
    return { r, g, b }
  }

  rgbToHsl(r, g, b) {
    // Convert RGB to [0, 1] range
    r /= 255
    g /= 255
    b /= 255
    
    const max = Math.max(r, g, b)
    const min = Math.min(r, g, b)
    let h, s, l = (max + min) / 2
    
    if (max === min) {
      // Achromatic (gray)
      h = s = 0
    } else {
      const d = max - min
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min)
      
      switch (max) {
        case r: h = (g - b) / d + (g < b ? 6 : 0); break
        case g: h = (b - r) / d + 2; break
        case b: h = (r - g) / d + 4; break
      }
      
      h /= 6
    }
    
    return {
      h: h * 360, // Convert to degrees
      s: s,
      l: l
    }
  }

  getStatusClass(status) {
    switch (status) {
      case 'owned':
        return 'bg-blue-100 text-blue-800'
      case 'wishlist':
        return 'bg-orange-100 text-orange-800'
      case 'avoid':
        return 'bg-red-100 text-red-800'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }
}
