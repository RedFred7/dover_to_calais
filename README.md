

# DoverToCalais

DoverToCalais allows the user to send a wide range of data sources (files & URLs)
to [OpenCalais](http://www.opencalais.com/about) and receive asynchronous responses when [OpenCalais](http://www.opencalais.com/about) has finished processing
the inputs. In addition, DoverToCalais enables response filtering in order to find relevant tags and/or tag values.

## What is OpenCalais?
In short -and quoting the [OpenCalais](http://www.opencalais.com/about) creators:  
> "*The OpenCalais Web Service automatically creates rich semantic metadata for the content you submit – in well under a second. Using natural language processing (NLP), machine learning and other methods, Calais analyzes your document and finds the entities within it. But, Calais goes well beyond classic entity identification and returns the facts and events hidden within your text as well.*"

In general, OpenCalais Simple XML Format (the one used by DoverToCalais) returns three kinds of tags: [Entitites, Events](http://www.opencalais.com/documentation/calais-web-service-api/api-metadata/entity-index-and-definitions) and [Topics](http://www.opencalais.com/documentation/calais-web-service-api/api-metadata/document-categorization). ***Entities*** are static 'things', like Persons, Places, et al. that are involved in the textual context in some capacity. OpenCalais assigns a *relevance* score to each entity to indicate it's relevance within the context of the data source's general topic.  ***Events*** are facts or actions that pertain to one or more Entities.  ***Topics*** are a characterisation or generic description of the data source's context. 

We can use these tags and the information within them to extract relevant information from the data or to draw useful conclusions about it. For example, if the data source tags include an *&lt;Event&gt;* with the value of *'CompanyExpansion'*, I can then look for the &lt;City&gt; or  &lt;Company&gt; tags to find out which company is expanding and if it's near my location (hint: they may be looking for more staff :))  Or, I could pick out all &lt;Company&gt;s involved in a &lt;JointVenture&gt;, or all  &lt;Person&gt;s implicated in an  &lt;Arrest&gt; in my  &lt;City&gt;, etc.


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

##Pre-requisites

To use the OpenCalais Web Service  and -by extension- DoverToCalais, one needs to possess an OpenCalais API key, which is easily obtainable from the [OpenCalais web site](http://www.opencalais.com/APIkey).

Also, DoverToCalais requires the presence of a working [JRE](http://en.wikipedia.org/wiki/JRE#Execution_environment). 


## Installation

Add this line to your application's Gemfile:

    gem 'dover_to_calais'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dover_to_calais



## Dependencies
DoverToCalais has been developed in Ruby 1.9.3 and relies on the following gems to work (installation with the gem command will automatically install all dependencies)

 * 'nokogiri', 1.6.0
 * 'eventmachine', 1.0.3
 * 'em-http-request', 1.1.0
 * 'yomu', 0.1.9 

As [Yomu](https://github.com/Erol/yomu) depends on a working JRE in order to function, so does DoverToCalais.

## Usage

### The Basics

As DoverToCalais uses the awesome-ness of [EventMachine](http://rubyeventmachine.com/), code must be placed within an EM *run* block:

```ruby
EM.run do

    # use Control + C to stop the EM
    Signal.trap('INT')  { EventMachine.stop }
    Signal.trap('TERM') { EventMachine.stop }

    DoverToCalais::API_KEY =  'my-opencalais-api-key'
    dover =  DoverToCalais::Dover.new('http://www.bbc.co.uk/news/world-africa-24412315')

    puts 'do some stuff....'

    dover.to_calais { |response| puts response.error ? response.error : response }

    puts 'do some more stuff....'

end
```
This will produce the following result:


> do some stuff....
> do some more stuff....
> &lt;?xml version="1.0"?&gt;
> &lt;OpenCalaisSimple&gt;
> ..........
> (the rest of the XML response from OpenCalais)


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
     my_filter = {:entity => 'Entity1', :value => 'Value1', :given => {:entity => 'Entity2', , :value => 'Value2'}}
     reponse.filter(my_filter)
 ```

The above tells DoverToCalais to look in the reponse for an entity called 'Entity1' with a value of 'Value1', **only** if the response contains an entity called 'Entity2' which has a value of 'Value2'.

The conditional clause (*:given*) is optional; the filtering hash can be used in pretty much any permutation.  For instance:

```ruby
EM.run do

    DoverToCalais::API_KEY =  'my-opencalais-api-key'

    dover =  DoverToCalais::Dover.new('http://www.bbc.co.uk/news/world-africa-24412315')

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


&lt;struct DoverToCalais::ResponseItem name="Company", value="BBC News", relevance=0.654, count=13, normalized=nil, importance=nil, originalValue=nil&gt;<br>  
&lt;struct DoverToCalais::ResponseItem name="Company", value="TV Radio", relevance=0.565, count=2, normalized="HERALD & WEEKLY-TV,RADIO OPS", importance=nil, originalValue=nil&gt;  <br>
&lt;struct DoverToCalais::ResponseItem name="Company", value="Reuters", relevance=0.255, count=2, normalized="THOMSON REUTERS GROUP LIMITED", importance=nil, originalValue=nil&gt;  <br>
&lt;struct DoverToCalais::ResponseItem name="Company", value="Twitter", relevance=0.395, count=1, normalized="TWITTER, INC.", importance=nil, originalValue=nil&gt;  <br>
&lt;struct DoverToCalais::ResponseItem name="Company", value="Huffington Post UK", relevance=0.136, count=1, normalized=nil, importance=nil, originalValue=nil&gt; <br> 
&lt;struct DoverToCalais::ResponseItem name="Company", value="Ireland Kenya", relevance=0.144, count=1, normalized=nil, importance=nil, originalValue=nil&gt; <br> 
&lt;struct DoverToCalais::ResponseItem name="Company", value="Yahoo! UK", relevance=0.144, count=1, normalized="YAHOO! UK LIMITED", importance=nil, originalValue=nil&gt; <br>


If this output looks a bit cluttered, we can easily tidy it up:

```ruby
EM.run do

  DoverToCalais::API_KEY =  'my-opencalais-api-key'

  dover =  DoverToCalais::Dover.new('http://www.bbc.co.uk/news/world-africa-24412315')

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


Company: BBC News, relevance = 0.656  <br>
Company: TV Radio, relevance = 0.566  <br>
Company: Reuters, relevance = 0.26  <br>
Company: Guardian.co.uk, relevance = 0.143  <br>
Company: Twitter, relevance = 0.399  <br>
Company: Huffington Post UK, relevance = 0.132  <br>
Company: Ireland Kenya, relevance = 0.139  <br>
Company: Yahoo! UK, relevance = 0.139  <br>



Let's see if the data source refers to any business partnerships:

```ruby
EM.run do

  DoverToCalais::API_KEY =  'my-opencalais-api-key'

  dover =  DoverToCalais::Dover.new('http://www.bbc.co.uk/news/technology-24380202')

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

There are 1 events like that in the source


Now let's find all companies involved in any business partnerships:

```ruby
EM.run do

  DoverToCalais::API_KEY =  'my-opencalais-api-key'

  dover =  DoverToCalais::Dover.new('http://www.bbc.co.uk/news/technology-24380202')

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

Company: BBC News a.k.a , relevance = 0.678 <br>
Company: Google a.k.a GOOGLE INC., relevance = 0.508 <br>
Company: Flutter a.k.a FLUTTER COM INC, relevance = 0.531 <br>
Company: TV Radio a.k.a HERALD & WEEKLY-TV,RADIO OPS, relevance = 0.558 <br>
Company: Microsoft a.k.a MICROSOFT CORPORATION, relevance = 0.303 <br>
Company: Adobe a.k.a ADOBE SYSTEMS INCORPORATED, relevance = 0.193 <br>
Company: Netflix a.k.a NETFLIX, INC., relevance = 0.301 <br>
Company: Y Combinator a.k.a Y Combinator, relevance = 0.258 <br>
Company: Nintendo a.k.a Nintendo Co., Ltd., relevance = 0.286 <br>
Company: Samsung a.k.a Samsung C&T Corporation, relevance = 0.285 <br>
Company: Glyndwr University a.k.a , relevance = 0.269 <br>



At this point, someone may ask: "But what if we want to get more than one entity for a given condition? The filter hash doesn't allow that!"

No it doesn't. However, given that filtering is done on the *whole* reponse *after* it's been received, we can apply many filters on the same response:

```ruby
EM.run do

  DoverToCalais::API_KEY =  'my-opencalais-api-key'

  dover =  DoverToCalais::Dover.new('http://www.bbc.co.uk/news/technology-24380202')

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

&lt;struct DoverToCalais::ResponseItem name="Company", value="Google", relevance=0.506, count=7, normalized="GOOGLE INC.", importance=nil, originalValue=nil&gt; <br>
&lt;struct DoverToCalais::ResponseItem name="Product", value="Xbox Kinect", relevance=0.286, count=1, normalized=nil, importance=nil, originalValue=nil&gt; <br>
&lt;struct DoverToCalais::ResponseItem name="Product", value="Galaxy S4 smartphone", relevance=0.282, count=1, normalized=nil, importance=nil, originalValue=nil&gt; <br>
&lt;struct DoverToCalais::ResponseItem name="Product", value="Wii", relevance=0.286, count=1, normalized=nil, importance=nil, originalValue=nil&gt; <br>
&lt;struct DoverToCalais::ResponseItem name="Product", value="Galaxy S4", relevance=0.282, count=1, normalized=nil, importance=nil, originalValue=nil&gt; <br>




***PS***: If you're not sure about the names or values of the tags you want to filter, you can get a listing with the following Constants:

```ruby
CalaisOntology::CALAIS_ENTITIES
CalaisOntology::CALAIS_EVENTS
CalaisOntology::CALAIS_TOPICS
```


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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


##Changelog

   * **07-Oct-2013** Version: 0.1.0  
Initial release

