import { Controller } from "@hotwired/stimulus";
import TomSelect from "tom-select";
require("tom-select/dist/css/tom-select.min.css");

export default class extends Controller {
  static targets = ["brandSelect", "productLineSelect", "paintSelect"];

  connect() {
    // Store Tom-Select instances
    this.tomSelectInstances = {
      brand: null,
      productLine: null,
      paint: null,
    };

    // Initialize brand select with Tom-Select
    this.initializeBrandSelect();

    // Initialize the other selects, but they'll start disabled
    this.productLineSelectTarget.disabled = true;
    this.paintSelectTarget.disabled = true;
  }

  disconnect() {
    // Clean up Tom-Select instances
    Object.values(this.tomSelectInstances).forEach((instance) => {
      if (instance) instance.destroy();
    });
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
      load: (query, callback) => {
        const url = `/api/brands?query=${encodeURIComponent(query)}`;

        fetch(url)
          .then((response) => response.json())
          .then((json) => {
            callback(json);
          })
          .catch(() => {
            callback();
          });
      },
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

    // Create new Tom-Select instance for product lines
    this.tomSelectInstances.productLine = new TomSelect(
      this.productLineSelectTarget,
      {
        valueField: "id",
        labelField: "text",
        searchField: "text",
        create: false,
        placeholder: "Select a product line",
        load: (query, callback) => {
          const url = `/api/product_lines?brand_id=${brandId}&query=${encodeURIComponent(query)}`;

          fetch(url)
            .then((response) => response.json())
            .then((json) => {
              callback(json);
            })
            .catch(() => {
              callback();
            });
        },
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

    // Create new Tom-Select instance for paints
    this.tomSelectInstances.paint = new TomSelect(this.paintSelectTarget, {
      valueField: "id",
      labelField: "text",
      searchField: ["text"],
      create: false,
      placeholder: "Select a paint",
      render: {
        option: function (data, escape) {
          return `<div class="flex items-center space-x-2">
                    <div class="w-4 h-4 rounded-full" style="background-color: ${escape(data.color)};"></div>
                    <div>${escape(data.text)}</div>
                  </div>`;
        },
        item: function (data, escape) {
          return `<div class="flex items-center space-x-2">
                    <div class="w-3 h-3 rounded-full" style="background-color: ${escape(data.color)};"></div>
                    <div>${escape(data.text)}</div>
                  </div>`;
        },
      },
      load: (query, callback) => {
        const url = `/api/paints?product_line_id=${productLineId}&query=${encodeURIComponent(query)}`;

        fetch(url)
          .then((response) => response.json())
          .then((json) => {
            callback(json);
          })
          .catch(() => {
            callback();
          });
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
