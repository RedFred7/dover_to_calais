# **************IMPORTANT NOTICE ************
## As of __30 September__ 2015, the OpenCalais API on which this gem is built, has been discontinued by Thomson-Reuters. A new and significantly changed API is now in use by OpenCalais. You can read about the changes [here](http://www.opencalais.com/upgrade/). Unfortunately this means that DoverToCalais is no longer functional. I don't know -at this stage- if and when I'll upgrade this gem to the new API. Thank you for your time and effort in using DoverToCalais.

# DoverToCalais

DoverToCalais allows the user to send a wide range of data sources (files & URLs)
to [OpenCalais](http://www.opencalais.com/about) and receive asynchronous responses when [OpenCalais](http://www.opencalais.com/about) has finished processing
the inputs. In addition, DoverToCalais enables response filtering in order to find relevant tags and/or tag values.

## What is OpenCalais?
In short -and quoting the [OpenCalais](http://www.opencalais.com/about) creators:  
> "*The OpenCalais Web Service automatically creates rich semantic metadata for the content you submit – in well under a second. Using natural language processing (NLP), machine learning and other methods, Calais analyzes your document and finds the entities within it. But, Calais goes well beyond classic entity identification and returns the facts and events hidden within your text as well.*"

In general, OpenCalais Simple XML Format (the one used by DoverToCalais) returns three kinds of tags: [Entitites, Events](http://www.opencalais.com/documentation/calais-web-service-api/api-metadata/entity-index-and-definitions) and [Topics](http://www.opencalais.com/documentation/calais-web-service-api/api-metadata/document-categorization). ***Entities*** are static 'things', like Persons, Places, et al. that are involved in the textual context in some capacity. OpenCalais assigns a *relevance* score to each entity to indicate it's relevance within the context of the data source's general topic.  ***Events*** are facts or actions that pertain to one or more Entities.  ***Topics*** are a characterisation or generic description of the data source's context. 

We can use these tags and the information within them to extract relevant information from the data or to draw useful conclusions about it. For example, if the data source tags include an *&lt;Event&gt;* with the value of *'CompanyExpansion'*, I can then look for the &lt;City&gt; or  &lt;Company&gt; tags to find out which company is expanding and if it's near my location (hint: they may be looking for more staff :))  Or, I could pick out all &lt;Company&gt;s involved in a &lt;JointVenture&gt;, or all  &lt;Person&gt;s implicated in an  &lt;Arrest&gt; in my  &lt;City&gt;, etc.


DoverToCalais, from version 0.2.1 onwards also supports the OpenCalais rich [JSON Output format](http://www.opencalais.com/documentation/calais-web-service-api/interpreting-api-response/opencalais-json-output-format). This format returns relationships between entities, as well as the previous tags returned by the Simple XML format, thus allowing a deeper level of data analysis and detection.


## Why use OpenCalais?
There are many reasons, mainly to:
   
 * incorporate tags into other applications, such as search, news aggregation, blogs, catalogs, etc.
 * enrich search by looking for deeper, contextual meaning instead of merely phrases or keywords.
 * help to discern relationships between semantic entities. 
 * facilitate data processing and analysis by allowing easy identification of relevant or important data sources and the discarding of irrelevant ones.


## DoverToCalais Features
1. **Multiple data source support**: Thanks to the power of [Yomu](https://github.com/Erol/yomu), DoverToCalais can process a vast range of files (and, of course, web pages), extract text from them and send
them to OpenCalais for analysis and tag generation. 

2. **Asynchronous responses (callbacks)**:
Users can set callbacks to receive the processed meta-data, once the OpenCalais Web Service response has  been received.
Furthermore, a user can set multiple callbacks for the same request (data source), thus enabling cleaner,
more modular code. 

3. **Result filtering**: DoverToCalais uses the OpenCalais [Simple XML Format](http://www.opencalais.com/documentation/calais-web-service-api/interpreting-api-response/simple-format) as the preferred response format. The user can work directly with the XML-formatted response, or -if feeling a bit lazy- can take advantage of the DoverToCalais filtering functionality and receive specific entities, optionally  based on specified conditions.

For more details of the features and code samples, see [Usage](#usage).

##Pre-requisites and dependencies

To use the OpenCalais Web Service  and -by extension- DoverToCalais, one needs to possess an OpenCalais API key, which is easily obtainable from the [OpenCalais web site](http://www.opencalais.com/APIkey).

DoverToCalais requires the presence of a working [JRE](http://en.wikipedia.org/wiki/JRE#Execution_environment). 

Also, if you're going to use the rich JSON output format, you'll need to have [Redis](http://redis.io/topics/quickstart) running on an accessible node.


## Installation

Add this line to your application's Gemfile:

    gem 'dover_to_calais'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dover_to_calais



## Compatibility
DoverToCalais has been developed in Ruby 1.9.3 and should work fine on post-1.9.3 MRI versions too. If anyone is succesfully running it on other Ruby runtimes please let me know.

## Usage
Using DoverToCalais is extremely simple.

### The Basics
As DoverToCalais uses the awesome-ness of [EventMachine](http://rubyeventmachine.com/), code must be placed within an EM *run* block:

```ruby
EM.run do

    # use Control + C to stop the EM
    Signal.trap('INT')  { EventMachine.stop }
    Signal.trap('TERM') { EventMachine.stop }

    # we need an API key to use OpenCalais
    DoverToCalais::API_KEY =  'my-opencalais-api-key'
    # create a new dover
    dover =  DoverToCalais::Dover.new('http://www.bbc.co.uk/news/world-africa-24412315')
    # parse the text and send it to OpenCalais
    dover.analyse_this
    puts 'do some stuff....'
    # set a callback for when we receive a response
    dover.to_calais { |response| puts response.error ? response.error : response }

    puts 'do some more stuff....'

end
```
This will produce the following result:


> do some stuff....  <br>
> do some more stuff.... <br>
> <?xml version="1.0"?>  <br>
> &lt;OpenCalaisSimple&gt;  <br>
> ..........    <br>
> (the rest of the XML response from OpenCalais)  <br>


As can be observed, the callback (#to_calais) is trigerred after the rest of the code has been executed and only when the OpenCalais request has been completed.

Of course, we can analyse more than one sources at a time:

```ruby
EM.run do

  # use Control + C to stop the EM
  Signal.trap('INT')  { EventMachine.stop }
  Signal.trap('TERM') { EventMachine.stop }

  DoverToCalais::API_KEY =  'my-opencalais-api-key'

  d1 =  DoverToCalais::Dover.new('http://www.bbc.co.uk/news/world-africa-24412315')
  d2 =  DoverToCalais::Dover.new('/home/fred/Documents/RailsRecipes.pdf')
  d3 =  DoverToCalais::Dover.new('//network-drive/annual_forecast.doc')

  d1.analyse_this; d2.analyse_this; d3.analyse_this; 

  puts 'do some stuff....'

  d1.to_calais { |response| puts response.error ? response.error : response }
  d2.to_calais { |response| puts response.error ? response.error : response }
  d3.to_calais { |response| puts response.error ? response.error : response }

  puts 'do some more stuff....'

end
```

This will output the two *puts* statements followed by the three callbacks (d1, d2, d3) in the order in which they are triggered, i.e. the first callback to receive a response from OpenCalais will fire first.


###Filtering the response
Why parse the response XML ourselves when DoverToCalais can do it for us? We'll just use the *#filter* method on the response object, passing a filtering hash:

 ```ruby
     my_filter = {:entity => 'Entity1', :value => 'Value1', :given => {:entity => 'Entity2', :value => 'Value2'}}
     reponse.filter(my_filter)
 ```

The above tells DoverToCalais to look in the reponse for an entity called 'Entity1' with a value of 'Value1', **only** if the response contains an entity called 'Entity2' which has a value of 'Value2'.

The conditional clause (*:given*) is optional; the filtering hash can be used in pretty much any permutation.  For instance:

```ruby
EM.run do

    DoverToCalais::API_KEY =  'my-opencalais-api-key'

    dover =  DoverToCalais::Dover.new('http://www.bbc.co.uk/news/world-africa-24412315')
    dover.analyse_this

    dover.to_calais do |response|
    if   response.error
      puts  response.error
    else
      puts response.filter({:entity => 'Company'})
    end
    end

end
```

This will pick out all entities tagged 'Company' from the data source. The output will be an Array of ResponseItem objects. 


> &lt;struct DoverToCalais::ResponseItem name="Company", value="BBC News", relevance=0.654, count=13, normalized=nil, importance=nil, originalValue=nil&gt;<br>
> &lt;struct DoverToCalais::ResponseItem name="Company", value="TV Radio", relevance=0.565, count=2, normalized="HERALD & WEEKLY-TV,RADIO OPS", importance=nil, originalValue=nil&gt;  <br>
> &lt;struct DoverToCalais::ResponseItem name="Company", value="Reuters", relevance=0.255, count=2, normalized="THOMSON REUTERS GROUP LIMITED", importance=nil, originalValue=nil&gt;  <br>
> &lt;struct DoverToCalais::ResponseItem name="Company", value="Twitter", relevance=0.395, count=1, normalized="TWITTER, INC.", importance=nil, originalValue=nil&gt;  <br>
> &lt;struct DoverToCalais::ResponseItem name="Company", value="Huffington Post UK", relevance=0.136, count=1, normalized=nil, importance=nil, originalValue=nil&gt; <br>
> &lt;struct DoverToCalais::ResponseItem name="Company", value="Ireland Kenya", relevance=0.144, count=1, normalized=nil, importance=nil, originalValue=nil&gt; <br>
> &lt;struct DoverToCalais::ResponseItem name="Company", value="Yahoo! UK", relevance=0.144, count=1, normalized="YAHOO! UK LIMITED", importance=nil, originalValue=nil&gt; <br>


If this output looks a bit cluttered, we can easily tidy it up:

```ruby
EM.run do

  DoverToCalais::API_KEY =  'my-opencalais-api-key'

  dover =  DoverToCalais::Dover.new('http://www.bbc.co.uk/news/world-africa-24412315')
  dover.analyse_this

  dover.to_calais do |response|
    if   response.error
      puts  response.error
    else
      items = response.filter({:entity => 'Company'})
      items.each do |item|
        puts "#{item.name}: #{item.value}, relevance = #{item.relevance}"
      end
    end
  end

end
```

Which will give us:


> Company: BBC News, relevance = 0.656  <br>
> Company: TV Radio, relevance = 0.566  <br>
> Company: Reuters, relevance = 0.26  <br>
> Company: Guardian.co.uk, relevance = 0.143  <br>
> Company: Twitter, relevance = 0.399  <br>
> Company: Huffington Post UK, relevance = 0.132  <br>
> Company: Ireland Kenya, relevance = 0.139  <br>
> Company: Yahoo! UK, relevance = 0.139  <br>



Let's see if the data source refers to any business partnerships:

```ruby
EM.run do

  DoverToCalais::API_KEY =  'my-opencalais-api-key'

  dover =  DoverToCalais::Dover.new('http://www.bbc.co.uk/news/technology-24380202')
  dover.analyse_this

  dover.to_calais do |response|
    if   response.error
      puts  response.error
    else
      items = response.filter({:entity => 'Event', :value => 'Business Partnership'})
      puts "There are #{items.length} events like that in the source"
    end
  end

end
```

which will produce:

> There are 1 events like that in the source


Now let's find all companies involved in any business partnerships:

```ruby
EM.run do

  DoverToCalais::API_KEY =  'my-opencalais-api-key'

  dover =  DoverToCalais::Dover.new('http://www.bbc.co.uk/news/technology-24380202')
  dover.analyse_this

  dover.to_calais do |response|
    if   response.error
      puts  response.error
    else
      items = response.filter( {:entity => 'Company', :given => {:entity => 'Event',  :value => 'Business Partnership'}} )
      items.each do |item|
        puts "#{item.name}: #{item.value} a.k.a #{item.normalized}, relevance = #{item.relevance}"
      end
    end
  end

end
```

which gives us:

> Company: BBC News a.k.a , relevance = 0.678 <br>
> Company: Google a.k.a GOOGLE INC., relevance = 0.508 <br>
> Company: Flutter a.k.a FLUTTER COM INC, relevance = 0.531 <br>
> Company: TV Radio a.k.a HERALD & WEEKLY-TV,RADIO OPS, relevance = 0.558 <br>
> Company: Microsoft a.k.a MICROSOFT CORPORATION, relevance = 0.303 <br>
> Company: Adobe a.k.a ADOBE SYSTEMS INCORPORATED, relevance = 0.193 <br>
> Company: Netflix a.k.a NETFLIX, INC., relevance = 0.301 <br>
> Company: Y Combinator a.k.a Y Combinator, relevance = 0.258 <br>
> Company: Nintendo a.k.a Nintendo Co., Ltd., relevance = 0.286 <br>
> Company: Samsung a.k.a Samsung C&T Corporation, relevance = 0.285 <br>
> Company: Glyndwr University a.k.a , relevance = 0.269 <br>



At this point, someone may ask: "But what if we want to get more than one entity for a given condition? The filter hash doesn't allow that!"

No it doesn't. However, given that filtering is done on the *whole* reponse *after* it's been received, we can apply many filters on the same response:

```ruby
EM.run do

  DoverToCalais::API_KEY =  'my-opencalais-api-key'

  dover =  DoverToCalais::Dover.new('http://www.bbc.co.uk/news/technology-24380202')
  dover.analyse_this

  dover.to_calais do |response|
    if   response.error
      puts  response.error
    else
      result1 = response.filter( {:entity => 'Company', :value => 'Google', :given => {:entity => 'Technology',  :value => 'gesture recognition'}} )
      result2 = response.filter( {:entity => 'Product', :given => {:entity => 'Technology',  :value => 'gesture recognition'}} )
      puts result1 | result2
    end
  end

end
```

Which will give us all the gesture-recognition products that Google is associated with according to our data source: 

> &lt;struct DoverToCalais::ResponseItem name="Company", value="Google", relevance=0.506, count=7, normalized="GOOGLE INC.", importance=nil, originalValue=nil&gt; <br>
> &lt;struct DoverToCalais::ResponseItem name="Product", value="Xbox Kinect", relevance=0.286, count=1, normalized=nil, importance=nil, originalValue=nil&gt; <br>
> &lt;struct DoverToCalais::ResponseItem name="Product", value="Galaxy S4 smartphone", relevance=0.282, count=1, normalized=nil, importance=nil, originalValue=nil&gt; <br>
> &lt;struct DoverToCalais::ResponseItem name="Product", value="Wii", relevance=0.286, count=1, normalized=nil, importance=nil, originalValue=nil&gt; <br>
> &lt;struct DoverToCalais::ResponseItem name="Product", value="Galaxy S4", relevance=0.282, count=1, normalized=nil, importance=nil, originalValue=nil&gt; <br>




***PS***: If you're not sure about the names or values of the tags you want to filter, you can get a listing with the following Constants:

```ruby
CalaisOntology::CALAIS_ENTITIES
CalaisOntology::CALAIS_EVENTS
CalaisOntology::CALAIS_TOPICS
```

### Rich output format
Since version 0.2.1, DoverToCalais users can request to receive the OpenCalais output in OpenCalais's rich JSON format. This has the advantage of producing relation data, which allows for a much deeper level of analysis and data detection.

The rich format can be requested simply by passing one of the following arguments to the *#analyse_this* method: *:rich, :rich_format, :rich_output*, i.e.

```ruby
dover.analyse_this :rich
```
When DoverToCalais processes the *rich* output, it will create a pseudo-relational data model on Redis. The model can then be be queried and searched using standard Ruby and the [Ohm](https://github.com/soveran/ohm) API.

The only difference in DoverToCalais usage when using the *rich* output is that there's no longer a need to do our response analysis in the callback (*#to_calais* method). The callback now only serves to let us know when the response has been processed. Once the callback returns, we know that we can find all our source data nicely modelled in Redis and we can access it ouside and independently of our EventMachine create->analyze->callback loop. 

#### The Data Model
DoverToCalais creates three kinds of key classes on Redis: *DoverToCalais::EntityModel, DoverToCalais::EntityModel::RelationModel, DoverToCalais::EntityModel::EventModel*.

As is suggested by the namespacing, the relational aspects of the model are that an EntityModel *has* a number of RelationModels and a number of EventModels. Knowing this simple fact, it becomes fairly straightforward to discover which entities are inter-connected and how.

*DoverToCalais::EntityModel* has the following attributes

* name - the entity name - String
* type - the entity type, e.g. Person, Location, etc - String
* calais_id - a unique id assigned by OpenCalais - String
* relations - a set of generic relations connected to the entity - Set
* events - a set of events connected to the entity - Set

*DoverToCalais::EntityModel::RelationModel* has the following attributes

* subject - the entity applying the action - Hash
* verb - an action - String
* object - the entity receiving the action - Hash
* detection -  the most accurate string description of the relation - String
* calais_id - a unique id assigned by OpenCalais - String

*DoverToCalais::EntityModel::EventModel* has the following attributes

* calais_id - a unique id assigned by OpenCalais - String
* info_hash - a Hash incorporating the event's attributes and values. As the number of attributes depends on the type of event (e.g. MilitaryAction will have very different attributes to MovieRelease), the info_hash is a good way to dynamically encapsulate an event's attributes.

#### Redis
DoverToCalais relies on [Redis](http://redis.io/topics/quickstart) to store processed responses in the rich JSON format. By default, DoverToCalais will use the local Redis instance 127.0.0.1, on the default port 6379 with database #6 (no password). If any of this proves inconvenient, it can be changed by modifying the constant *DoverToCalais::REDIS*.

#### Rich output usage

```ruby
#probably good idea to clear Redis DB first
DoverToCalais::flushdb
EM.run do

    # use Control + C to stop the EM
    Signal.trap('INT')  { EventMachine.stop }
    Signal.trap('TERM') { EventMachine.stop }

    # we need an API key to use OpenCalais
    DoverToCalais::API_KEY =  'my-opencalais-api-key'
    # create a new dover
    dover =  DoverToCalais::Dover.new('http://www.bbc.co.uk/news/world-africa-24412315')
    # parse the text and send it to OpenCalais
    dover.analyse_this :rich
    puts 'do some stuff....'
    # set a callback for when we receive a response
    dover.to_calais { |response| puts response.error ? response.error : "finished!" }

    puts 'do some more stuff....'

end
```

As you can see, this isn't much different from our bread-and-butter usage with the simple format. The differences are:

* we clear the Redis data store before we begin. Not a necessary step, but we may want to start on a clean slate. DoverToCalais provides its own method for doing that and it's recommended this method is used instead of an external Redis command .
* we pass the *:rich* symbol to *#analyse_this*. 
* in our callback, instead of doing something with the response we simply notify when it's done. What this means is that DoverToCalais has processed the response and has created a data model on Redis. We can now go and search our data model.


```ruby
require 'dover_to_calais'

  #make sure we're connected to the DoverToCalais data-store
  Ohm.redis = Redic.new(DoverToCalais::REDIS)

  #let's find out how many entities we have in our store
  puts DoverToCalais::EntityModel.all.to_a.length
  puts DoverToCalais::EntityModel::RelationModel.all.to_a.length
  puts DoverToCalais::EntityModel::EventModel.all.to_a.length
  
  #find all relations where the subject is Jesse James
  all_relations = DoverToCalais::EntityModel::RelationModel.all.to_a
  selected = all_relations.select {|v| v.subject['name'].eql?("Jesse James")}
  selected.each do |relation|
    puts relation.subject, relation.verb, relation.object, relation.detection
  end
  
  #get JFK (the Person, not the Airport)
  presidents = DoverToCalais::EntityModel.find(name: "JFK", type: "Person")
  
  #make sure there's only one
  if presidents.size == 1
    the_president = presidents.first
    #get all JFK-related events
    the_president.events.each do |e|
      e.info_hash.each_pair do |k,v|
        puts "#{k}: #{v}"
      end
    end
    
  end
  
```

###Code samples

More examples of using DoverToCalais can be found as GitHub Gists:

[Using DoverToCalais to semantically tag all files in a directory](https://gist.github.com/RedFred7/6961349)  
[Use DoverToCalais to find all Persons or Organizations with a relevance score greater than 0.1, if the data source contains an environmental event](https://gist.github.com/RedFred7/6961853)  


### Using a Proxy

If you're behind a corporate firewall and the only way to reach outside is through a proxy then you need to set the *DoverToCalais::PROXY* constant:

```ruby
    DoverToCalais::PROXY = 
        :proxy => {
           :host => 'www.myproxy.com',
           :port => 8080,
           :authorization => ['username', 'password'] #optional
        }
```


If you're connecting through a SOCKS5 Proxy just set the *:type* key to :socks5.

```ruby
    DoverToCalais::PROXY = 
        :proxy => {
           :host => 'www.myproxy.com',
           :port => 8080,
           :type => :socks5
        }
```

## Documentation

Comprehensive documentation can be found at [rubydoc](http://rubydoc.info/gems/dover_to_calais) and also at [omniref](http://www.omniref.com/?utf8=%E2%9C%93&q=dovertocalais&p=0&r=20&commit=Search).

## Testing 

A list of Cucumber features and scenarios can be found in the *features* directory. The list is far from exhaustive, so feel free to add your own scenarios and steps.

To run the tests, there is already a rake task set up. Just type:

    rake features API_KEY='my_api_key'

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


##Changelog

   * **07-Oct-2013** Version: 0.1.0  
Initial release
   * **10-Feb-2014** Version: 0.1.1 
Improved Response error message
   * **10-Feb-2014** Version: 0.2.0  
Added #analyse_this to public interface
   * **24-Mar-2014** Version: 0.2.1  
New feature: rich JSON output analysis and Redis data modelling


# **************IMPORTANT NOTICE ************
## As of __30 September__ 2015, the OpenCalais API on which this gem is built, has been discontinued by Thomson-Reuters. A new and significantly changed API is now in use by OpenCalais. You can read about the changes [here](http://www.opencalais.com/upgrade/). Unfortunately this means that DoverToCalais is no longer functional. I don't know -at this stage- if and when I'll upgrade this gem to the new API. Thank you for your time and effort in using DoverToCalais.
