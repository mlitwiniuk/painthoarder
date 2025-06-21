// Entry point for the build script in your package.json
import { Application } from '@hotwired/stimulus'
import controllers from './*_controller.js'
import RailsNestedForm from '@stimulus-components/rails-nested-form'


const application = Application.start()
application.register('rails-nested-form', RailsNestedForm)

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

controllers.forEach((controller) => {
  application.register(controller.name, controller.module.default)
})
