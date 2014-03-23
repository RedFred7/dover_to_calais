require "dover_to_calais/version"   #gem lib file
require "dover_to_calais/ontology"  #gem lib file
require 'open-uri'  # in std library
require 'nokogiri'
require 'eventmachine'
require 'em-http-request'
require 'yomu'
require 'json'
require "dover_to_calais/models"  #gem lib file
require 'daybreak'
require 'ohm'


module DoverToCalais


  PROXY = nil
  REDIS = "redis://127.0.0.1:6379/6"

  def self.flushdb
    Ohm.redis = Redic.new(REDIS)
    Ohm.redis.call "FLUSHDB"
  end


  # The ResponseItem structure holds all potential text and attribute values of an OpenCalais
  # XML Simple format element.
  class ResponseItem < Struct.new(:name, :value, :relevance, :count, :normalized, :importance, :originalValue)
    #
    # @!attribute [r] name
    #   @return [String] the element's name.
    #
    #
    # @!attribute [r] value
    #   @return [String] the element's text value.
    #
    #
    # @!attribute [r] relevance
    #   The importance of the element in the context of the given input, in the range 0-1
    #   (1 being the most relevant and important). The score has 3-digit precision after the decimal point.
    #   @return [Float] the element's relevance, in the range 0-1.
    #
    #
    # @!attribute [r] count
    #   @return [Integer]  the count (frequency) of the element in the given input.
    #
    #
    # @!attribute [r] normalized
    #   If the element is one of: (Company, City, ProvinceOrState, Country) OpenCalais
    #   provides disambiguation of its value in the 'normalized' attribute. For instance, the element
    #   <City>Birmingham</City> may include the attribute normalized = "Birmingham, UK" in order to avoid
    #   confusion with the city of Birmingham, USA.
    #   @return [String] the element text's disambiguated value
    #
    #
    # @!attribute [r] importance
    #   Only applicable to the SocialTag element.
    #   @return [1, 2] the importance of the SocialTag.
    #
    #
    # @!attribute [r] originalValue
    #   Only applicable to the SocialTag element.
    #   @return [String] The original value of the SocialTag.
    #
  end


  # This class is responsible for creating a response object that will be passed to {Dover}, after
  # the data source has been analysed by OpenCalais. If the response contains valid data, the
  # {#error} attribute will be nil. The response object will then contain the OpenCalais response
  # as an XML string. The user can then call {#filter} to filter the response.
  # If the response doesn't contain valid, processed data then the {#error} won't be nil (i.e. will
  # be true). The {#error} attribute can then be read in order to find the cause of the error.
  #
  # @!attribute [r] error
  #   @return [String, nil] any error that occurred as a result of the OpenCalais API call,
  #     nil if none occurred
  #
  class ResponseData



    class Entity< Struct.new(:type, :name, :ref)

      def to_hash
        a_hash = {}
        self.each_pair do |attr, value|
          a_hash[attr] =  value 
        end
        a_hash
      end

    end

    class GenericRelation< Struct.new(:subject, :verb, :object, :detection)

    end

    class Event

      attr_reader :entities

      def initialize(events_hash)
        # @entities = entity_hash
        events_hash.each do |k,v|
          unless k.eql?('_typeGroup') || k.eql?('instances') || k.eql?('_typeReference')
            k = 'type' if k.eql?('_type') #don't like the underscore
            ## create and initialize an instance variable for this key/value pair
            self.instance_variable_set("@#{k}", v)
            ## create the getter that returns the instance variable
            self.class.send(:define_method, k, proc{self.instance_variable_get("@#{k}")})
            ## create the setter that sets the instance variable
            self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})
          end
        end #block
      end #method

      def each_pair
        self.instance_variables.each do |a|
          # dereference(v["relationsubject"]) {|r| gr['subject']  =  r}
          yield a, self.instance_variable_get(a)
        end
      end

      def [](attrib_name)
        self.instance_variables.each do |a|
          if "@#{a}" == attrib_name
            self.instance_variable_get(a)
          end
        end
      end


      def dereference(ref_key, response_data)
        found = Entity.new(nil, nil, nil)
        entities_store = Daybreak::DB.new "entities.db"

        entities_store.keys.each do |entity_type|
          response_data.entities[entity_type].each_pair do |key, value|
            if key == ref_key
              found[:type] = value["_type"]
              found[:name] = value["name"]
              found[:ref] = ref_key
            end
          end
        end
        found
      end

      public :each_pair
      private :dereference

    end #class




    attr_reader :error, :entities_store, :events_store, :generic_relations_store, :freds
    # creates a new ResponseData object, passing the name of the data source to be processed
    #
    # @param response_data [ Nokogiri::XML::NodeSet, Hash, nil] the XML or JSON data returned by OpenCalais
    # @param error [ String, nil] an error description if the OpenCalais call has failed
    def initialize(response_data = nil, error = nil)
      if response_data.class.to_s == "Nokogiri::XML::Document"
        @xml_data = response_data
      elsif response_data.class.to_s == "Hash"
        @json_data = response_data
        prepare_data(response_data)


      else
        @error = error
      end

    end

    # Returns  the response data as an XML string or an error, if one has occurred.
    #
    # @return [String] an XML string
    def to_s
      if @xml_data
        @xml_data.to_s
      elsif @json_data
        @json_data.to_s
      else
        @error
      end
    end


   

    # The method will first create three Hash instance variables, where it will store the 
    # Entities, Generic Relations and Events -respectively- from the OpenCalais response. 
    # The key on each Hash instance variable will be the OpenCalais ID and the value will
    # be the values_hash for that ID.
    # Secondly, the method will iterate through each Entity, find all of it's related
    # Relations and Events and store them -in a relational manner- in Redis, via Ohm.
    #
    # Only applicable with the JSON (rich) output format
    #
    # @param Hash the OpenCalais JSON response, as a Hash
    # @return an GenericRelation Struct if a match is found, nil otherwise

    def prepare_data(results_hash)

      @entities_store = {}
      @generic_relations_store = {}
      @events_store = {}
      # find all Entities in response
      @entities_store = results_hash.select{|key, hash| hash["_typeGroup"] == "entities"}
      # find all GenericRelations in response
      @generic_relations_store = results_hash.select{|key, hash| hash["_typeGroup"] == "relations" &&
      hash["_type"] == "GenericRelations"}
      # find all Events in response
      @events_store = results_hash.select{|key, hash| hash["_typeGroup"] == "relations" &&
      hash["_type"] != "GenericRelations"}

      Ohm.redis = Redic.new(REDIS)


      #for each Entity find all related Relations and Events and store them to Ohm/Redis
      @entities_store.each_pair do |k, v|
        entity = EntityModel.create(:name => v['name'], :type => v['_type'], :calais_id => k)
        if entity.save
          #get all referenced relations
          find_in_relations(k).each do |obj|

            found_rel = get_relation(obj[0])
            if found_rel

              found_rel.subject = convert_to_hash(found_rel.subject)
              found_rel.object = convert_to_hash(found_rel.object)

              relation = EntityModel::RelationModel.create(:subject => found_rel.subject, 
                                            :object => found_rel.object, 
                                            :verb => found_rel.verb,
                                            :detection => found_rel.detection,
                                             :calais_id => obj[0])
              entity.relations.add(relation)
            end #if
          end #each
          #get all referenced events
          find_in_events(k).each do |obj|
            found_event = get_event(obj[0])
            attribs = {}
            if found_event

              found_event.each_pair do |key, val|
                
                key = key.to_s.slice(1, key.length-1)
                attribs[key] = val

              end #block

              event = EntityModel::EventModel.create(:calais_id => obj[0], :info_hash => attribs)
              entity.events.add(event)

            end #if

          end #each

          
        end #if save

      end #each_pair

    end #method

    # Coverts an attribute to an appropriate Hash
    #
    # Only applicable with the JSON (rich) output format
    #
    # @param [String, DoverToCalais::ResponseData::Entity, Hash] an object
    # @return a Hash value
    def convert_to_hash(an_attribute)
      h = {}
      if an_attribute.class.to_s.eql?('String')
        h[:name] = an_attribute
      end

      if an_attribute.class.to_s.eql?('DoverToCalais::ResponseData::Entity')
        h = an_attribute.to_hash
      end   

      if an_attribute.class.to_s.eql?('Hash')
        h = an_attribute
      end

      h
    end #method



    # Retrieves the entity with the specified key (OpenCalais ID)
    #
    # Only applicable with the JSON (rich) output format
    #
    # @param String the OpenCalais ID
    # @return an Entity Struct if a match is found, nil otherwise
    def get_entity(ref_key)
      if @entities_store.has_key?(ref_key)
        Entity.new(@entities_store[ref_key]['_type'],  @entities_store[ref_key]['name'], ref_key)
      else
        nil
      end
    end


    # Retrieves the relation with the specified key (OpenCalais ID). The method will also
    # de-reference any of its attributes that refer to other entities via an OpenCalais ID
    # and will replace the references with the appropriate Entity structure, if applicable
    #
    # Only applicable with the JSON (rich) output format
    #
    # @param String the OpenCalais ID
    # @return an GenericRelation Struct if a match is found, nil otherwise
    def get_relation(ref_key)
      if @generic_relations_store.key?(ref_key)

        if @generic_relations_store[ref_key]['relationsubject']
          gr_subject = @generic_relations_store[ref_key]['relationsubject'].match('^http://d.opencalais.com') ?
                      get_entity(@generic_relations_store[ref_key]['relationsubject']) :
                      @generic_relations_store[ref_key]['relationsubject']
        else
          gr_subject = 'N/A'
        end
        

        if @generic_relations_store[ref_key]['relationobject']
          gr_object = @generic_relations_store[ref_key]['relationobject'].match('^http://d.opencalais.com') ?
                      get_entity(@generic_relations_store[ref_key]['relationobject']) :
                      @generic_relations_store[ref_key]['relationobject']
        else
          gr_object = 'N/A'
        end

        GenericRelation.new(gr_subject,  
                            @generic_relations_store[ref_key]['verb'], 
                            gr_object,
                            @generic_relations_store[ref_key]['instances'][0]['exact'] ||= 'N/A')
      else
        nil
      end
    end

    def get_event(ref_key)

      dereferenced_events = {}

      if @events_store.key?(ref_key)

        @events_store[ref_key].each do |k, v|

          if v.class.to_s.eql?("String") && v.match('^http://d.opencalais.com')
            dereferenced_events[k] = get_entity(v).to_hash
          elsif v.class.to_s.eql?("String") && !v.match('^http://d.opencalais.com')
            h = {}
            h['name'] = v
            dereferenced_events[k] = h
          elsif v.class.to_s.eql?("Array")
            h = {}
            h['name'] = v[0]['exact']
            dereferenced_events[k] = h
          end
        end

        Event.new(dereferenced_events)
      else
        nil
      end
    end


    # Selects a Hash of generic relations, where the relations' subject or object attributes
    # match the specified OpenCalais ID.
    #
    # Only applicable with the JSON (rich) output format
    #
    # @param String the OpenCalais ID
    # @return a Hash with the selected matches
    def find_in_relations(ref_key)
      @generic_relations_store.select{|key, hash| (hash["relationsubject"] == ref_key) || 
                                                (hash["relationobject"] == ref_key) }

    end

    # Selects a Hash of events, where the events' key matches the 
    # specified OpenCalais ID.
    #
    # Only applicable with the JSON (rich) output format
    #
    # @param String the OpenCalais ID
    # @return a Hash with the selected matches
    def find_in_events(ref_key)
      @events_store.select{|key, hash| hash.has_value?(ref_key) }
    end



    # Filters the xml response object to extract relevant data.
    #
    # @param params [Hash] a filter Hash (see code samples)
    # @return [Array[ResponseItem]] a list of relevant response items
    def filter(params)
      unless  @xml_data
        return 'ERR: filter method only works with xml-based output!'

      end

      result = Array.new
      begin
        if @xml_data

          if params[:given]
            found = @xml_data.xpath("//#{params[:given][:entity]}[contains(text(), #{params[:given][:value].inspect})]")
            if found.size > 0
              @xml_data.xpath("//#{params[:entity]}[contains(text(), #{params[:value].inspect})]").each do |node|
                result <<  create_response_item(node)
              end
            end
          else  # no conditional
            @xml_data.xpath("//#{params[:entity]}[contains(text(), #{params[:value].inspect})]").each do |node|
              result <<  create_response_item(node)
            end
          end

          return result
        else # no xml data
          return 'ERR: no valid xml data!'

        end #if

      rescue  Exception=>e
        return "ERR: #filter:  #{e}"

      end

      return result

    end  #method

    # Creates a Response Item from an xml node.
    #
    # @param node [Nokogiri::XML::Node] an XML node
    # @return [ResponseItem] a response item object
    def create_response_item(node)
      node_relevance =  node.attribute('relevance').text.to_f if node.has_attribute?('relevance')
      node_count =  node.attribute('count').text.to_i if node.has_attribute?('count')
      node_normalized =  node.attribute('normalized').text if node.has_attribute?('normalized')
      node_importance = node.attribute('importance').text.to_i if node.has_attribute?('importance')
      node_orig_value =  node.xpath('originalValue').text if node.name.eql?('SocialTag')

      ResponseItem.new(node.name,
      node.text,
      node_relevance,
      node_count,
      node_normalized,
      node_importance,
      node_orig_value )

    end

    public :filter
    private :create_response_item, :prepare_data, :convert_to_hash, :find_in_relations, :find_in_events

  end #class


  #====================================================================================

  # This class is responsible for parsing, reading and sending to OpenCalais, text from a data source.
  # The data source is passed to the class constructor and can be pretty much any form of document or URL.
  # The class allows the user to specify one or more callbacks, to be called when the data source has been
  # processed by OpenCalais ({#to_calais}).
  #
  # @!attribute [r] data_src
  #   @return [String] the data source to be processed, either a file path or a URL.
  #
  # @!attribute [r] error
  #   @return [String, nil] any error that occurred during data-source processing, nil if none occurred
  #
  class Dover

    CALAIS_SERVICE = 'https://api.opencalais.com/tag/rs/enrich'

    attr_reader :data_src, :error

    # creates a new Dover object, passing the name of the data source to be processed
    #
    # @param data_src [String] the name of the data source to be processed
    def initialize(data_src)
      @data_src = data_src
      @callbacks = []
    end


    # uses the {https://github.com/Erol/yomu yomu} gem to extract text from a number of document formats and URLs.
    # If an exception occurs, it is written to the {@error} instance variable
    #
    # @param [String] src the name of the data source (file-path or URI)
    # @return [String, nil] the extracted text, or nil if an exception occurred.
    def get_src_data(src)
      begin
        yomu = Yomu.new src

      rescue Exception=>e
        @error = "ERR: #{e}"
      else
        yomu.text
      end

    end

    # Defines the user callbacks. If the data source is successfully read, then this method will store a
    # user-defined block which will be called on completion of the OpenCalais HTTP request. If the data source
    # cannot be read -for whatever reason- then the block will immediately be called, passing the parameter that
    # caused the read failure.
    #
    # @param block a user-defined block
    # @return N/A
    def to_calais(&block)
      #fred rules ok
      if !@error
        @callbacks << block
      else
        result = ResponseData.new nil, @error
        block.call(result)
      end

    end #method





    # Gets the source text parsed. If the parsing is successful, the data source is POSTed to OpenCalais
    # via an EventMachine request and a callback is set to manage the OpenCalais response.
    # All Dover object callbacks are then called with the request result yielded to them.
    #
    # @param N/A
    # @return a {Class ResponseData} object
    def analyse_this(output_format=nil)

      if output_format
        @output_format = 'application/json'
      else
        @output_format = 'Text/Simple'
      end

      @document = get_src_data(@data_src)
      begin
        if @document[0..2].eql?('ERR')
          raise 'Invalid data source'
        else
          response = nil

          connection_options = {:inactivity_timeout => 0}


          if DoverToCalais::PROXY &&
            DoverToCalais::PROXY.class.eql?('Hash') &&
            DoverToCalais::PROXY.keys[0].eql?(:proxy)

            connection_options = connection_options.merge(DoverToCalais::PROXY)
          end

          request_options = {
            :body => @document.to_s,
            :head => {
              'x-calais-licenseID' => DoverToCalais::API_KEY,
              :content_type => 'TEXT/RAW',
              :enableMetadataType => 'GenericRelations,SocialTags',
            :outputFormat => @output_format}
          }

          http = EventMachine::HttpRequest.new(CALAIS_SERVICE, connection_options ).post request_options


          http.callback do

            if http.response_header.status == 200
              if @output_format == 'Text/Simple'
                http.response.match(/<OpenCalaisSimple>/) do |m|
                  response = Nokogiri::XML('<OpenCalaisSimple>' + m.post_match)  do |config|
                    #strict xml parsing, disallow network connections
                    config.strict.nonet
                  end #block
                end
              else #@output_format == 'application/json'
                response = JSON.parse(http.response) #response should now be a Hash

              end #if

              case response.class.to_s
              when 'NilClass'
                result = ResponseData.new(nil,'ERR: cannot parse response data - source invalid?')
              when 'Nokogiri::XML::Document'
                result = ResponseData.new(response, nil)
              when 'Hash'
                result = ResponseData.new(response, nil)
              else
                result = ResponseData.new(nil,'ERR: cannot parse response data - unrecognized format!')
              end


            else #non-200 response
              result = ResponseData.new nil,
              "ERR: OpenCalais service responded with #{http.response_header.status} - response body: '#{http.response}'"
            end

            @callbacks.each { |c| c.call(result) }

          end  #callback


          http.errback do
            result = ResponseData.new nil, "ERR: #{http.error}"
            @callbacks.each { |c| c.call(result) }
          end  #errback


        end  #if
      rescue  Exception=>e
        #result = ResponseData.new nil,  "ERR: #{e}"
        #@callbacks.each { |c| c.call(result) }
        @error = "ERR: #{e}"
      end

    end  #method



    alias_method :analyze_this, :analyse_this
    public :to_calais, :analyse_this
    private :get_src_data


  end  #class

end
