import { Controller } from "@hotwired/stimulus";

// Stimulus controller to choose a cover image from existing attachments
export default class extends Controller {
  static targets = ["input", "gallery"];

  connect() {
    console.log("Cover picker connected");
  }

  pick(event) {
    const photoContainer = event.currentTarget;
    const chosenId = photoContainer.dataset.id;

    // update hidden field
    this.inputTarget.value = chosenId;

    // Update all photo containers to remove current selection
    this.galleryTarget.querySelectorAll("[data-id]").forEach((container) => {
      const img = container.querySelector("img");
      const badge = container.querySelector(".badge");
      const overlay = container.querySelector(".absolute.inset-0");

      // Remove selection styling
      if (img) {
        img.classList.remove("ring-2", "ring-primary");
      }

      // Remove current badge
      if (badge) {
        badge.remove();
      }

      // Update overlay text
      if (overlay) {
        const textDiv = overlay.querySelector("div");
        if (textDiv) {
          textDiv.textContent = "Set as Cover";
        }
      }
    });

    // Add selection styling to chosen container
    const chosenImg = photoContainer.querySelector("img");
    if (chosenImg) {
      chosenImg.classList.add("ring-2", "ring-primary");
    }

    // Add selected badge
    const badgeHtml = `
      <div class="absolute -top-2 -right-2">
        <div class="badge badge-primary badge-sm">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
        </div>
      </div>
    `;
    photoContainer.insertAdjacentHTML("beforeend", badgeHtml);

    // Update overlay text for selected item
    const chosenOverlay = photoContainer.querySelector(".absolute.inset-0");
    if (chosenOverlay) {
      const textDiv = chosenOverlay.querySelector("div");
      if (textDiv) {
        textDiv.textContent = "Current Cover";
      }
    }
  }

  clear(event) {
    event.preventDefault();

    // Clear the hidden field
    this.inputTarget.value = "";

    // Remove all selection styling and badges
    this.galleryTarget.querySelectorAll("[data-id]").forEach((container) => {
      const img = container.querySelector("img");
      const badge = container.querySelector(".badge");
      const overlay = container.querySelector(".absolute.inset-0");

      // Remove selection styling
      if (img) {
        img.classList.remove("ring-2", "ring-primary");
      }

      // Remove badge
      if (badge) {
        badge.remove();
      }

      // Update overlay text
      if (overlay) {
        const textDiv = overlay.querySelector("div");
        if (textDiv) {
          textDiv.textContent = "Set as Cover";
        }
      }
    });
  }
}
