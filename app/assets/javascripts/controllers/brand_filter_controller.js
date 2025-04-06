import { Controller } from "@hotwired/stimulus";
import TomSelect from "tom-select";
require("tom-select/dist/css/tom-select.min.css");

export default class extends Controller {
  static targets = ["brandSelect", "container"];
  static values = {
    url: String,
    sourceId: String,
    similarType: String,
    perPage: Number,
    selectedBrands: Array
  };

  connect() {
    this.initializeBrandSelect();
    
    // Initialize with previously selected brands if available
    if (this.hasSelectedBrandsValue && this.selectedBrandsValue.length > 0) {
      this.brandSelectTarget.value = this.selectedBrandsValue.join(',');
    }
  }

  disconnect() {
    if (this.tomSelect) {
      this.tomSelect.destroy();
    }
  }

  initializeBrandSelect() {
    // Destroy existing instance if it exists
    if (this.tomSelect) {
      this.tomSelect.destroy();
    }

    // Create new Tom-Select instance for brands
    this.tomSelect = new TomSelect(this.brandSelectTarget, {
      plugins: ['remove_button', 'clear_button'],
      placeholder: "Filter by brand",
      allowEmptyOption: true,
      render: {
        item: function(data, escape) {
          return '<div class="item">' + escape(data.text) + '</div>';
        },
        option: function(data, escape) {
          return '<div class="option">' + escape(data.text) + '</div>';
        }
      },
      onChange: (value) => {
        this.filterByBrands(value);
      }
    });
    
    // Add custom CSS for better display of multiple selections
    const style = document.createElement('style');
    style.textContent = `
      .ts-wrapper .ts-control {
        min-height: 3rem;
        padding: 0.5rem;
        overflow-y: auto;
        max-height: 150px;
      }
      .ts-wrapper .ts-control .item {
        margin: 2px;
        padding: 2px 6px;
        background: rgba(var(--p)/0.2);
        color: hsl(var(--pc));
        border-radius: 4px;
      }
      .ts-dropdown .option {
        padding: 8px 12px;
      }
      .ts-dropdown .active {
        background-color: rgba(var(--p)/0.2);
        color: hsl(var(--pc));
      }
    `;
    document.head.appendChild(style);
  }

  filterByBrands(brandIds) {
    // Store selected brands in value for persistence
    // Tom Select with multiple: true returns an array, not a string
    this.selectedBrandsValue = Array.isArray(brandIds) ? brandIds : 
                              (typeof brandIds === 'string' ? brandIds.split(',').filter(id => id !== '') : []);
    
    // Build URL with brand filter
    let url = this.urlValue;
    
    
    // Add query parameters
    const params = new URLSearchParams({
      similar_type: this.similarTypeValue,
      per_page: this.perPageValue,
      format: 'html'
    });
    
    // Add brand filter if brands are selected
    if (this.selectedBrandsValue.length > 0) {
      params.append('brand_ids', this.selectedBrandsValue.join(','));
    }
    
    // Complete URL
    url += `?${params.toString()}`;
    
    // Update the turbo frame
    const frameId = `similar-paints-frame-${this.similarTypeValue}`;
    const frame = document.getElementById(frameId);
    
    if (frame) {
      frame.src = url;
      frame.reload();
    }
  }
}
