require "dover_to_calais/version"   #gem lib file
require "dover_to_calais/ontology"  #gem lib file
require 'open-uri'  # in std library
require 'nokogiri'
require 'eventmachine'
require 'em-http-request'
require 'yomu'


module DoverToCalais


  PROXY = nil

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
    attr_reader :error

    # creates a new ResponseData object, passing the name of the data source to be processed
    #
    # @param xml_data [ Nokogiri::XML::NodeSet, nil] the xml data returned by OpenCalais
    # @param error [ String, nil] an error description if the OpenCalais call has failed
    def initialize(xml_data = nil, error = nil)
      if xml_data
        @raw = xml_data
      else
        @error = error
      end
    end

    # Returns  the response data as an XML string or an error, if one has occurred.
    #
    # @return [String] an XML string
    def to_s
      @raw ?  @raw.to_s : @error
    end


    # Filters the response object to extract relevant data.
    #
    # @param params [Hash] a filter Hash (see code samples)
    # @return [Array[ResponseItem]] a list of relevant response items
    def filter(params)
      result = Array.new
      begin
        if @raw

          if params[:given]
            found = @raw.xpath("//#{params[:given][:entity]}[contains(text(), #{params[:given][:value].inspect})]")
            if found.size > 0
              @raw.xpath("//#{params[:entity]}[contains(text(), #{params[:value].inspect})]").each do |node|
                result <<  create_response_item(node)
              end
            end
          else  # no conditional
            @raw.xpath("//#{params[:entity]}[contains(text(), #{params[:value].inspect})]").each do |node|
              result <<  create_response_item(node)
            end
          end

          return result
        else # no xml data
          puts 'ERR: no valid xml data!'

        end #if

      rescue  Exception=>e
        puts "ERR: #filter:  #{e}"

      end

      #return result

    end  #method

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
    private :create_response_item

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
      analyse_this
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

    #
    def analyse_this

      @document = get_src_data(@data_src)
      begin
        if @document[0..2].eql?('ERR')
         # puts  @document
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
                  :outputFormat => 'Text/Simple'}
          }

          http = EventMachine::HttpRequest.new(CALAIS_SERVICE, connection_options ).post request_options


          http.callback do
            http.response.match(/<OpenCalaisSimple>/) do |m|
              response = Nokogiri::XML('<OpenCalaisSimple>' + m.post_match)  do |config|
                #strict xml parsing, disallow network connections
                config.strict.nonet
              end #block
            end #block

            result =   response ?
                      ResponseData.new(response, nil) :
                      ResponseData.new(nil,'ERR: cannot find <OpenCalaisSimple> tag in response data - source invalid?')
            @callbacks.each { |c| c.call(result) }
          end  #callback


          http.errback do

            result = ResponseData.new nil, "#{http.error}"
            @callbacks.each { |c| c.call(result) }
          end  #errback


        end  #if
      rescue  Exception=>e
        #result = ResponseData.new nil,  "ERR: #{e}"
        #@callbacks.each { |c| c.call(result) }
        @error = "ERR: #{e}"
      end

    end  #method


    public :to_calais
    private :get_src_data, :analyse_this


  end  #class

end
