namespace :paint_catalog do
  desc "Refresh and publish confident producer changes (DRY_RUN=1 saves a preview only)"
  task :fetch, [:source] => :environment do |_task, args|
    source = args.fetch(:source)
    abort "Choose monument or army_painter" unless PaintCatalog::Sources::CONFIG.key?(source)
    run = PaintCatalogRun.start!(source, auto_apply: ENV["DRY_RUN"] != "1")
    PaintCatalog::Sync.new(run).call
    puts "Batch #{run.id}: #{run.status}"
    puts "Review: /admin/paint_catalog_runs/#{run.id}"
    abort run.error_message if run.status == "failed"
    puts run.entries.group(:action).count.inspect
    puts "Publication: #{run.auto_apply? ? run.automation_status : "preview only"}"
    puts run.entries.group(:status).count.inspect
    abort run.automation_error if run.automation_status == "failed"
  rescue ActiveRecord::RecordNotUnique
    abort "A fetch for this producer is already queued or running"
  end
end
