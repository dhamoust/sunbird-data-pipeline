require_relative '../../data-async-processors/geo_reverse_search2.rb'
require_relative '../../data-async-processors/set_ldata2.rb'


class Spinach::Features::TestHowLocationTaggingWorks < Spinach::FeatureSteps
  include CommonSteps::ElasticsearchClient
  include CommonSteps::UserSimulation
  include CommonSteps::Utility

  step 'all events should be tagged to that location' do
    q = search({q:"eid:GE_SESSION_START"})
    q.hits.total.should == 1
    q.hits.hits.first._source.edata.eks.loc.should == THAT_LOCATION
  end

  step 'lat long should be reverse searched' do
    sessions = search({q:"eid:GE_SESSION_START"})
    ldata = sessions.hits.hits.map {|session| session._source.edata.eks.ldata }
    ldata.compact.should be_empty
    Processors::ReverseSearch2.perform('test*')
    refresh_index
    sessions = search({q:"eid:GE_SESSION_START"})
    ldata = sessions.hits.hits.map {|session| session._source.edata.eks.ldata }
    ldata.compact.should_not be_empty
  end

  step 'events should be tagged to respective locations' do
    Processors::SetLdata2.perform('test*')
    refresh_index
    sessions = search({q:"eid:GE_SESSION_START"})
    sessions.hits.hits.each do |session|
      events = search({q:"sid:#{session._source.sid}"}).hits.hits
      events.each do |event|
        location_string(event).should == location_string(session)
      end
    end
  end

  step 'missing GPS events should be tagged to the devices current location' do
    pending 'step not implemented'
  end

end
