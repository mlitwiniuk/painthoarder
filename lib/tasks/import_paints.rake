namespace :paints do
  desc "Import all markdown paint files to the database"
  task :import_to_db => :environment do
    require_relative '../../app/services/markdown_color_parser'

    paints_dir = Rails.root.join('db', 'miniature-paints', 'paints')
    markdown_files = Dir["#{paints_dir}/**/*.md"]

    puts "Found #{markdown_files.size} markdown files to process and import to database"

    markdown_files.each do |file_path|
      begin
        content = File.read(file_path)
        parser = MarkdownColorParser.new(content)
        result = parser.parse

        # Find or create the brand
        brand = Brand.find_or_initialize_by(name: result[:brand][:name])

        # Handle the logo file
        if result[:brand][:logo_path].present?
          # Get the absolute path to the logo file
          # The logo path in markdown might be relative (e.g., "../logos/Brand.png")
          base_dir = File.dirname(file_path)
          logo_path = File.expand_path(result[:brand][:logo_path], base_dir)

          if File.exist?(logo_path)
            # Attach the logo file to the brand using Active Storage
            logo_file = File.open(logo_path)
            brand.logo.attach(
              io: logo_file,
              filename: File.basename(logo_path),
              content_type: Marcel::MimeType.for(logo_file)
            )
            logo_file.close
            puts "  ✓ Attached logo: #{logo_path}"
          else
            puts "  ✗ Logo file not found: #{logo_path}"
          end
        end

        if brand.save
          # Create the colors associated with this brand
          result[:colors].each do |color_data|
            product_line = brand.product_lines.find_or_create_by(name: color_data[:set])
            paint = product_line.paints.find_or_initialize_by(code: color_data[:code])
            paint.assign_attributes(
              name: color_data[:name],
              red: color_data[:r],
              green: color_data[:g],
              blue: color_data[:b],
              hex_color: color_data[:hex]
            )

            if paint.save
              print "."
            else
              puts "\n✗ Failed to save color #{color_data[:name]}: #{paint.errors.full_messages.join(', ')}"
            end
          end

          puts "\n✓ Imported #{result[:colors].size} colors for #{brand.name}"
        else
          puts "✗ Failed to save brand #{result[:brand][:name]}: #{brand.errors.full_messages.join(', ')}"
        end
      rescue => e
        puts "✗ Error processing #{file_path}: #{e.message}"
      end
    end

    puts "\nImport complete! Database now contains #{Brand.count} brands and #{Paint.count} colors."
  end
end
