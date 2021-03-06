class FileSetIndexer < Hyrax::FileSetIndexer
  include Hyrax::IndexesLinkedMetadata
  self.thumbnail_path_service = IIIFWorkThumbnailPathService

  def generate_solr_document
    # Convert ActiveTriples::Resource to Hyrax::ControlledVocabulary::[field name]
    # This is needed for Hyrax::DeepIndexingService
    object.attribute_names.each do |field|
      if object.controlled_properties.include?(field.to_sym) and object[field].present?
        object[field].each do |val|
          unless val.class == String
            to_controlled_vocab(field)
          end
        end
      end
    end

    super.tap do |solr_doc|
      solr_doc['hasFormat_ssim'] = object.rendering_ids
      if object.parent and object.parent.creator.present?
        parent_doc = SolrDocument.find(object.parent.id)
        solr_doc['creator_tesim'] = parent_doc['creator_tesim']
        solr_doc['creator_label_tesim'] = parent_doc['creator_label_tesim']
      end
    end
  end

  private
  # term is a symbol/controlled property
  # returns an array of Hyrax::ControlledVocabularies::[term]
  def to_controlled_vocab(field)
    if field.to_s == "based_near"
      class_name = "Hyrax::ControlledVocabularies::Location".constantize
    else
      class_name = "Hyrax::ControlledVocabularies::#{field.to_s.camelize}".constantize
    end
    object[field] =  object[field].map do |val|
    	val.include?("http") ? class_name.new(val) : val
    end
  end

end

