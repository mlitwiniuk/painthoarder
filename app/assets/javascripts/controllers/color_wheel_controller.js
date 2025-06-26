import { Controller } from "@hotwired/stimulus";
import * as d3 from "d3";

// Color wheel controller for visualizing paints on a color wheel
export default class extends Controller {
  static targets = ["wheel", "tooltip"];
  static values = {
    paints: Array,
  };

  connect() {
    if (this.paintsValue.length === 0) return;

    this.setupColorWheel();
    this.setupResizeHandler();
  }

  disconnect() {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
    }
  }

  setupColorWheel() {
    const container = this.wheelTarget;
    const containerRect = container.getBoundingClientRect();
    const width = containerRect.width;
    const height = containerRect.height;
    // Adjust margin based on screen size
    const margin = width < 400 ? 30 : 50;
    const radius = Math.min(width, height) / 2 - margin;
    const centerX = width / 2;
    const centerY = height / 2;

    // Create SVG
    const svg = d3
      .select(container)
      .append("svg")
      .attr("width", width)
      .attr("height", height);

    // Draw color wheel background
    this.drawColorWheelBackground(svg, centerX, centerY, radius);

    // Plot paints on the wheel
    this.plotPaints(svg, centerX, centerY, radius);
  }

  drawColorWheelBackground(svg, centerX, centerY, radius) {
    // Create a filled color wheel with pie segments
    const numSlices = 360;
    const sliceAngle = (2 * Math.PI) / numSlices;

    // Generate pie slices to fill the wheel with color
    for (let i = 0; i < numSlices; i++) {
      const angle = i * sliceAngle;
      const nextAngle = (i + 1) * sliceAngle;
      const hue = i;

      // Create a path for each slice
      const x1 = centerX + radius * Math.cos(angle);
      const y1 = centerY + radius * Math.sin(angle);
      const x2 = centerX + radius * Math.cos(nextAngle);
      const y2 = centerY + radius * Math.sin(nextAngle);

      // Define the arc path
      const path = [
        `M ${centerX} ${centerY}`, // Move to center
        `L ${x1} ${y1}`, // Line to first point on circumference
        `A ${radius} ${radius} 0 0 1 ${x2} ${y2}`, // Arc to next point
        "Z", // Close path
      ].join(" ");

      // Add the colored slice
      svg
        .append("path")
        .attr("d", path)
        .attr("fill", `hsl(${hue}, 100%, 50%)`)
        .attr("opacity", 0.7);
    }

    // Add color wheel circles for guidance
    const guidanceRadii = [0.2, 0.4, 0.6, 0.8];
    guidanceRadii.forEach((factor) => {
      svg
        .append("circle")
        .attr("cx", centerX)
        .attr("cy", centerY)
        .attr("r", radius * factor)
        .attr("fill", "none")
        .attr("stroke", "#ddd")
        .attr("stroke-width", 1)
        .attr("opacity", 0.5);
    });
  }

  plotPaints(svg, centerX, centerY, radius) {
    const tooltip = this.tooltipTarget;
    const paints = this.paintsValue;

    // Use pre-calculated HSV values from server or convert RGB to HSV
    const paintData = paints.map((paint) => {
      let hsv;
      if (
        paint.hue !== undefined &&
        paint.saturation !== undefined &&
        paint.value !== undefined
      ) {
        // Use pre-calculated HSV values from server
        hsv = {
          h: paint.hue,
          s: paint.saturation / 100, // Convert from percentage to 0-1 range
          v: paint.value / 100,
        };
      } else {
        // Fallback to client-side conversion
        hsv = this.rgbToHsv(paint.red, paint.green, paint.blue);
      }

      // Calculate position on the wheel based on hue and saturation
      const angle = (hsv.h * 2 * Math.PI) / 360;
      const distance = hsv.s * radius;

      const x = centerX + distance * Math.cos(angle);
      const y = centerY + distance * Math.sin(angle);

      return {
        ...paint,
        x,
        y,
        hsv,
      };
    });

    // Create paint dots on the wheel
    const dots = svg
      .selectAll(".paint-dot")
      .data(paintData)
      .enter()
      .append("circle")
      .attr("class", "paint-dot")
      .attr("cx", (d) => d.x)
      .attr("cy", (d) => d.y)
      .attr("r", (d) => {
        // Vary dot size based on value/brightness and screen size
        const isMobile = window.innerWidth < 640;
        const baseSize = isMobile ? 4 : 6;
        const sizeVariation = isMobile ? 4 : 6;
        return baseSize + d.hsv.v * sizeVariation;
      })
      .attr("fill", (d) => d.hex_color)
      .attr("stroke", (d) => {
        // Darker stroke for better visibility
        return `rgb(${Math.max(0, d.red - 50)}, ${Math.max(0, d.green - 50)}, ${Math.max(0, d.blue - 50)})`;
      })
      .attr("stroke-width", (d) => {
        // Thicker stroke for darker colors to maintain visibility
        return d.hsv.v < 0.3 ? 2 : 1;
      })
      .attr("opacity", (d) => {
        // Vary opacity based on value (0.6-1.0 range) to show brightness
        return Math.max(0.6, 0.4 + d.hsv.v * 0.6);
      })
      .style("cursor", "pointer")
      .attr("data-status", (d) => d.status)
      .style("filter", (d) => {
        if (d.status === "wishlist")
          return "drop-shadow(0 0 3px rgba(255, 165, 0, 0.5))";
        if (d.status === "avoid")
          return "drop-shadow(0 0 3px rgba(255, 0, 0, 0.5))";
        return "drop-shadow(0 0 2px rgba(0, 0, 0, 0.3))";
      });

    // Add interactivity - support both mouse and touch events
    // Capture controller context for use in event handlers
    const controller = this;
    const wheelContainer = this.wheelTarget;

    const showTooltip = (event, d) => {
      // Enlarge dot on hover/touch
      const currentRadius = parseFloat(d3.select(event.target).attr("r"));
      const enlargement = window.innerWidth < 640 ? 2 : 4;
      d3.select(event.target)
        .transition()
        .duration(200)
        .attr("r", currentRadius + enlargement)
        .attr("opacity", 1);

      // Show tooltip with mobile-friendly content
      const isMobile = window.innerWidth < 640;
      tooltip.innerHTML = `
        <div class="font-semibold text-xs leading-tight">${d.name}</div>
        <div class="text-xs text-gray-600 leading-tight">${d.brand}</div>
        <div class="flex items-center mt-0.5">
          <div class="w-3 h-3 rounded-full mr-1.5" style="background-color: ${d.hex_color}"></div>
          <div class="text-xs">${d.hex_color}</div>
        </div>
        <div class="mt-0.5">
          <span class="inline-flex px-1 py-0.5 text-xs rounded ${controller.getStatusClass(d.status)}">
            ${d.status.charAt(0).toUpperCase() + d.status.slice(1)}
          </span>
        </div>
        <div class="mt-1"><a href="${d.path}" class="text-xs text-blue-600 hover:underline">${isMobile ? "Long press to view" : "Click to view"}</a></div>
      `;
      tooltip.style.display = "block";
      tooltip.style.visibility = "hidden";

      // Position tooltip very close to mouse/dot
      const tooltipRect = tooltip.getBoundingClientRect();

      let leftPos, topPos;

      if (isMobile) {
        // On mobile, position relative to the dot
        const containerRect = wheelContainer.getBoundingClientRect();
        const dotRect = event.target.getBoundingClientRect();
        const dotCenterX =
          dotRect.left - containerRect.left + dotRect.width / 2;
        const dotCenterY = dotRect.top - containerRect.top + dotRect.height / 2;

        leftPos = Math.max(
          5,
          Math.min(
            containerRect.width - tooltipRect.width - 5,
            dotCenterX - tooltipRect.width / 2,
          ),
        );
        topPos = dotCenterY - tooltipRect.height - 5;

        // If no space above, show below
        if (topPos < 5) {
          topPos = dotCenterY + 15;
        }
      } else {
        // Desktop positioning - relative to container, not page
        const containerRect = wheelContainer.getBoundingClientRect();
        const mouseX = event.pageX - containerRect.left;
        const mouseY = event.pageY - containerRect.top;

        leftPos = mouseX - tooltipRect.width / 2;
        topPos = mouseY - tooltipRect.height - 8;

        // Keep within container bounds
        if (leftPos < 5) leftPos = 5;
        if (leftPos + tooltipRect.width > containerRect.width - 5)
          leftPos = containerRect.width - tooltipRect.width - 5;
        if (topPos < 5) topPos = mouseY + 8;
      }

      tooltip.style.left = `${leftPos}px`;
      tooltip.style.top = `${topPos}px`;
      tooltip.style.visibility = "visible";
    };

    const hideTooltip = (event, d) => {
      const isMobile = window.innerWidth < 640;
      const baseSize = isMobile ? 4 : 6;
      const sizeVariation = isMobile ? 4 : 6;
      const originalRadius = baseSize + d.hsv.v * sizeVariation;
      const originalOpacity = Math.max(0.6, 0.4 + d.hsv.v * 0.6);

      d3.select(event.target)
        .transition()
        .duration(200)
        .attr("r", originalRadius)
        .attr("opacity", originalOpacity);

      tooltip.style.display = "none";
    };

    // Mouse events (desktop)
    dots.on("mouseover", showTooltip);
    dots.on("mouseout", hideTooltip);

    // Touch events (mobile) - use touchend for better interaction
    dots.on("touchend", (event, d) => {
      event.preventDefault();
      event.stopPropagation();

      // Check if this was a quick tap (tooltip) or longer touch (navigation)
      const touchDuration = Date.now() - (event.target._touchStart || 0);

      if (touchDuration < 300) {
        // Quick tap - show tooltip
        showTooltip(event, d);
        setTimeout(() => {
          hideTooltip(event, d);
        }, 3000);
      } else {
        // Longer touch - navigate to paint details
        window.location.href = d.path;
      }
    });

    // Track touch start time for duration calculation
    dots.on("touchstart", (event, d) => {
      event.preventDefault();
      event.stopPropagation();
      event.target._touchStart = Date.now();
    });

    // Prevent scrolling when touching the color wheel area
    d3.select(wheelContainer).on("touchstart", (event) => {
      event.preventDefault();
    });

    // Click events (desktop only)
    dots.on("click", (event, d) => {
      // Only handle clicks on desktop to avoid conflicts with touch events
      if (window.innerWidth >= 640) {
        window.location.href = d.path;
      }
    });
  }

  setupResizeHandler() {
    // Use ResizeObserver to detect container size changes
    if (window.ResizeObserver) {
      this.resizeObserver = new ResizeObserver(() => {
        this.redrawColorWheel();
      });
      this.resizeObserver.observe(this.wheelTarget);
    } else {
      // Fallback for older browsers
      window.addEventListener("resize", this.redrawColorWheel.bind(this));
      window.addEventListener(
        "orientationchange",
        this.redrawColorWheel.bind(this),
      );
    }
  }

  redrawColorWheel() {
    // Clear existing SVG
    const container = this.wheelTarget;
    const existingSvg = container.querySelector("svg");
    if (existingSvg) {
      existingSvg.remove();
    }

    // Redraw with new dimensions
    this.setupColorWheel();
  }

  rgbToHsv(r, g, b) {
    // Convert RGB to [0, 1] range
    r /= 255;
    g /= 255;
    b /= 255;

    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    const delta = max - min;

    let h,
      s,
      v = max;

    // Calculate saturation
    s = max === 0 ? 0 : delta / max;

    // Calculate hue
    if (delta === 0) {
      h = 0; // Achromatic (gray)
    } else {
      switch (max) {
        case r:
          h = ((g - b) / delta + (g < b ? 6 : 0)) / 6;
          break;
        case g:
          h = ((b - r) / delta + 2) / 6;
          break;
        case b:
          h = ((r - g) / delta + 4) / 6;
          break;
      }
    }

    return {
      h: h * 360, // Convert to degrees (0-360)
      s: s, // Saturation (0-1)
      v: v, // Value/Brightness (0-1)
    };
  }

  getStatusClass(status) {
    switch (status) {
      case "owned":
        return "bg-blue-100 text-blue-800";
      case "wishlist":
        return "bg-orange-100 text-orange-800";
      case "avoid":
        return "bg-red-100 text-red-800";
      default:
        return "bg-gray-100 text-gray-800";
    }
  }
}
