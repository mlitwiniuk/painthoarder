# Propshaft writes fingerprinted assets after jsbundling has finished. Refresh
# the precache manifest afterwards so a clean image includes the final assets.
Rake::Task["assets:precompile"].enhance do
  sh "corepack yarn build:service-worker"
end
