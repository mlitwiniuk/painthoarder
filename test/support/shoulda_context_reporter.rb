# shoulda-context 2.0.0 replaces Rails' failure reporter with an implementation
# that calls the old instance accessor. Rails 8 exposes it on the class instead.
# Keep failure reporting functional until Shoulda removes its obsolete patch.
class Rails::TestUnitReporter
  private

  def executable
    self.class.executable
  end
end
