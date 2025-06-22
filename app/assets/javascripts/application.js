// Entry point for the build script in your package.json
import { Turbo } from "@hotwired/turbo-rails";
import "./controllers";
import * as ActiveStorage from "@rails/activestorage";
import "@rails/actiontext";
import "trix";
ActiveStorage.start();

Turbo.StreamActions.redirect = function () {
  Turbo.visit(this.target);
};
