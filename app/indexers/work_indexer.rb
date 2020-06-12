class WorkIndexer < Hyrax::WorkIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  include Hyrax::IndexesLinkedMetadata

  # Use thumbnails served by RIIIF
  self.thumbnail_path_service = IIIFWorkThumbnailPathService

  # Uncomment this block if you want to add custom indexing behavior:
   def generate_solr_document
    super.tap do |solr_doc|
      solr_doc['title_sort_ssi'] = object.title.first unless object.title.empty?

      unless object.date_created.empty?
        solr_doc['year_sort_dtsim'] = []
        object.date_created.each do |solr_date|
          # modify date so that the interval encompasses the years on the last interval date
          temp_date = solr_date.gsub('/..','').gsub('%','?~').gsub(/\/$/,'')
          date = temp_date.include?("/") ? temp_date.gsub(/([0-9]+X+\/)([0-9]+)(X+)/){"#{$1}"+"#{$2.to_i+1}"+"#{$3}"}.gsub("X","u") : temp_date
          date = date.gsub("XX-","uu-").gsub("X-", "u-")
          if date[/\d{3}u/]# edtf can't parse single u in year (e.g. 192u), so we replace it
            date = date.gsub('u','0')
          end
          parsed_date = Date.edtf(date)#.first.gsub(/~|#/,'').gsub('X','0')) # Account for special characters; see https://github.com/UVicLibrary/Vault/issues/36
          # Returns formatted string with time set to midnight; e.g. Wed, 01 Jan 1913 => "1913-01-01T00:00:00Z"
          # https://lucene.apache.org/solr/guide/7_7/working-with-dates.html
          if ([EDTF::Interval, EDTF::Decade, EDTF::Century, EDTF::Season].include?(parsed_date.class))
            solr_doc['year_sort_dtsim'] += parsed_date.map{|d| d.strftime("%FT%TZ")}
            solr_doc['year_sort_dtsi'] = solr_doc['year_sort_dtsim'].first
          elsif date.class == Date
            solr_doc['year_sort_dtsim'] << parsed_date.strftime("%FT%TZ")
            solr_doc['year_sort_dtsi'] = solr_doc['year_sort_dtsim'].first
          elsif date == "unknown"
            # Do not index anything in year sort
          else # parsed_date == nil
            # Show an error message?
          end
        end
      end
    end
  end
end
