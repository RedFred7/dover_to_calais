# DoverToCalais

DoverToCalais allows the user to send a wide range of data sources (files & URLs)
to [OpenCalais](http://www.opencalais.com/about) and receive asynchronous responses when [OpenCalais](http://www.opencalais.com/about) has finished processing
the inputs. In addition, DoverToCalais enables the filtering of the response in order to
find relevant tags and/or tag values.

## What is OpenCalais?
In short -and quoting the [OpenCalais](http://www.opencalais.com/about) creators:  

*The OpenCalais Web Service automatically creates rich semantic metadata for the content you submit – in well under a second. Using natural language processing (NLP), machine learning and other methods, Calais analyzes your document and finds the entities within it. But, Calais goes well beyond classic entity identification and returns the facts and events hidden within your text as well.*

## Why use OpenCalais?
There are many reasons, mainly to:
   
 * incorporate tags into other applications, such as search, news aggregation, blogs, catalogs, etc.
 * enrich search by looking for deeper, contextual meaning instead of merely phrases or keywords.
 * help to discern relationships between semantic entities. 
 * facilitate data processing and analysis by allowing easy filtering of relevant data sources and the discarding of irrelevant ones.


## DoverToCalais Features
1. **Supports most data sources**: Thanks to the power of [Yomu](https://github.com/Erol/yomu), DoverToCalais can process a vast range of files (and -of course- web pages), extract text from them and send
them to OpenCalais for analysis and tag generation. 

2. **Asynchronous responses (callbacks)**:
Users can set callbacks to receive the processed meta-data, once the OpenCalais Web Service response has  been received.
Furthermore, a user can set multiple callbacks for the same request (data source), thus enabling cleaner,
more modular code. Powered by [EventMachine](http://rubyeventmachine.com/) :)

3. **Result filtering**: DoverToCalais uses the OpenCalais [Simple XML Format](http://www.opencalais.com/documentation/calais-web-service-api/interpreting-api-response/simple-format) as its preferred response format. The user can work directly with the XMl-formatted response, or -if feeling a bit lazy- can take advantage of the DoverToCalais filtering functionality and receive specific entities, optionally  based on specified conditions.

For more details of the features and code samples, see [Usage](#usage).

##Pre-requisites

To use the OpenCalais Web Service  and -by extension- DoverToCalais one needs to possess an OpenCalais API key, which is easily obtainable from the [OpenCalais web site](http://www.opencalais.com/APIkey).

Also, DoverToCalais requires the presence of a working [JRE](http://en.wikipedia.org/wiki/JRE#Execution_environment). 


## Installation

Add this line to your application's Gemfile:

    gem 'dover_to_calais'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dover_to_calais

## Dependencies
DoverToCalais has been developed in Ruby 1.9.3 and requires the following gems (for development purposes only)

 * 'nokogiri', 1.6.0
 * 'eventmachine', 1.0.3
 * 'em-http-request', 1.1.0
 * 'open-uri', 
 * 'yomu', 0.1.9 

As [Yomu](https://github.com/Erol/yomu) depends on a working JRE in order to function, so does DoverToCalais.

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
