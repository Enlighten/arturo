require File.expand_path('../../test_helper', __FILE__)
require 'arturo/features_helper'

class CacheTest < ActiveSupport::TestCase

  Arturo::Feature.extend(Arturo::FeatureCaching)

  def setup
    @feature = Factory(:feature)
    Arturo::Feature.cache_ttl = 30.minutes
    Arturo::Feature.feature_cache.clear
  end

  def teardown
    Arturo::Feature.cache_ttl = 0 # turn off for other tests
    Timecop.return
  end

  def test_first_load_hits_database
    Arturo::Feature.expects(:where).once.returns([@feature])
    Arturo::Feature.to_feature(@feature.symbol)
  end

  def test_subsequent_loads_within_ttl_hit_cache
    Arturo::Feature.expects(:where).once.returns([@feature])
    Arturo::Feature.to_feature(@feature.symbol)
    Arturo::Feature.to_feature(@feature.symbol)
    Arturo::Feature.to_feature(@feature.symbol)
  end

  def test_clear_cache
    Arturo::Feature.to_feature(@feature.symbol)
    Arturo::Feature.feature_cache.clear
    Arturo::Feature.expects(:where).once.returns([@feature])
    Arturo::Feature.to_feature(@feature.symbol)
  end

  def test_turn_off_caching
    Arturo::Feature.cache_ttl = 0
    Arturo::Feature.expects(:where).twice.returns([@feature])
    Arturo::Feature.to_feature(@feature.symbol)
    Arturo::Feature.to_feature(@feature.symbol)
  end

  def test_ttl_expiry
    Arturo::Feature.to_feature(@feature.symbol)
    Arturo::Feature.expects(:where).once.returns([@feature])
    Timecop.travel(Time.now + Arturo::Feature.cache_ttl - 5.seconds)
    Arturo::Feature.to_feature(@feature.symbol)
    Timecop.travel(Time.now + Arturo::Feature.cache_ttl + 5.seconds)
    Arturo::Feature.to_feature(@feature.symbol)
  end

end
