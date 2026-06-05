# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require 'pry-nav'
require 'elasticsearch/persistence'

unless defined?(ELASTICSEARCH_URL)
  ELASTICSEARCH_URL = ENV['ELASTICSEARCH_URL'] || "localhost:#{(ENV['TEST_CLUSTER_PORT'] || 9200)}"
end

RSpec.configure do |config|
  config.formatter = 'documentation'
  config.color = true

  config.before(:suite) do
    # ES 9.4+ defaults `action.destructive_requires_name` to true, which rejects
    # `_all`/wildcard deletes. Relax it for the test cluster so the after(:suite)
    # cleanup works uniformly across ES 8.x and 9.x.
    DEFAULT_CLIENT.cluster.put_settings(
      body: { persistent: { 'action.destructive_requires_name' => false } }
    )
    puts "Elasticsearch Version: #{DEFAULT_CLIENT.info['version']}"
  end
  config.after(:suite) do
    DEFAULT_CLIENT.indices.delete(index: '_all')
  end
end

# The default client to be used by the repositories.
#
# @since 6.0.0
DEFAULT_CLIENT = Elasticsearch::Client.new(host: ELASTICSEARCH_URL,
                                           tracer: (ENV['QUIET'] ? nil : ::Logger.new(STDERR)),
                                           transport_options: { :ssl => { verify: false } })

class MyTestRepository
  include Elasticsearch::Persistence::Repository
  include Elasticsearch::Persistence::Repository::DSL
  client DEFAULT_CLIENT
end

# The default repository to be used by tests.
#
# @since 6.0.0
DEFAULT_REPOSITORY = MyTestRepository.new(index_name: 'my_test_repository')

# Get the Elasticsearch server version.
#
# @return [ String ] The version of Elasticsearch.
#
# @since 7.0.0
def server_version(client = nil)
  (client || DEFAULT_CLIENT).info['version']['number']
end
