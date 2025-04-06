import { Controller } from "@hotwired/stimulus";
import TomSelect from "tom-select";
require("tom-select/dist/css/tom-select.min.css");

export default class extends Controller {
  static targets = ["brandSelect", "productLineSelect", "paintSelect"];
  static values = {
    brandId: Number,
    productLineId: Number,
    paintId: Number
  };

  connect() {
    // Store Tom-Select instances
    this.tomSelectInstances = {
      brand: null,
      productLine: null,
      paint: null,
    };

    // Store all data for client-side filtering
    this.paintsData = {
      brands: [],
      productLines: {},  // Indexed by brand_id
      paints: {}         // Indexed by product_line_id
    };

    // Load all data and initialize selects
    this.loadAllData().then(() => {
      this.initializeBrandSelect();
      
      // If we have initial values (editing mode), initialize the dropdowns
      if (this.hasBrandIdValue && this.brandIdValue) {
        // For edit mode, initialize the selects with the pre-selected values
        setTimeout(() => {
          if (this.tomSelectInstances.brand) {
            this.tomSelectInstances.brand.setValue(this.brandIdValue.toString());
            
            if (this.hasProductLineIdValue && this.productLineIdValue) {
              // Initialize product line select with the saved value
              this.initializeProductLineSelect(this.brandIdValue);
              setTimeout(() => {
                if (this.tomSelectInstances.productLine) {
                  this.tomSelectInstances.productLine.setValue(this.productLineIdValue.toString());
                  
                  if (this.hasPaintIdValue && this.paintIdValue) {
                    // Initialize paint select with the saved value
                    this.initializePaintSelect(this.productLineIdValue);
                    setTimeout(() => {
                      if (this.tomSelectInstances.paint) {
                        this.tomSelectInstances.paint.setValue(this.paintIdValue.toString());
                      }
                    }, 100);
                  }
                }
              }, 100);
            }
          }
        }, 100);
      } else {
        // For new records, start with disabled selects
        this.productLineSelectTarget.disabled = true;
        this.paintSelectTarget.disabled = true;
      }
    });
  }

  disconnect() {
    // Clean up Tom-Select instances
    Object.values(this.tomSelectInstances).forEach((instance) => {
      if (instance) instance.destroy();
    });
  }

  // Load all data upfront
  async loadAllData() {
    try {
      // Load all brands
      const brandsResponse = await fetch('/api/brands');
      this.paintsData.brands = await brandsResponse.json();

      // Load all product lines
      const productLinesResponse = await fetch('/api/product_lines');
      const allProductLines = await productLinesResponse.json();
      
      // Group product lines by brand_id
      allProductLines.forEach(productLine => {
        if (!this.paintsData.productLines[productLine.brand_id]) {
          this.paintsData.productLines[productLine.brand_id] = [];
        }
        this.paintsData.productLines[productLine.brand_id].push(productLine);
      });

      // Load all paints
      const paintsResponse = await fetch('/api/paints');
      const allPaints = await paintsResponse.json();
      
      // Group paints by product_line_id
      allPaints.forEach(paint => {
        if (!this.paintsData.paints[paint.product_line_id]) {
          this.paintsData.paints[paint.product_line_id] = [];
        }
        this.paintsData.paints[paint.product_line_id].push(paint);
      });
    } catch (error) {
      console.error('Error loading data:', error);
    }
  }

  initializeBrandSelect() {
    // Destroy existing instance if it exists
    if (this.tomSelectInstances.brand) {
      this.tomSelectInstances.brand.destroy();
    }

    // Create new Tom-Select instance for brands
    this.tomSelectInstances.brand = new TomSelect(this.brandSelectTarget, {
      valueField: "id",
      labelField: "text",
      searchField: "text",
      create: false,
      placeholder: "Select a brand",
      options: this.paintsData.brands,
      onChange: (value) => {
        if (value) {
          this.brandChanged();
        } else {
          // If brand is cleared, disable and clear the dependent selects
          this.resetProductLineSelect();
          this.resetPaintSelect();
        }
      },
    });
  }

  brandChanged() {
    const brandId = this.brandSelectTarget.value;

    if (!brandId) {
      this.resetProductLineSelect();
      this.resetPaintSelect();
      return;
    }

    // Initialize product line select
    this.initializeProductLineSelect(brandId);
  }

  initializeProductLineSelect(brandId) {
    // Reset the paint select since product line is changing
    this.resetPaintSelect();

    // Destroy existing instance if it exists
    if (this.tomSelectInstances.productLine) {
      this.tomSelectInstances.productLine.destroy();
    }

    // Enable the select
    this.productLineSelectTarget.disabled = false;

    // Get product lines for the selected brand
    const productLinesForBrand = this.paintsData.productLines[brandId] || [];

    // Create new Tom-Select instance for product lines
    this.tomSelectInstances.productLine = new TomSelect(
      this.productLineSelectTarget,
      {
        valueField: "id",
        labelField: "text",
        searchField: "text",
        create: false,
        placeholder: "Select a product line",
        options: productLinesForBrand,
        onChange: (value) => {
          if (value) {
            this.productLineChanged();
          } else {
            this.resetPaintSelect();
          }
        },
      },
    );
  }

  productLineChanged() {
    const productLineId = this.productLineSelectTarget.value;

    if (!productLineId) {
      this.resetPaintSelect();
      return;
    }

    // Initialize paint select
    this.initializePaintSelect(productLineId);
  }

  initializePaintSelect(productLineId) {
    // Destroy existing instance if it exists
    if (this.tomSelectInstances.paint) {
      this.tomSelectInstances.paint.destroy();
    }

    // Enable the select
    this.paintSelectTarget.disabled = false;

    // Get paints for the selected product line
    const paintsForProductLine = this.paintsData.paints[productLineId] || [];

    // Create new Tom-Select instance for paints
    this.tomSelectInstances.paint = new TomSelect(this.paintSelectTarget, {
      valueField: "id",
      labelField: "text",
      searchField: ["text"],
      create: false,
      placeholder: "Select a paint",
      options: paintsForProductLine,
      render: {
        option: function (data, escape) {
          return `<div class="!flex !flex-row items-center space-x-2">
                    <div class="w-4 h-4 rounded-full" style="background-color: ${escape(data.color)};"></div>
                    <div>${escape(data.text)}</div>
                  </div>`;
        },
        item: function (data, escape) {
          return `<div class="!flex !flex-row items-center space-x-2">
                    <div class="w-3 h-3 rounded-full" style="background-color: ${escape(data.color)};"></div>
                    <div>${escape(data.text)}</div>
                  </div>`;
        },
      },
      onChange: (value) => {
        if (value) {
          // Trigger the color preview update
          this.element.dispatchEvent(
            new CustomEvent("paint-selected", {
              detail: { paintId: value },
              bubbles: true,
            }),
          );
        }
      },
    });
  }

  resetProductLineSelect() {
    if (this.tomSelectInstances.productLine) {
      this.tomSelectInstances.productLine.destroy();
      this.tomSelectInstances.productLine = null;
    }

    this.productLineSelectTarget.disabled = true;
    this.productLineSelectTarget.innerHTML =
      '<option value="">Select a product line</option>';
  }

  resetPaintSelect() {
    if (this.tomSelectInstances.paint) {
      this.tomSelectInstances.paint.destroy();
      this.tomSelectInstances.paint = null;
    }

    this.paintSelectTarget.disabled = true;
    this.paintSelectTarget.innerHTML =
      '<option value="">Select a paint</option>';
  }
}
