import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container", "primarySelector", "primarySelect", "input"];

  connect() {
    console.log("PhotoPreviewController connected");
  }

  handleFileChange(event) {
    console.log("File change event triggered");
    const files = event.target.files;

    if (files.length === 0) {
      this.hidePreview();
      return;
    }

    this.showPreview();
    this.clearPreviews();
    // this.updatePrimaryOptions(files);

    // Create preview for each file
    Array.from(files).forEach((file, index) => {
      if (file.type.startsWith("image/")) {
        this.createPreview(file, index);
      }
    });
  }

  createPreview(file, index) {
    const reader = new FileReader();

    reader.onload = (e) => {
      const previewDiv = document.createElement("div");
      previewDiv.className = "relative group";
      previewDiv.innerHTML = `
        <img src="${e.target.result}"
             class="w-full h-24 object-cover rounded-lg shadow-md"
             alt="Preview ${index + 1}">
        <div class="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors duration-200 rounded-lg"></div>
        <div class="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
          <div class="bg-black/70 text-white text-xs px-2 py-1 rounded-full">
            ${index + 1}
          </div>
        </div>
      `;

      this.containerTarget.appendChild(previewDiv);
    };

    reader.readAsDataURL(file);
  }

  updatePrimaryOptions(files) {
    // Clear existing options except the first "No primary photo"
    const select = this.primarySelectTarget;
    while (select.children.length > 1) {
      select.removeChild(select.lastChild);
    }

    // Add option for each file
    Array.from(files).forEach((file, index) => {
      if (file.type.startsWith("image/")) {
        const option = document.createElement("option");
        option.value = index;
        option.textContent = `Photo ${index + 1} - ${file.name}`;
        select.appendChild(option);
      }
    });

    // Show primary selector if there are multiple photos
    if (files.length > 1) {
      this.primarySelectorTarget.classList.remove("hidden");
    } else {
      this.primarySelectorTarget.classList.add("hidden");
    }
  }

  showPreview() {
    const previewArea = document.getElementById("photo-preview");
    if (previewArea) {
      previewArea.classList.remove("hidden");
    }
  }

  hidePreview() {
    const previewArea = document.getElementById("photo-preview");
    if (previewArea) {
      previewArea.classList.add("hidden");
    }
    this.primarySelectorTarget.classList.add("hidden");
  }

  clearPreviews() {
    this.containerTarget.innerHTML = "";
  }
}
